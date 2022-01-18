# video_player.coffee

class video_playing
  constructor: ->
    @stlControls
    @stlRenderer
    @stlCamera
    @stlScene
    @stlLight
    @stlGeometry
    @stlMaterial
    @stlMesh
    @stlLoader
    @video_started = 0
    @player_timeout

  delete_from_data_json: (file_uri, cid, com_body, com_date_added, cb) =>
    data_inner_path = "data/users/" + Page.site_info.auth_address + "/data.json";
    console.log("deleting comment from data.json at directory: " + Page.site_info.auth_address)
    Page.cmd "fileGet", data_inner_path, (res) =>
      data = JSON.parse(res)
      console.log(data["comment"][file_uri])

      comment_count = 0
      for i in data["comment"][file_uri]
        console.log("Comment row: " + data["comment"][file_uri][comment_count])
        if com_date_added.toString().indexOf(data["comment"][file_uri][comment_count]["date_added"]) != -1
          data["comment"][file_uri].splice(comment_count, 1)
          break
        comment_count++

      Page.cmd "fileWrite", [data_inner_path, Text.fileEncode(data)], (res) =>
        cb?(res)

  delete_report_from_data_json: (file_uri, cb) =>
    data_inner_path = "data/users/" + Page.site_info.auth_address + "/data.json"
    Page.cmd "fileGet", data_inner_path, (res) =>
      data = JSON.parse(res)

      delete data["file_report"][file_uri]

      Page.cmd "fileWrite", [data_inner_path, Text.fileEncode(data)], (res) =>
        cb?(res)

  delete_like_from_data_json: (file_uri, cb) =>
    data_inner_path = "data/users/" + Page.site_info.auth_address + "/data.json"
    Page.cmd "fileGet", data_inner_path, (res) =>
      data = JSON.parse(res)

      delete data["file_vote"][file_uri]

      Page.cmd "fileWrite", [data_inner_path, Text.fileEncode(data)], (res) =>
        cb?(res)

  delete_sub_from_data_json: (user_directory, cb) =>
    data_inner_path = "data/users/" + Page.site_info.auth_address + "/data.json"
    Page.cmd "fileGet", data_inner_path, (res) =>
      data = JSON.parse(res)

      delete data["subscription"][user_directory]

      Page.cmd "fileWrite", [data_inner_path, Text.fileEncode(data)], (res) =>
        cb?(res)

  delete_report: (date_added, user_address) =>
    file_uri = date_added + "_" + user_address
    delete_report_from_data_json = @delete_report_from_data_json
    content_inner_path = "data/users/" + Page.site_info.auth_address + "/content.json"

    this_load_report = @load_report

    Page.cmd "wrapperConfirm", ["Unreport?", "Ok"], =>
      delete_report_from_data_json file_uri, (res) ->
        if res == "ok"
          Page.cmd "sitePublish", {"inner_path": content_inner_path}
          console.log("[KopyKate: Unreported]")
          this_load_report(file_uri)

  delete_like: (date_added, user_address) =>
    file_uri = date_added + "_" + user_address
    delete_like_from_data_json = @delete_like_from_data_json
    content_inner_path = "data/users/" + Page.site_info.auth_address + "/content.json"

    this_load_likes = @load_likes

    Page.cmd "wrapperConfirm", ["Unlike?", "Ok"], =>
      delete_like_from_data_json file_uri, (res) ->
        if res == "ok"
          Page.cmd "sitePublish", {"inner_path": content_inner_path}
          console.log("[KopyKate: Unliked]")
          this_load_likes(file_uri)


  delete_subscription: (file_uri, user_address) =>
    delete_sub_from_data_json = @delete_sub_from_data_json
    content_inner_path = "data/users/" + Page.site_info.auth_address + "/content.json";

    this_load_subs = @load_subs

    Page.cmd "wrapperConfirm", ["Unsubscribe?", "Ok"], =>
      delete_sub_from_data_json user_address, (res) ->
        if res == "ok"
          Page.cmd "sitePublish", {"inner_path": content_inner_path}
          console.log("[KopyKate: Unsubscribed]")
          this_load_subs(file_uri)

  delete_comment: (file_uri, cid, body, date_added) =>
    delete_from_data_json = @delete_from_data_json
    content_inner_path = "data/users/" + Page.site_info.auth_address + "/content.json";

    this_load_comments = @load_comments

    Page.cmd "wrapperConfirm", ["Delete comment?", "Delete"], =>
      delete_from_data_json file_uri, cid, body, date_added, (res) ->
        if res == "ok"
          Page.cmd "sitePublish", {"inner_path": content_inner_path}
          console.log("[KopyKate: Deleted comment]")
          this_load_comments(file_uri)

  register_subscription: (file_directory, cb) =>
    inner_path = "data/users/" + Page.site_info.auth_address + "/data.json"
    Page.cmd "fileGet", [inner_path, false], (res) =>
      if res
        res = JSON.parse(res)
      if res is null
        res = {}
      if res.subscription is null or res.subscription is undefined
        res.subscription = {}
      if res.subscription[file_directory] is null or res.subscription[file_directory] is undefined
        res.subscription[file_directory] = 1

      Page.cmd "fileWrite", [inner_path, Text.fileEncode(res)], cb

  register_comment: (file_uri, body, date_added, cb) =>
    inner_path = "data/users/" + Page.site_info.auth_address + "/data.json"
    Page.cmd "fileGet", [inner_path, false], (res) =>
      console.log "This is comment res: " + JSON.parse(res)
      if res
        res = JSON.parse(res)
      if res is null
        res = {}
      if res.comment is null or res.comment is undefined
        res.comment = {}
      if res.comment[file_uri] is null or res.comment[file_uri] is undefined
        res.comment[file_uri] = []

      console.log(res.comment)
      console.log(file_uri)
      console.log(res.comment[file_uri])

      res.comment[file_uri].push({body: body, date_added: date_added})
      Page.cmd "fileWrite", [inner_path, Text.fileEncode(res)], cb


  register_vote: (file_uri, cb) =>
    inner_path = "data/users/" + Page.site_info.auth_address + "/data.json"
    Page.cmd "fileGet", [inner_path, false], (res) =>
      #console.log "This is comment res: " + JSON.parse(res)
      if res
        res = JSON.parse(res)
      if res is null
        res = {}
      if res.file_vote is null or res.file_vote is undefined
        res.file_vote = {}
      if res.file_vote[file_uri] is null or res.file_vote[file_uri] is undefined
        res.file_vote[file_uri] = []

      console.log(res.file_vote)
      console.log(file_uri)
      console.log(res.file_vote[file_uri])

      res.file_vote[file_uri] = 1
      Page.cmd "fileWrite", [inner_path, Text.fileEncode(res)], cb

  register_report: (file_uri, cb) =>
    inner_path = "data/users/" + Page.site_info.auth_address + "/data.json"
    Page.cmd "fileGet", [inner_path, false], (res) =>
      if res
        res = JSON.parse(res)
      if res is null
        res = {}
      if res.file_vote is null or res.file_report is undefined
        res.file_report = {}
      if res.file_report[file_uri] is null or res.file_report[file_uri] is undefined
        res.file_report[file_uri] = []

      res.file_report[file_uri] = 1
      Page.cmd "fileWrite", [inner_path, Text.fileEncode(res)], cb

  register_to_design: (design_uri, file_uri, date_added, cb) =>
    inner_path = "data/users/" + Page.site_info.auth_address + "/data.json"
    Page.cmd "fileGet", [inner_path, false], (res) =>
      if res
        res = JSON.parse(res)
      if res is null
        res = {}
      if res.design_file is null or res.design_file is undefined
        res.design_file = {}
      if res.design_file[design_uri] is null or res.design_file[design_uri] is undefined
        res.design_file[design_uri] = []

      res.design_file[design_uri].push({file_uri: file_uri, date_added: date_added})
      Page.cmd "fileWrite", [inner_path, Text.fileEncode(res)], cb

  subscribe: (file_date_added, file_directory) =>
    file_uri = file_date_added + "_" + file_directory
    register_subscription = @register_subscription
    load_subs = @load_subs
    editor.check_content_json (res) =>
      register_subscription file_directory, (res) =>
        load_subs(file_uri)
        Page.cmd "siteSign", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json"}, (res) ->
          Page.cmd "sitePublish", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json", "sign": false}

  add_vote: (file_date_added, file_directory) =>
    file_uri = file_date_added + "_" + file_directory
    register_vote = @register_vote
    load_likes = @load_likes
    editor.check_content_json (res) =>
      register_vote file_uri, (res) =>
        load_likes(file_uri)
        Page.cmd "siteSign", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json"}, (res) ->
          Page.cmd "sitePublish", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json", "sign": false}

  add_report: (file_date_added, file_directory) =>
    file_uri = file_date_added + "_" + file_directory
    register_report = @register_report
    load_report = @load_report
    editor.check_content_json (res) =>
      register_report file_uri, (res) =>
        load_report(file_uri)
        Page.cmd "siteSign", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json"}, (res) ->
          Page.cmd "sitePublish", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json", "sign": false}

  add_to_design: (option_val, file_uri) =>
    option_val_obj = JSON.parse(option_val)
    design_uri = option_val_obj['date_added'] + "_" + option_val_obj['directory']
    register_to_design = @register_to_design

    editor.check_content_json (res) =>
      register_to_design design_uri, file_uri, Time.timestamp(), (res) =>
        Page.cmd "siteSign", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json"}, (res) ->
          Page.cmd "sitePublish", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json", "sign": false}

  write_comment: (file_date_added, file_directory, comment_body) =>
    register_comment = @register_comment
    load_comments = @load_comments
    file_uri = file_date_added + "_" + file_directory
    editor.check_content_json (res) =>
      register_comment file_uri, comment_body, Time.timestamp(), (res) ->
        load_comments(file_uri)
        Page.cmd "siteSign", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json"}, (res) ->
          Page.cmd "sitePublish", {inner_path: "data/users/" + Page.site_info.auth_address + "/content.json", "sign": false}

  load_related: (query_string) =>
    Page.cmd "dbQuery", ["SELECT * FROM file LEFT JOIN json USING (json_id) WHERE file.title LIKE '%" +query_string+ "%' ORDER BY date_added DESC"], (res0) =>
      if res0.length < 15
        query = "WHERE file.title LIKE '%%'"
      else
        query = "WHERE file.title LIKE '%" +query_string+ "%'"

      #console.log("FIRST WORD: " + query_string)
      order_actual = {filter: "", address: "1L7aqQovTqoaARXnaTNPV7csErPMJfX3Dp", limit: 1000}
      Page.cmd "dbQuery", ["SELECT * FROM file LEFT JOIN json USING (json_id) "+query+" ORDER BY date_added DESC LIMIT 15"], (res1) =>

        related_counter = 0

        $("#related_column").html ""
        $("#related_column").append "<div class='related_header'>Similar Models</div>"

        for row1, i in res1
          video_string = row1.date_added + "_" + row1.directory
          full_channel_name = row1.cert_user_id
          video_channel_name = row1.cert_user_id.split("@")[0]

          video_row_id = "related_" + related_counter
          video_row = $("<div></div>")
          video_row.attr "id", video_row_id
          video_row.attr "class", "related_row"

          video_info_id = "relate_info_" + related_counter
          video_info = $("<div></div>")
          video_info.attr "id", video_info_id
          video_info.attr "class", "related_info"

          video_link_id = "related_link_" + related_counter
          video_link = $("<a></a>")
          video_link.attr "id", video_link_id
          video_link.attr "class", "related_link"
          video_link.attr "href", "?Model=" + video_string
          video_link.text row1.title

          video_channel_id = "related_channel_" + related_counter
          video_channel = $("<a></a>")
          video_channel.attr "id", video_channel_id
          video_channel.attr "class", "related_channel"
          video_channel.attr "href", "?Channel=" + full_channel_name
          video_channel.text video_channel_name.charAt(0).toUpperCase() + video_channel_name.slice(1)

          thumbnail_id = "related_thumb_" + related_counter
          thumbnail = $("<a></a>")
          thumbnail.attr "id", thumbnail_id
          thumbnail.attr "class", "related_thumb"
          thumbnail.css "background-image", "url('"+row1.image_link+"')"
          thumbnail.attr "href", "?Model=" + video_string

          $("#related_column").append video_row
          $("#" + video_row_id).append thumbnail
          $("#" + video_row_id).append video_info
          $("#" + video_info_id).append video_link
          $("#" + video_info_id).append video_channel
          $("#" + thumbnail_id).on "click", ->
            Page.nav(this.href)
          $("#" + video_link_id).on "click", ->
            Page.nav(this.href)
          $("#" + video_channel_id).on "click", ->
            Page.nav(this.href)

          related_counter += 1

  load_design_files: (design_url) =>
    Page.cmd "dbQuery", ["SELECT * FROM design_file LEFT JOIN json USING (json_id) WHERE design_uri='"+design_url+"' ORDER BY date_added ASC"], (res7) =>
      if res7.length > 0

        $("#related_column").html ""
        $("#related_column").append "<div class='related_header'>Design Files</div>"

        res7.forEach (row1, related_index) =>
          design_file_uri = row1.file_uri
          console.log("Adding file uri: " + design_file_uri)
          file_date_added = design_file_uri.split("_")[0]
          file_user_address = design_file_uri.split("_")[1]

          Page.cmd "dbQuery", ["SELECT * FROM file LEFT JOIN json USING (json_id) WHERE date_added='" + file_date_added + "' AND directory='" + file_user_address + "'"], (res8) =>
            design_file_index = related_index + 1

            video_string = res8[0].date_added + "_" + res8.directory
            full_file_channel_name = res8[0].cert_user_id
            file_channel_name = res8[0].cert_user_id.split("@")[0]

            video_row_id = "related_" + related_index
            video_row = $("<div></div>")
            video_row.attr "id", video_row_id
            video_row.attr "class", "related_row"

            video_info_id = "relate_info_" + related_index
            video_info = $("<div></div>")
            video_info.attr "id", video_info_id
            video_info.attr "class", "related_info"

            video_link_id = "related_link_" + related_index
            video_link = $("<a></a>")
            video_link.attr "id", video_link_id
            video_link.attr "class", "related_link"
            video_link.attr "href", "?DesignView=" + design_url + "_" + design_file_index
            video_link.text res8[0].title

            video_channel_id = "related_channel_" + related_index
            video_channel = $("<a></a>")
            video_channel.attr "id", video_channel_id
            video_channel.attr "class", "related_channel"
            video_channel.attr "href", "?Channel=" + full_file_channel_name
            video_channel.text file_channel_name.charAt(0).toUpperCase() + file_channel_name.slice(1)

            thumbnail_id = "related_thumb_" + related_index
            thumbnail = $("<a></a>")
            thumbnail.attr "id", thumbnail_id
            thumbnail.attr "class", "related_thumb"
            thumbnail.css "background-image", "url('"+res8[0].image_link+"')"
            thumbnail.attr "href", "?DesignView=" + design_url + "_" + design_file_index

            $("#related_column").append video_row
            $("#" + video_row_id).append thumbnail
            $("#" + video_row_id).append video_info
            $("#" + video_info_id).append video_link
            $("#" + video_info_id).append video_channel
            $("#" + thumbnail_id).on "click", ->
              Page.nav(this.href)
            $("#" + video_link_id).on "click", ->
              Page.nav(this.href)
            $("#" + video_channel_id).on "click", ->
              Page.nav(this.href)

  load_subs: (real_url) =>
    #init_url = Page.history_state["url"]
    #real_url = init_url.split("Model=")[1]

    video_date_added = real_url.split("_")[0]
    video_user_address = real_url.split("_")[1]
    file_url = real_url

    query = "SELECT * FROM subscription LEFT JOIN json USING (json_id) WHERE user_address='" + video_user_address + "'"

    Page.cmd "dbQuery", [query], (res) =>
      sub_counter = 0

      i = 0
      is_subscribed = false

      for sub, i in res
        sub_counter += 1
        if sub.directory == Page.site_info.auth_address
          is_subscribed = true

      if i is res.length
        if is_subscribed
          unsubscribe_button = $("<a></a>")
          unsubscribe_button.attr "id", "unsubscribe_now_button"
          unsubscribe_button.attr "class", "subscribe_icon b64_green"
          unsubscribe_button.attr "href", "javascript:void(0)"

          $("#subscribers").html " Unfollow " + sub_counter
          $("#subscribe_button").html unsubscribe_button

          delete_subscription = @delete_subscription
          $("#unsubscribe_now_button").on "click", ->
            if Page.site_info.cert_user_id
              delete_subscription real_url, video_user_address
            else
              Page.cmd "certSelect", [["zeroid.bit"]], (res) =>
                delete_subscription video_user_address
        else
          subscribe_button = $("<a></a>")
          subscribe_button.attr "id", "subscribe_now_button"
          subscribe_button.attr "class", "subscribe_icon"
          subscribe_button.attr "href", "javascript:void(0)"

          $("#subscribers").html " Follow " + sub_counter
          $("#subscribe_button").html subscribe_button

          subscribe = @subscribe
          $("#subscribe_now_button").on "click", ->
            if Page.site_info.cert_user_id
              subscribe video_date_added, video_user_address
            else
              Page.cmd "certSelect", [["zeroid.bit"]], (res) =>
                subscribe video_date_added, video_user_address

  load_report: (real_url) =>
    #init_url = Page.history_state["url"]
    #real_url = init_url.split("Model=")[1]

    video_date_added = real_url.split("_")[0]
    video_user_address = real_url.split("_")[1]
    file_uri = real_url

    query = "SELECT * FROM file_report LEFT JOIN json USING (json_id) WHERE file_uri='" + real_url + "'"

    Page.cmd "dbQuery", [query], (res) =>
      report_counter = 0

      i = 0
      is_reported = false

      for report, i in res
        report_counter += 1
        if report.directory == Page.site_info.auth_address
          is_reported = true

      if i is res.length
        if is_reported
          unreport_button = $("<a></a>")
          unreport_button.attr "id", "unreport_now_button"
          unreport_button.attr "class", "report_icon b64_red"
          unreport_button.attr "href", "javascript:void(0)"

          $("#report_button").html ""
          $("#report_button").append "<span> Unreport</span>"
          $("#report_button").append unreport_button

          delete_report = @delete_report
          $("#unreport_now_button").on "click", ->
            if Page.site_info.cert_user_id
              delete_report video_date_added, video_user_address
            else
              Page.cmd "certSelect", [["zeroid.bit"]], (res) =>
                delete_report video_date_added, video_user_address

        else
          report_button = $("<a></a>")
          report_button.attr "id", "report_now_button"
          report_button.attr "class", "report_icon"
          report_button.attr "href", "javascript:void(0)"

          $("#report_button").html ""
          $("#report_button").append "<span> Report</span>"
          $("#report_button").append report_button

          add_report = @add_report
          $("#report_now_button").on "click", ->
            if Page.site_info.cert_user_id
              add_report video_date_added, video_user_address
            else
              Page.cmd "certSelect", [["zeroid.bit"]], (res) =>
                add_report video_date_added, video_user_address

  load_likes: (real_url) =>
    #init_url = Page.history_state["url"]
    #real_url = init_url.split("Model=")[1]

    video_date_added = real_url.split("_")[0]
    video_user_address = real_url.split("_")[1]
    file_uri = real_url

    query = "SELECT * FROM file_vote LEFT JOIN json USING (json_id) WHERE file_uri='" + real_url + "'"

    Page.cmd "dbQuery", [query], (res) =>
      like_counter = 0

      i = 0
      is_liked = false

      for vote, i in res
        like_counter += 1
        if vote.directory == Page.site_info.auth_address
          is_liked = true

      if i is res.length
        if is_liked
          unlike_button = $("<a></a>")
          unlike_button.attr "id", "unlike_now_button"
          unlike_button.attr "class", "like_icon b64_green"
          unlike_button.attr "href", "javascript:void(0)"

          $("#like_button").html unlike_button
          $("#likes_total").html "<span style='margin-left: 5px'>Unlike </span>" + like_counter

          delete_like = @delete_like
          $("#unlike_now_button").on "click", ->
            if Page.site_info.cert_user_id
              delete_like video_date_added, video_user_address
            else
              Page.cmd "certSelect", [["zeroid.bit"]], (res) =>
                delete_like video_date_added, video_user_address
        else
          like_button = $("<a></a>")
          like_button.attr "id", "like_now_button"
          like_button.attr "class", "like_icon"
          like_button.attr "href", "javascript:void(0)"

          $("#like_button").html like_button
          $("#likes_total").html "<span style='margin-left: 5px'>Like </span>" + like_counter

          add_vote = @add_vote
          $("#like_now_button").on "click", ->
            if Page.site_info.cert_user_id
              add_vote video_date_added, video_user_address
            else
              Page.cmd "certSelect", [["zeroid.bit"]], (res) =>
                add_vote video_date_added, video_user_address

          #$("#video_likes").text like_counter + " Like"
          #console.log "Like counter: " + like_counter

  load_comments: (real_url) =>
    #init_url = Page.history_state["url"]
    #real_url = init_url.split("Model=")[1]

    video_date_added = real_url.split("_")[0]
    video_user_address = real_url.split("_")[1]
    file_uri = real_url

    query = "SELECT * FROM comment LEFT JOIN json USING (json_id) WHERE file_uri='" + real_url + "' ORDER BY date_added DESC"

    Page.cmd "dbQuery", [query], (res) =>

      comment_input = $("<input>")
      comment_input.attr "id", "comment_box_input"
      comment_input.attr "class", "comment_box_input"
      comment_input.attr "placeholder", "Write a comment..."

      my_counter = 0
      comment_counter = 0
      $("#comment_actual").html ""
      $("#comment_actual").append comment_input

      write_comment = @write_comment
      $("#comment_box_input").on "keypress", (e) ->
        comment_body = this.value
        if e.which == 13
          if Page.site_info.cert_user_id
            write_comment video_date_added, video_user_address, comment_body
          else
            Page.cmd "certSelect", [["zeroid.bit"]], (res) =>
              write_comment video_date_added, video_user_address, comment_body

      for comment in res
        comment_body = comment.body
        comment_body = comment.body.replace /</g, ' < '
        comment_body = comment.body.replace />/g, ' > '
        comment_date_added = comment.date_added
        comment_directory = comment.directory
        if comment.cert_user_id is null or comment.cert_user_id is undefined
          comment_user_id = "guest"
        else
          comment_user_id = comment.cert_user_id.split("@")[0]
        comment_id = "comment_" + comment_date_added + "_" + comment_directory

        comment_single_id = "comment_" + comment_counter
        comment_single = $("<div></div>")
        comment_single.attr "id", comment_single_id
        comment_single.attr "class", "comment_single"

        comment_this_user_id = "comment_user_" + comment_counter
        comment_user = $("<div></div>")
        comment_user.attr "id", comment_this_user_id

        comment_icon = $("<div></div>")
        comment_icon.attr "class", "comment_icon"

        comment_username = $("<span></span>")
        comment_username.attr "class", "comment_user"
        comment_username.text comment_user_id.charAt(0).toUpperCase() + comment_user_id.slice(1)

        comment_date = $("<span></span>")
        comment_date.attr "id", "comment_date"
        comment_date.attr "class", "comment_date"
        comment_date.text " " + Time.since(comment_date_added)

        comment_delete_id = "comment_delete_" + comment_counter
        comment_delete = $("<a></a>")
        comment_delete.attr "id", comment_delete_id
        comment_delete.attr "class", "comment_delete"
        comment_delete.attr "href", "javascript:void(0)"
        comment_delete.attr "data-uri", file_uri
        comment_delete.attr "data-cid", my_counter
        comment_delete.attr "data-body", comment.body
        comment_delete.attr "data-date", comment.date_added
        comment_delete.text " [-delete]"

        comment_text = $("<div></div>")
        comment_text.attr "id", "comment_text"
        comment_text.attr "class", "comment_text"
        comment_text.text comment_body

        $("#comment_actual").append comment_single
        $("#" + comment_single_id).append comment_user
        $("#" + comment_this_user_id).append comment_username
        $("#" + comment_this_user_id).append comment_date
        $("#" + comment_this_user_id).append comment_icon
        if Page.site_info.cert_user_id is comment.cert_user_id
          $("#" + comment_this_user_id).append comment_delete
        $("#" + comment_single_id).append comment_text

        delete_comment = @delete_comment
        $("#" + comment_delete_id).on "click", ->
          console.log("Body: " + $(this).data("body"))
          console.log("Date added: " + $(this).data("date"))
          console.log("File uri: " + $(this).data("uri"))
          console.log("Cid: " + $(this).data("cid"))
          delete_comment $(this).data("uri"), $(this).data("cid"), $(this).data("body"), $(this).data("date")

        comment_counter = comment_counter + 1
        if Page.site_info.cert_user_id is comment.cert_user_id
          my_counter += 1

  startAnimate: =>
    @stlRenderer.render( @stlScene, @stlCamera )
    @stlControls.update()
    requestAnimationFrame(@startAnimate)

  render_video: (video_path) =>
    if Page.first_time == 1
      console.log 'Removing mesh.'
      @stlScene.remove(@stlMesh)

    $("#video_box").html ""
    container = document.getElementById "video_box"
    @video_started = 0

    @stlCamera = new THREE.PerspectiveCamera( 60, 768 / 432, 1, 1000 )
    stlCamera = @stlCamera
    stlCamera.position.set( 0, 0, 75 )

    @stlScene = new THREE.Scene()
    @stlScene.add(new THREE.AmbientLight(0x000000))

    @stlLight = new THREE.DirectionalLight(0xffffff)
    stlLight = @stlLight

    stlLight.position.set(1, 1, 1)
    @stlScene.add(stlLight)

    @stlRenderer = new THREE.WebGLRenderer( { antialias: true } )
    stlRenderer = @stlRenderer

    if window.innerWidth >= 1366
      stlRenderer.setSize( 768, 432 )
      stlCamera.aspect = 768 / 432
    else if window.innerWidth < 1366 && window.innerWidth >= 1024
      stlRenderer.setSize( 640, 360 )
      stlCamera.aspect = 640 / 360
    else if window.innerWidth < 1024 && window.innerWidth >= 768
      stlRenderer.setSize( 768, 360 )
      stlCamera.aspect = 768 / 360
    else if window.innerWidth < 768 && window.innerWidth >= 640
      stlRenderer.setSize( window.innerWidth, 288 )
      stlCamera.aspect = window.innerWidth / 288
    else if window.innerWidth < 640 && window.innerWidth >= 432
      stlRenderer.setSize( window.innerWidth, 288 )
      stlCamera.aspect = window.innerWidth / 288

    stlCamera.updateProjectionMatrix();

    stlRenderer.setClearColor( 0xffffff, 1 );
    stlRenderer.gammaInput = true;
    stlRenderer.gammaOutput = true;
    container.appendChild( stlRenderer.domElement );

    $("#video_box").append "<div id='loading_spinner' class='loading_container'><div class='loading_container2'><div class='cube'><div class='sides'><div class='top'></div><div class='right'></div><div class='bottom'></div><div class='left'></div><div class='front'></div><div class='back'></div></div></div>"

    @stlControls = new THREE.TrackballControls( stlCamera, stlRenderer.domElement )
    stlControls = @stlControls

    stlControls.rotateSpeed = 0.3
    stlControls.noPan = true
    stlControls.staticMoving = false
    stlControls.dynamicDampingFactor = 0.2

    @startAnimate()

    stlLoader = new THREE.STLLoader()
    stlScene = @stlScene

    stlLoader.addEventListener "load", (event) ->
      stlGeometry = event.content
      stlMaterial = new THREE.MeshLambertMaterial( { color: 0x880000, emissive: 0x000000, emissiveIntensity: .8, side: THREE.DoubleSide } )
      @stlMesh = new THREE.Mesh( stlGeometry, stlMaterial )
      @stlMesh.position.set( 0, 0, 0)
      stlScene.add( this.stlMesh )

    window.addEventListener "resize", () ->
      if window.innerWidth >= 1366
        stlRenderer.setSize( 768, 432 )
        stlCamera.aspect = 768 / 432
      else if window.innerWidth < 1366 && window.innerWidth >= 1024
        stlRenderer.setSize( 640, 360 )
        stlCamera.aspect = 640 / 360
      else if window.innerWidth < 1024 && window.innerWidth >= 768
        stlRenderer.setSize( 768, 360 )
        stlCamera.aspect = 768 / 360
      else if window.innerWidth < 768 && window.innerWidth >= 640
        stlRenderer.setSize( window.innerWidth, 288 )
        stlCamera.aspect = window.innerWidth / 288
      else if window.innerWidth < 640 && window.innerWidth >= 432
        stlRenderer.setSize( window.innerWidth, 288 )
        stlCamera.aspect = window.innerWidth / 288

    Page.cmd "wrapperGetAjaxKey", {}, (res) =>
      stlLoader.load(video_path, res)

    Page.first_time = 1;

  render_player: (file_uri, render_mode, design_url) =>
    #init_url = Page.history_state["url"]
    #real_url = init_url.split("Model=")[1]

    date_added = file_uri.split("_")[0]
    user_address = file_uri.split("_")[1]

    query = "SELECT * FROM file LEFT JOIN json USING (json_id) WHERE date_added='" + date_added + "' AND directory='" + user_address + "'"
    Page.cmd "dbQuery", [query], (res1) =>
      if res1.length > 0
        optional_file_path = optional_path = "data/users/" + res1[0]['directory'] + "/" + res1[0]['file_name']
      Page.cmd "optionalFileInfo", optional_file_path, (res2) =>
        if res1.length > 0
          my_row = res1[0]
          file_name = my_row['file_name']
          video_title = my_row['title']
          video_channel = my_row['cert_user_id'].split("@")[0]
          video_description = my_row['description']
          video_date_added = my_row['date_added']
          user_directory = my_row['directory']

          stats_loaded = false

          my_file = res2
          if res2
            optional_name = my_file['inner_path'].replace /.*\//, ""
            optional_peer = my_file['peer']
            optional_seed = my_file['peer_seed']

            if typeof optional_seed != 'undefined'
              optional_seed = my_file['peer_seed']
            else
              optional_seed = "-"

            if optional_name is file_name
              stats_loaded = true
              $("#player_info").append "<span class='video_player_title'>" + video_title + "</span>"
              $("#player_info").append "<div id='player_stats' class='video_player_stats'><span>" + optional_seed + " / " + optional_peer + " <div class='lightning_icon'></div></span></div>"
              $("#player_info").append "<div id='additional_info' class='video_player_stats'></div>"
              $("#player_info").append "<span class='video_player_username'>" + video_channel.charAt(0).toUpperCase() + video_channel.slice(1) + "</span>"
              $("#player_info").append "<span class='video_player_userdate'>Published " + Time.since(video_date_added) + "</span><br>"
              $("#player_info").append "<span class='video_player_brief'>" + video_description + "</span>"
              $("#player_info").append "<div class='player_icon'></div>"

          else
            stats_loaded = false
            $("#player_info").append "<span class='video_player_title'>" + video_title + "</span>"
            $("#player_info").append "<div id='player_stats' class='video_player_stats'><span>0 / 0 Peers &middot; </span></div><br>"
            $("#player_info").append "<div id='additional_info' class='video_player_stats'></div>"
            $("#player_info").append "<span class='video_player_username'>" + video_channel.charAt(0).toUpperCase() + video_channel.slice(1) + "</span>"
            $("#player_info").append "<span class='video_player_userdate'>Published " + Time.since(video_date_added) + "</span><br>"
            $("#player_info").append "<span class='video_player_brief'>" + video_description + "</span>"
            $("#player_info").append "<div class='player_icon'></div>"

          $("#additional_info").hide()

          video_actual = "data/users/" + user_directory + "/" + file_name

          @render_video(video_actual)

          word_array = video_title.split(" ")

          dl_icon_button = $("<a></a>")
          dl_icon_button.attr "id", "dl_icon_button"
          dl_icon_button.attr "class", "download_icon"
          dl_icon_button.attr "href", video_actual
          dl_icon_button.attr "download", file_name
          dl_icon_button.attr "target", "_blank"

          collect_icon_button = $("<a></a>")
          collect_icon_button.attr "id", "collect_icon_button"
          collect_icon_button.attr "class", "add_icon"
          collect_icon_button.attr "href", "javascript:void(0)"

          $("#player_stats").append "<span id='likes_total'></span>"
          $("#player_stats").append "<span id='like_button'></span>"
          $("#player_stats").append "<span id='subscribers'></span>"
          $("#player_stats").append "<span id='subscribe_button'></span>"
          $("#player_stats").append "<span id='report_button'></span>"
          $("#player_stats").append "<span id='download_button'><span> Get</span></span>"
          $("#download_button").append dl_icon_button
          $("#player_stats").append "<span id='collect_button'><span> Add</span></span>"
          $("#collect_button").append collect_icon_button

          @load_likes(file_uri)
          @load_subs(file_uri)
          @load_report(file_uri)
          @load_comments(file_uri)

          add_report = @add_report
          $("#report_button").on "click", ->
            if Page.site_info.cert_user_id
              add_report date_added, user_address
            else
              Page.cmd "certSelect", [["zeroid.bit"]], (res) =>
                add_report date_added, user_address

          if render_mode is "model"
            @load_related(word_array[0])
          else if render_mode is "design"
            @load_design_files(design_url)
            $("#collect_button").hide()
            $("#collect_icon_button").hide()

          add_to_design = @add_to_design
          $("#collect_icon_button").on "click", ->
            design_select = $("<select></select>")
            design_select.attr "id", "design_selector"
            design_select.attr "class", "design_selector"
            design_select.attr "name", "design_selector"
            $("#additional_info").append design_select
            $("#additional_info").show()
            $("#player_stats").hide()

            collect_submit = $("<span> Submit!</span>")

            collect_icon_submit = $("<a></a>")
            collect_icon_submit.attr "id", "add_2_design"
            collect_icon_submit.attr "class", "add_icon"
            collect_icon_submit.attr "href", "javascript:void(0)"

            $("#additional_info").append collect_submit
            $("#additional_info").append collect_icon_submit

            if Page.site_info.cert_user_id
              Page.cmd "dbQuery", ["SELECT * FROM design LEFT JOIN json USING (json_id) WHERE cert_user_id='" +Page.site_info.cert_user_id+ "' ORDER BY date_added DESC LIMIT 50"], (res5) =>
                if res5.length > 0
                  res5.forEach (row5, index) =>
                    $("#design_selector").append $('<option></option>').val(JSON.stringify(row5)).text(row5.title)
                else
                  console.log("Res5 is 0")
                  $("#design_selector").append $('<option></option>').val("bundles_none").text("No bundles yet")
            else
              Page.cmd "certSelect", [["zeroid.bit"]], (resExec) =>
                Page.cmd "dbQuery", ["SELECT * FROM design LEFT JOIN json USING (json_id) WHERE cert_user_id='" +Page.site_info.cert_user_id+ "' ORDER BY date_added DESC LIMIT 50"], (res5) =>
                  if res5.length > 0
                    res5.forEach (row5, index) =>
                      $("#design_selector").append $('<option></option>').val(JSON.stringify(row5)).text(row5.title)
                  else
                    console.log("Res5 is 0")
                    $("#design_selector").append $('<option></option>').val("bundles_none").text("No bundles yet")

            $("#add_2_design").on "click", ->
              design_selector_value = $("#design_selector :selected").val()
              if design_selector_value is "bundles_none"
                Page.cmd "wrapperNotification", ["info", "Error: No bundles yet! Try creating one first..."]
              else
                parsed_design_selector_value = JSON.parse(design_selector_value)
                proper_design_uri = parsed_design_selector_value.date_added + "_" + parsed_design_selector_value.directory
                console.log(design_selector_value)
                Page.cmd "dbQuery", ["SELECT * FROM design_file LEFT JOIN json USING (json_id) WHERE file_uri='" +file_uri+ "' AND design_uri='" +proper_design_uri+ "'"], (res9) =>
                  if res9.length is 0
                    add_to_design design_selector_value, file_uri
                    $("#additional_info").hide()
                    $("#player_stats").show()
                    $("#collect_button").remove()
                    $("#collect_icon_button").remove()
                  else
                    Page.cmd "wrapperNotification", ["info", "Error: model already exists in bundle!"]
        else
          $("#video_box").html ""
          $("#video_box").html "<p style='color: white; margin-left: 10px'>Error: Unable to load model file!</p><p style='color: white; margin-left: 10px'>If you're sure it exists, try:</p><p style='color: white; margin-left: 10px'>1. Clearing your cache</p><p style='color: white; margin-left: 10px'>2. Waiting for ZeroNet to fully download the site.</p>"
  render: =>
    video_player = $("<div></div>")
    video_player.attr "id", "video_player"
    video_player.attr "class", "video_player"

    video_column = $("<div></div>")
    video_column.attr "id", "video_column"
    video_column.attr "class", "video_column"

    related_column = $("<div></div>")
    related_column.attr "id", "related_column"
    related_column.attr "class", "related_column"

    related_text =

    video_box = $("<div></div>")
    video_box.attr "id", "video_box"
    video_box.attr "class", "video_box"

    video_info = $("<div></div>")
    video_info.attr "id", "player_info"
    video_info.attr "class", "player_info"

    comment_div = $("<div></div>")
    comment_div.attr "id", "comment_box"
    comment_div.attr "class", "player_info"

    comment_actual = $("<div></div>")
    comment_actual.attr "id", "comment_actual"
    comment_actual.attr "class", "comment_actual"

    $("#main").attr "class", "main_nomenu"
    $("#main").html ""
    donav()

    $("#main").append video_player
    $("#video_player").append video_column
    $("#video_player").append related_column
    $("#related_column").html "<div class='spinner'><div class='bounce1'></div></div>"
    $("#video_column").append video_box
    $("#video_column").append video_info
    $("#video_column").append comment_div
    $("#comment_box").append comment_actual

    clearTimeout(@player_timeout)

    init_url = Page.history_state["url"]
    console.log("Init url is: " + init_url)

    render_player = @render_player

    if init_url.indexOf("Model=") > -1
      real_url = init_url.split("Model=")[1]
      render_player real_url, "model"
      console.log("Rendering model view: " + real_url)
    else if init_url.indexOf("DesignView=") > -1
      real_url = init_url.split("DesignView=")[1]
      design_url = real_url.split("_")[0] + "_" + real_url.split("_")[1]
      file_uri_num = real_url.split("_")[2]
      file_uri_index = file_uri_num - 1
      Page.cmd "dbQuery", ["SELECT * FROM design_file LEFT JOIN json USING (json_id) WHERE design_uri='" +design_url+ "' ORDER BY date_added ASC LIMIT 50"], (res6) =>
        if res6.length > 0
          first_item = res6[file_uri_index].file_uri
          render_player first_item, "design", design_url
          console.log("Rendering design view: " + first_item)
        else
          $("#video_box").html ""
          $("#video_box").html "<p style='color: white; margin-left: 10px'>Error: This design is empty!</p><p style='color: white; margin-left: 10px'>If you're sure it's not, try:</p><p style='color: white; margin-left: 10px'>1. Clearing your cache</p><p style='color: white; margin-left: 10px'>2. Waiting for ZeroNet to fully download the site.</p>"

video_playing = new video_playing()
