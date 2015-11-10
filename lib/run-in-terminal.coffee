child_process = require("child_process")
path = require("path")
fs = require("fs")


interpolate = (s, o) ->

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


start_terminal = (start_path) =>

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

            cmd.push(read_option("terminal_exec_arg"))
            cmd.push(shebang)
            cmd.push(file_path)

        else if current_launcher

            cmd.push(read_option("terminal_exec_arg"))
            cmd.push(current_launcher)

    else if stats.isDirectory()

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


module.exports =

    activate: (state) ->

        commands = [
            [
                selectors.tree,
                "tree-start-terminal-here",
                "Start terminal here [tree]",
                () => @tree_start_terminal_here(false)
            ],
            [
                selectors.tree,
                "tree-start-terminal-here-and-run",
                "Start terminal here and run [tree]",
                () => @tree_start_terminal_here(true)
            ],
            [
                selectors.tabs,
                "tab-start-terminal-here",
                "Start terminal here [tab]",
                () => @tab_start_terminal_here(false)
            ],
            [
                selectors.tabs,
                "tab-start-terminal-here-and-run",
                "Start terminal here and run [tab]",
                () => @tab_start_terminal_here(true)
            ],
            [
                selectors.editor,
                "editor-start-terminal-here",
                "Start terminal here [editor]",
                () => @editor_start_terminal_here(false)
            ],
            [
                selectors.editor,
                "editor-start-terminal-here-and-run",
                "Start terminal here and run [editor]",
                () => @editor_start_terminal_here(true)
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

    tree_start_terminal_here: (run) ->

        li = document.querySelector(selectors.tree + " li.selected")
        is_dir = "directory" in li.classList
        start_path = li.querySelector("span.name").getAttribute("data-path")
        start_path = path.dirname(start_path) if not (is_dir or run)
        start_terminal(start_path)

    tab_start_terminal_here: (run) ->

        li = document.querySelector("li.tab.right-clicked")
        if li

            div = li.querySelector(".title")
            if div and div.hasAttribute("data-path")

                start_path = div.getAttribute("data-path")
                start_path = path.dirname(start_path) if not run
                start_terminal(start_path)

    editor_start_terminal_here: (run) ->

        start_path = atom.workspace.getActivePaneItem()?.buffer?.file?.path
        if start_path

            start_path = path.dirname(start_path) if not run
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

            title: "Terminal with arguments"
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
