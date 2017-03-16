child_process = require("child_process")
path = require("path")
fs = require("fs")
os = require("os")

interpolate = (s, o) ->
    if os.platform() == "darwin"
      quote = (s) -> if read_option("autoquotation") then "\\\"#{s}\\\"" else s
    else
      quote = (s) -> if read_option("autoquotation") then "\"#{s}\"" else s
    choose = (a, b) -> if typeof(o[b]) in ["string", "number"] then o[b] else a
    s.replace(/{([^{}]*)}/g, (a, b) -> quote(choose(a, b)))

strip = (s) ->

    s.replace(/^\s+|\s+$/g, "")

project_directory = (file_dir) ->

    for dir in atom.project.getDirectories()

        if dir.contains(file_dir)

            return dir.path

    return file_dir


git_directory = (file_dir) ->

    path_info = path.parse(path.join(file_dir, "fictive"))
    while path_info.root != path_info.dir

        if fs.existsSync(path.join(path_info.dir, ".git"))

            return path_info.dir

        path_info = path.parse(path_info.dir)

    return file_dir


read_shebang = (file_path) =>

    fd = fs.openSync(file_path, "r")
    try

        maximum_length = read_option("maximum_shebang_length")
        buffer = new Buffer(maximum_length)
        fs.readSync(fd, buffer, 0, maximum_length, 0)
        [shebang, ...] = buffer.toString().split("\n")

    finally

        fs.closeSync(fd)

    if shebang.indexOf("#!") == 0

        return strip(shebang[2..])


start_terminal = (start_path, args) =>

    try

        stats = fs.statSync(start_path)

    catch err

        console.error(
            """
            run-in-terminal error: when statSync('#{start_path}')
            #{err}
            """
        )
        return

    cmd = [read_option("terminal")]
    if os.platform() == "darwin"
      cmd = ["""osascript -e 'tell application \"Terminal\"' -e 'activate' -e 'tell application \"Terminal\" to do script \""""]
      cmd_mac_end = """\"' -e 'end tell'"""
    parameters = {}
    if stats.isFile()

        file_path = start_path
        save_file_in_editor(file_path)
        parameters.file_path = file_path
        parameters.working_directory = path.dirname(file_path)
        if read_option("use_shebang")

            shebang = read_shebang(file_path)

        for pair in read_option("launchers").split(",").map(strip)

            [end, launcher...] = pair.split(" ").map(strip)
            if file_path.indexOf(end, file_path.length - end.length) != -1

                current_launcher = launcher.join(" ")
                break

        if shebang

            cmd.push(read_option("terminal_exec_arg")) if read_option("terminal_exec_arg") != "terminal-execution-argument"
            cmd.push(shebang)
            cmd.push("{file_path}")
            if os.platform() == "darwin"
              cmd.push(cmd_mac_end)

        else if current_launcher

            cmd.push(read_option("terminal_exec_arg")) if read_option("terminal_exec_arg") != "terminal-execution-argument"
            cmd.push(current_launcher)
            if os.platform() == "darwin"
              cmd.push(cmd_mac_end)

        cmd.push(args) if args

    else if stats.isDirectory()
        if os.platform() == "darwin"
          cmd = ["""osascript -e 'tell application \"Terminal\"' -e 'activate' -e 'tell application \"Terminal\" to do script "cd"""]
          cmd.push("{working_directory}")
          cmd.push(cmd_mac_end)
        parameters.working_directory = start_path

    else

        console.error(
            """
            run-in-terminal error: #{start_path} is not file or dir
            """
        )

    parameters.project_directory = project_directory(parameters.working_directory)
    parameters.git_directory = git_directory(parameters.working_directory)

    if read_option("use_exec_working_directory")

        exec_cwd = parameters.working_directory

    else

        exec_cwd = null

    cmd_line = interpolate(cmd.join(" "), parameters)
    child_process.exec(cmd_line, cwd: exec_cwd, (error, stdout, stderr) ->

        if error

            console.error(
                """
                run-in-terminal error: child_process.exec ->
                cmd = #{cmd_line}
                error = #{error}
                stdout = #{stdout}
                stderr = #{stderr}
                """
            )

    )


read_option = (name) ->

    atom.config.get("run-in-terminal.#{name}")


save_file_in_editor = (file_path) ->

    if read_option("save_before_launch")

        for editor in atom.workspace.getTextEditors()

            if file_path == editor.getPath() and editor.isModified()

                editor.save()
                break


selectors =

    tree: ".tree-view-resizer"
    tabs: ".tab-bar"
    editor: "atom-text-editor"


class ArgumentsRequester

    constructor: (label_text) ->

        @root = document.createElement("div")
        @root.classList.add("run-in-terminal-input-with-label")

        @message = document.createElement("div")
        @message.textContent = label_text
        @message.classList.add("message")
        @root.appendChild(@message)

        @line_edit_model = atom.workspace.buildTextEditor(mini: true)
        @line_edit_view = atom.views.getView(@line_edit_model)
        @root.appendChild(@line_edit_view)

        @panel = atom.workspace.addModalPanel({

            item: @root,
            visible: false,

        })

        @line_edit_view.addEventListener("focusout", @save_and_hide)
        @line_edit_view.addEventListener("keydown", @key_pressed)

        @attributes_memory = {}

    destroy: ->

        @panel.destroy()
        @root.remove()

    show: (@path) ->

        if not @panel.isVisible()

            @line_edit_model.setText(@attributes_memory[@path] or "")
            @panel.show()
            @line_edit_view.focus()
            @line_edit_model.selectAll()

    save_and_hide: =>

        @attributes_memory[@path] = @line_edit_model.getText()
        @panel.hide()

    key_pressed: (e) =>

        switch e.keyCode

            when 27

                @save_and_hide()

            when 13

                @save_and_hide()
                start_terminal(@path or "", @line_edit_model.getText())


module.exports =

    activate: (state) ->

        commands = [
            [
                selectors.tree,
                "tree-start-terminal-here",
                "Start terminal here [tree]",
                () => @tree_start_terminal_here(false, false)
            ],
            [
                selectors.tree,
                "tree-start-terminal-here-and-run",
                "Start terminal here and run [tree]",
                () => @tree_start_terminal_here(true, false)
            ],
            [
                selectors.tree,
                "tree-start-terminal-here-and-run-with-arguments",
                "Start terminal here and run with arguments [tree]",
                () => @tree_start_terminal_here(true, true)
            ],
            [
                selectors.tabs,
                "tab-start-terminal-here",
                "Start terminal here [tab]",
                () => @tab_start_terminal_here(false, false)
            ],
            [
                selectors.tabs,
                "tab-start-terminal-here-and-run",
                "Start terminal here and run [tab]",
                () => @tab_start_terminal_here(true, false)
            ],
            [
                selectors.tabs,
                "tab-start-terminal-here-and-run-with-arguments",
                "Start terminal here and run with arguments [tab]",
                () => @tab_start_terminal_here(true, true)
            ],
            [
                selectors.editor,
                "editor-start-terminal-here",
                "Start terminal here [editor]",
                () => @editor_start_terminal_here(false, false)
            ],
            [
                selectors.editor,
                "editor-start-terminal-here-and-run",
                "Start terminal here and run [editor]",
                () => @editor_start_terminal_here(true, false)
            ],
            [
                selectors.editor,
                "editor-start-terminal-here-and-run-with-arguments",
                "Start terminal here and run with arguments [editor]",
                () => @editor_start_terminal_here(true, true)
            ]
        ]

        menu = {}
        use_context_menu = read_option("context_menu")
        for [selector, name, desc, f] in commands

            command = "run-in-terminal:#{name}"
            atom.commands.add(selector, command, f)
            if use_context_menu

                menu[selector] ?= []
                menu[selector].push({
                    label: desc
                    command: command
                })

        atom.contextMenu.add(menu)

        @arguments_view = new ArgumentsRequester("Run arguments:")

    deactivate: ->

        @arguments_view.destroy()

    tree_start_terminal_here: (should_run, request_arguments) ->

        li = document.querySelector(selectors.tree + " li.selected")
        is_dir = "directory" in li.classList
        start_path = li.querySelector("span.name").getAttribute("data-path")
        start_path = path.dirname(start_path) if not (is_dir or should_run)
        if request_arguments

            @arguments_view.show(start_path)

        else

            start_terminal(start_path)

    tab_start_terminal_here: (should_run, request_arguments) ->

        li = document.querySelector("li.tab.right-clicked")
        if li

            div = li.querySelector(".title")
            if div and div.hasAttribute("data-path")

                start_path = div.getAttribute("data-path")
                start_path = path.dirname(start_path) if not should_run
                if request_arguments

                    @arguments_view.show(start_path)

                else

                    start_terminal(start_path)

    editor_start_terminal_here: (should_run, request_arguments) ->

        start_path = atom.workspace.getActivePaneItem()?.buffer?.file?.path
        if start_path

            start_path = path.dirname(start_path) if not should_run
            if request_arguments

                @arguments_view.show(start_path)

            else

                start_terminal(start_path)

    config:

        use_exec_working_directory:

            title: "Use exec cwd argument when launching terminal"
            type: "boolean"
            default: true

        use_shebang:

            title: "Use shebang if available"
            type: "boolean"
            default: true

        maximum_shebang_length:

            title: "Maximum length of shebang to read"
            type: "integer"
            default: 256

        save_before_launch:

            title: "Save file before run terminal"
            type: "boolean"
            default: true

        autoquotation:

            title: "Autoquote paths with double quotation mark"
            type: "boolean"
            default: true

        terminal:

            title: "Terminal with arguments (Leave blank for Mac OS X)"
            type: "string"
            default: "your-favorite-terminal --foo --bar"

        terminal_exec_arg:

            title: "Terminal execution argument"
            description: "This is the last flag for executing command directly in terminal (see the readme for more information)"
            type: "string"
            default: "terminal-execution-argument"

        launchers:

            title: "List of launchers by extension"
            description: "See the readme for more information"
            type: "string"
            default: "your-launchers"

        context_menu:

            title: "Show commands in context menu"
            description: "Need restart (ctrl-alt-r)"
            type: "boolean"
            default: true
