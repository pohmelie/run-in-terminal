child_process = require("child_process")
path = require("path")
fs = require("fs")
os = require("os")


interpolate = (s, o) ->

    choose = (a, b) -> if typeof(o[b]) in ["string", "number"] then o[b] else a
    s.replace(/{([^{}]*)}/g, (a, b) -> choose(a, b))


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

    cmd = read_option("launchfile")
    parameters = {}
    if stats.isFile()

        file_path = start_path
        save_file_in_editor(file_path)
        parameters.file_path = file_path
        parameters.working_directory = path.dirname(file_path)
        if read_option("use_shebang")

            shebang = read_shebang(file_path)

        for pair in read_option("programs").split(",").map(strip)

            [end, program...] = pair.split(" ").map(strip)
            if file_path.indexOf(end, file_path.length - end.length) != -1

                current_program = program.join(" ")
                break

        if shebang

          parameters.launcher = shebang

        else if current_program

          parameters.launcher = current_program

        else

          atom.notifications.addError('Run-in-terminal: No program found in "List of programs" for current filetype or shebang not found')

        parameters.args = args

    else if stats.isDirectory()

      cmd = read_option("launchdir")
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

    cmd_line = interpolate(cmd, parameters)
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

        # Request args does not work if below line is uncommented? (OS X)
        # @line_edit_view.addEventListener("focusout", @save_and_hide)
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

switch require('os').platform()
  when 'darwin'
    defaultLaunchfile = """osascript -e 'tell application \"Terminal\"' -e 'activate' -e 'tell application \"Terminal\" to do script \"cd \\\"{working_directory}\\\" && {launcher} \\\"{file_path}\\\" \"' -e 'end tell'"""
    defaultLaunchdir = """osascript -e 'tell application \"Terminal\"' -e 'activate' -e 'tell application \"Terminal\" to do script \"cd \\\"{working_directory}\\\" \"' -e 'end tell'"""
  when 'win32'
    defaultLaunchfile = 'start /D {working_directory} C:\Windows\System32\cmd.exe /u /k cd "{working_directory}" & {launcher} "{file_path}"'
    defaultLaunchdir = 'start /D {working_directory} C:\Windows\System32\cmd.exe /u /k cd "{working_directory}"'
  else
    defaultLaunchfile = 'your-favorite-terminal --foo --bar "{working_directory}" && {launcher} "{file_path}"'
    defaultLaunchdir = 'your-favorite-terminal --foo --bar "{working_directory}"'

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
            order: 4
            default: true

        use_shebang:

            title: "Use shebang if available"
            type: "boolean"
            order: 6
            default: true

        maximum_shebang_length:

            title: "Maximum length of shebang to read"
            type: "integer"
            order: 7
            default: 256

        save_before_launch:

            title: "Save file before run terminal"
            type: "boolean"
            order: 2
            default: true

        launchfile:

            title: "Launch file in terminal command"
            description: "Enter the command to open and run a file in the terminal"
            type: "string"
            order: 1
            default: defaultLaunchfile

        launchdir:

            title: "Launch directory in terminal command"
            description: "Enter the command to open the terminal in the defined directory"
            type: "string"
            order: 3
            default: defaultLaunchdir

        programs:

            title: "List of programs by extension"
            description: "See the readme for more information"
            type: "string"
            order: 5
            default: ".py python, .java javac, .coffee coffee"

        context_menu:

            title: "Show commands in context menu"
            description: "Need restart (ctrl-alt-r)"
            type: "boolean"
            order: 8
            default: true
