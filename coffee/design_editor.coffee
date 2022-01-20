# design_editor.coffee

class design_editor
  convert_base64: =>
    max_size = 1024 * 25
    thumbnail_upload = $("#thumbnail_upload").prop("files")[0]

    if thumbnail_upload && thumbnail_upload.size < max_size
      convertImage(thumbnail_upload)
    else
      Page.cmd "wrapperNotification", ["info", "Max image size: 25kb (Tip: use GIMP or online compression tools to reduce resolution/quality!)"]
      debugger
      return false

  delete_model_from_data_json: (model_design_uri, model_file_uri, model_date_added, cb) =>
    data_inner_path = "data/users/" + Page.site_info.auth_address + "/data.json";
    console.log("Deleting design file from data.json at directory: " + Page.site_info.auth_address)
    Page.cmd "fileGet", data_inner_path, (res) =>
      data = JSON.parse(res)
      #console.log(data["design_file"][model_design_uri])

      #delete data["design_file"][model_design_uri][model_file_uri]
      design_file_count = 0
      for i in data["design_file"][model_design_uri]
        #console.log("Design file row: " + JSON.stringify(data["design_file"][model_design_uri][design_file_count]))
        #console.log(model_date_added)
        if model_date_added is (data["design_file"][model_design_uri][design_file_count]["date_added"])
          data["design_file"][model_design_uri].splice(design_file_count, 1)
          break
        design_file_count++

      Page.cmd "fileWrite", [data_inner_path, Text.fileEncode(data)], (res) =>
        cb?(res)

  delete_model: (design_uri, file_uri, date_added) =>
    delete_model_from_data_json = @delete_model_from_data_json
    content_inner_path = "data/users/" + Page.site_info.auth_address + "/content.json";

    this_render = @render
    Page.cmd "wrapperConfirm", ["Delete bundle item?", "Delete"], =>
      delete_model_from_data_json design_uri, file_uri, date_added, (res) ->
        if res == "ok"
          Page.cmd "sitePublish", {"inner_path": content_inner_path}
          console.log("[NGnoid 3D: Deleted design file...] " + file_uri)
          this_render()

  delete_from_data_json: (design_url, design_name, cb) =>
    design_directory = design_url.split("_")[1]
    data_inner_path = "data/users/" + design_directory + "/data.json";
    console.log("deleting from data.json at directory: " + design_directory + "and design name: " + design_name)
    Page.cmd "fileGet", data_inner_path, (res) =>
      data = JSON.parse(res)
      delete data["design"][design_name]
      delete data["design_file"][design_url]
      Page.cmd "fileWrite", [data_inner_path, Text.fileEncode(data)], (cb)

  delete_design: (design_url, design_name) =>
    delete_from_data_json = @delete_from_data_json
    design_directory = design_url.split("_")[1]
    content_inner_path = "data/users/" + design_directory + "/content.json";

    Page.cmd "wrapperConfirm", ["Are you sure?", "Delete"], =>
      delete_from_data_json design_url, design_name, (res) ->
        if res == "ok"
          Page.cmd "sitePublish", {"inner_path": content_inner_path}
          console.log("[NGnoid 3D] Deleted design: " + design_name)
          Page.nav("?Latest")

  check_content_json: (cb) =>
    inner_path = "data/users/" + Page.site_info.auth_address + "/content.json"
    Page.cmd "fileGet", [inner_path, false], (res) =>
      if res
        res = JSON.parse(res)
      res ?= {}
      optional_pattern = "(?!data.json)"
      if res.optional == optional_pattern
        return cb()

      res.optional = optional_pattern
      Page.cmd "fileWrite", [inner_path, Text.fileEncode(res)], cb

  register_info: (name, title, description, image_link, date_added, cb) =>
    inner_path = "data/users/" + Page.site_info.auth_address + "/data.json"
    Page.cmd "fileGet", [inner_path, false], (res) =>
      if res
        res = JSON.parse(res)
      if res == null
        res = {}
      if res.file == null
        res.design = {}
      res.design[name] = {title: title, description: description, image_link: image_link, date_added: date_added}
      Page.cmd "fileWrite", [inner_path, Text.fileEncode(res)], cb

  save_info: (d_name, d_title, d_description, d_image, d_date) =>
    register_info = @register_info

    @check_content_json (res) =>
      register_info d_name, d_title, d_description, d_image, d_date, (res) =>
        Page.cmd "siteSign", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json"}, (res) ->
          Page.cmd "sitePublish", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json", "sign": false}, (res) ->
            Page.set_url("?DesignUser=" + Page.site_info.cert_user_id)

  render: =>

    console.log("[NGnoid 3d: Rendering design editor.]")
    init_url = Page.history_state["url"]
    real_url = init_url.split("DesignEdit=")[1]

    date_added = real_url.split("_")[0]
    user_address = real_url.split("_")[1]

    editorbox = $("<div></div>")
    editorbox.attr "id", "editor"
    editorbox.attr "class", "editor"

    query = "SELECT * FROM design LEFT JOIN json USING (json_id) WHERE date_added='" + date_added + "' AND directory='" + user_address + "'"
    Page.cmd "dbQuery", [query], (res) =>

      if res.length is 0
        $("#editor").html "<span>Error: No such video found!!!</span>"
        console.log("date added: " + date_added)
        console.log("user address: " + user_address)
      else
        my_row = res[0]
        design_name = my_row['name']
        design_title = my_row['title']
        design_image = my_row['image_link']
        design_description = my_row['description']
        design_date_added = my_row['date_added']

        user_directory = my_row['directory']

        if user_directory is Page.site_info.auth_address

          editor_container = $("<div></div>")
          editor_container.attr "id", "editor_container"
          editor_container.attr "class", "editor_container"

          editor_submit = $("<button></button>")
          editor_submit.attr "id", "editor_submit_button"
          editor_submit.attr "class", "standard_button"
          editor_submit.text "PUBLISH"

          title_div = $("<div></div>")
          title_div.attr "id", "title_row"
          title_div.attr "class", "editor_row"

          title_label = $("<label></label>")
          title_label.attr "for", "editor_title"
          title_label.attr "class", "editor_input_label"
          title_label.text "Title"

          title_input = $("<input>")
          title_input.attr "id", "editor_title"
          title_input.attr "class", "editor_input"
          title_input.attr "type", "text"
          title_input.attr "name", "editor_title"
          title_input.attr "value", design_title

          brief_div = $("<div></div>")
          brief_div.attr "id", "brief_row"
          brief_div.attr "class", "editor_row"

          brief_label = $("<span></span>")
          brief_label.attr "class", "editor_input_label"
          brief_label.text "Description"

          brief_input = $("<textarea>")
          brief_input.attr "id", "editor_brief"
          brief_input.attr "class", "editor_brief_input"
          brief_input.attr "type", "text"
          brief_input.attr "name", "editor_brief"
          brief_input.text design_description

          thumbnail_div = $("<div></div>")
          thumbnail_div.attr "id", "thumbnail_row"
          thumbnail_div.attr "class", "editor_row"

          thumbnail_title = $("<span></span>")
          thumbnail_title.attr "class", "editor_input_label"
          thumbnail_title.text "Thumbnail"

          thumbnail_container = $("<div></div>")
          thumbnail_container.attr "id", "thumbnail_container"
          thumbnail_container.attr "class", "thumbnail_container"

          thumbnail_image = $("<div></div>")
          thumbnail_image.attr "id", "thumbnail_preview"
          thumbnail_image.attr "class", "thumbnail_preview"
          thumbnail_image.css "background-image", "url('" + design_image + "')"

          thumbnail_input = $("<input>")
          thumbnail_input.attr "id", "thumbnail_input"
          thumbnail_input.attr "class", "editor_input"
          thumbnail_input.attr "type", "text"
          thumbnail_input.attr "name", "thumbnail_input"
          thumbnail_input.attr "value", design_image
          thumbnail_input.attr "style", "display: none"

          dropdown_row = $("<div></div>")
          dropdown_row.attr "id", "dropdown_row"
          dropdown_row.attr "class", "editor_row"

          design_file_select = $("<select></select>")
          design_file_select.attr "id", "design_file_selector"
          design_file_select.attr "class", "design_file_selector"
          design_file_select.attr "name", "design_file_selector"

          design_file_delete = $("<button></button>")
          design_file_delete.attr "id", "design_file_delete"
          design_file_delete.attr "class", "delete_button"

          thumbnail_upload_label = $("<label></label>")
          thumbnail_upload_label.attr "class", "standard_button"
          thumbnail_upload_label.attr "for", "thumbnail_upload"
          thumbnail_upload_label.text "UPLOAD IMAGE"

          thumbnail_upload = $("<input>")
          thumbnail_upload.attr "id", "thumbnail_upload"
          thumbnail_upload.attr "type", "file"
          thumbnail_upload.attr "style", "display: none"

          delete_design_button = $("<button></button>")
          delete_design_button.attr "id", "delete_design_button"
          delete_design_button.attr "class", "standard_button"
          delete_design_button.text "DELETE"

          $("#editor").append editor_container
          $("#editor_container").append title_div
          $("#title_row").append title_label
          $("#title_row").append title_input
          $("#editor_container").append brief_div
          $("#brief_row").append brief_label
          $("#brief_row").append brief_input
          $("#editor_container").append thumbnail_div
          $("#thumbnail_row").append thumbnail_title
          $("#thumbnail_row").append thumbnail_container
          $("#thumbnail_container").append thumbnail_image
          $("#editor_container").append dropdown_row
          $("#dropdown_row").append design_file_select
          $("#dropdown_row").append design_file_delete
          $("#editor_container").append editor_submit
          $("#editor_container").append thumbnail_upload_label
          $("#editor_container").append thumbnail_upload
          $("#editor_container").append delete_design_button
          $("#editor_container").append thumbnail_input

          Page.cmd "dbQuery", ["SELECT * FROM design_file LEFT JOIN json USING (json_id) WHERE design_uri='" +real_url+ "' ORDER BY date_added DESC LIMIT 50"], (res1) =>
            if res1.length > 0
              res1.forEach (row1, index) =>
                file_date_added = row1.file_uri.split("_")[0]
                file_directory = row1.file_uri.split("_")[1]
                Page.cmd "dbQuery", ["SELECT * FROM file LEFT JOIN json USING (json_id) WHERE date_added='" +file_date_added+ "' AND directory='" +file_directory+ "'"], (res2) =>
                  $("#design_file_selector").append $('<option></option>').val(JSON.stringify(row1)).text(res2[0].title)
            else
              console.log("Res5 is 0")
              $("#design_file_selector").append $('<option></option>').val("bundles_none").text("No files yet")

          delete_model = @delete_model
          $("#design_file_delete").on "click", (e) ->
            design_file_selector_value = $("#design_file_selector :selected").val()
            dfsv_parsed = JSON.parse(design_file_selector_value)
            #design_file_selector_value = $("#design_file_selector :selected").val()
            #parsed_design_file_selector_value = JSON.parse(design_file_selector_value)
            console.log("Design file selector date_added: " + dfsv_parsed.date_added)
            console.log("Design file selector file_uri: " + dfsv_parsed.file_uri)
            console.log("Design file selector design_uri: " + real_url)
            delete_model real_url, dfsv_parsed.file_uri, dfsv_parsed.date_added

          convert_base64 = @convert_base64
          $("#thumbnail_upload").on "change", (e) ->
            convert_base64()

          save_info = @save_info
          $("#editor_submit_button").on "click", (e) ->
            save_info design_name, $("#editor_title").val(), $("#editor_brief").val(), $("#thumbnail_input").val(), design_date_added
            e.preventDefault()

          delete_design = @delete_design
          $("#delete_design_button").on "click", (e) ->
            delete_design real_url, design_name
            e.preventDefault()
        else
          $("#editor").html "<span>Error: Permission denied!</span>"

    $("#main").attr "class", "main_nomenu"
    $("#main").html ""
    donav()

    $("#main").append editorbox

design_editor = new design_editor()
