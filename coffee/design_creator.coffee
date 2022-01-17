# design_creator.coffee

class design_creator
  convert_base64: =>
    max_size = 1024 * 25
    thumbnail_upload = $("#thumbnail_upload").prop("files")[0]

    if thumbnail_upload && thumbnail_upload.size < max_size
      convertImage(thumbnail_upload)
    else
      Page.cmd "wrapperNotification", ["info", "Max image size: 25kb (Tip: use GIMP or online compression tools to reduce resolution/quality!)"]
      debugger
      return false

  check_content_json: (cb) =>
    inner_path = "data/users/" + Page.site_info.auth_address + "/content.json"
    Page.cmd "fileGet", [inner_path, false], (res) =>
      if res
        res = JSON.parse(res)
      if res == null
        res = {}
      optional_pattern = "(?!data.json)"
      if res.optional is optional_pattern
        cb()
      res.optional = optional_pattern
      Page.cmd "fileWrite", [inner_path, Text.fileEncode(res)], cb

  register_design: (name, title, description, image_link, date_added, cb) =>
    inner_path = "data/users/" + Page.site_info.auth_address + "/data.json"
    Page.cmd "fileGet", [inner_path, false], (res) =>
      if res
        res = JSON.parse(res)
      if res is null or res is undefined
        res = {}
      if res.design is null or res.design is undefined
        res.design = {}
      res.design[name] = {title: title, description: description, image_link: image_link, date_added: date_added}
      Page.cmd "fileWrite", [inner_path, Text.fileEncode(res)], cb

  create_done: (name, title, date_added, user_address) =>
    #Page.set_url("?DesignEdit=" + date_added + "_" + user_address)
    Page.set_url("?Designs")
    console.log("Design creation done! ", name)

  create_design: (design_title, design_brief, design_image) =>
    time_stamp = Math.floor(new Date() / 1000)
    console.log("Creating new design: " + design_title)

    file_info = @file_info = {}
    register_design = @register_design
    create_done = @create_done
    new_design_name = design_title.replace(/\s/g, "_");
    @check_content_json (res) =>
      stamp_design_name = time_stamp + "-" + new_design_name
      console.log("loadend", arguments)
      file_info.status = "done"

      register_design stamp_design_name, design_title, design_brief, design_image, time_stamp, (res) ->
        Page.cmd "siteSign", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json"}, (res) ->
          Page.cmd "sitePublish", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json", "sign": false}, (res) ->
            create_done(stamp_design_name, design_title, time_stamp, Page.site_info.auth_address)

  render: =>
    design_editorbox = $("<div></div>")
    design_editorbox.attr "id", "design_editorbox"
    design_editorbox.attr "class", "editor"  
  
    design_container = $("<div></div>")
    design_container.attr "id", "design_container"
    design_container.attr "class", "editor_container"
 
    editor_submit = $("<button></button>")
    editor_submit.attr "id", "editor_submit_button"
    editor_submit.attr "class", "standard_button"
    editor_submit.text "PUBLISH"

    title_div = $("<div></div>")
    title_div.attr "id", "title_row"
    title_div.attr "class", "editor_row"

    title_label = $("<label></label>")
    title_label.attr "for", "design_name"
    title_label.attr "class", "editor_input_label"
    title_label.text "Name"

    title_input = $("<input>")
    title_input.attr "id", "design_name"
    title_input.attr "class", "editor_input"
    title_input.attr "type", "text"
    title_input.attr "name", "design_name"
    title_input.attr "value", "My new Design"

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
    brief_input.text "Write description here!"

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
    thumbnail_image.css "background-image", "url('img/design_empty.png')"

    thumbnail_input = $("<input>")
    thumbnail_input.attr "id", "thumbnail_input"
    thumbnail_input.attr "class", "editor_input"
    thumbnail_input.attr "type", "text"
    thumbnail_input.attr "name", "thumbnail_input"
    thumbnail_input.attr "value", "img/design_empty.png"
    thumbnail_input.attr "style", "display: none"

    thumbnail_upload_label = $("<label></label>")
    thumbnail_upload_label.attr "class", "standard_button"
    thumbnail_upload_label.attr "for", "thumbnail_upload"
    thumbnail_upload_label.text "UPLOAD IMAGE"

    thumbnail_upload = $("<input>")
    thumbnail_upload.attr "id", "thumbnail_upload"
    thumbnail_upload.attr "type", "file"
    thumbnail_upload.attr "style", "display: none"

    $("#main").attr "class", "main_nomenu"
    $("#main").html ""
    donav()

    $("#main").append design_editorbox
    $("#design_editorbox").append design_container
    $("#design_container").append title_div
    $("#title_row").append title_label
    $("#title_row").append title_input
    $("#design_container").append brief_div
    $("#brief_row").append brief_label
    $("#brief_row").append brief_input
    $("#design_container").append thumbnail_div
    $("#thumbnail_row").append thumbnail_title
    $("#thumbnail_row").append thumbnail_container
    $("#thumbnail_container").append thumbnail_image
    $("#design_container").append editor_submit
    $("#design_container").append thumbnail_upload_label
    $("#design_container").append thumbnail_upload
    $("#design_container").append thumbnail_input

    convert_base64 = @convert_base64
    $("#thumbnail_upload").on "change", (e) ->
      convert_base64()

    create_design = @create_design
    
    $("#editor_submit_button").on "click", (e) ->
      if Page.site_info.cert_user_id
        create_design $("#design_name").val(), $("#editor_brief").val(), $("#thumbnail_input").val()       
        $("#design_container").html "<div class='spinner'><div class='bounce1'></div></div>"       
        console.log("[NGnoid 3d: Creating design...]")       
      else
        Page.cmd "certSelect", [["zeroid.bit"]], (res) =>
          create_design $("#design_name").val(), $("#editor_brief").val(), $("#thumbnail_input").val()        
          $("#design_container").html "<div class='spinner'><div class='bounce1'></div></div>" 
          console.log("[NGnoid 3d: Creating design...]")
      e.preventDefault() 

design_creator = new design_creator()
