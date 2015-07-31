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


start_terminal = (terminal, exec_arg, command) =>

    file_path = atom.workspace.getActivePaneItem()?.buffer?.file?.path or ""
    file_dir = path.dirname(file_path)

    if !file_path

        proj_dirs = atom.project.getDirectories()
        if proj_dirs.length

            file_path = proj_dirs[0].path
            file_dir = file_path

    proj_dir = project_directory(file_dir)
    git_dir = git_directory(file_dir)

    use_exec_cwd = read_option("use_exec_working_directory")
    exec_cwd = if use_exec_cwd and file_path then file_dir else null

    if read_option("save_before_launch") and file_path

        atom.workspace.getActiveTextEditor()?.save()

    cmd = [terminal]
    if command and file_path

        cmd.push(exec_arg)
        cmd.push(command)

    parameters =

        working_directory: file_dir
        project_directory: proj_dir
        git_directory: git_dir
        file_path: file_path

    cmd_line = interpolate(cmd.join(" "), parameters)
    child_process.exec(cmd_line, cwd: exec_cwd, (error, stdout, stderr) ->

        if error

            console.error(
                """
                run-in-terminal error when child_process.exec ->
                cmd = #{cmd_line}
                error = #{error}
                stdout = #{stdout}
                stderr = #{stderr}
                """
            )

    )


read_option = (name) ->

    atom.config.get("run-in-terminal.#{name}")


build_command = (name) ->

    "run-in-terminal:#{name}"


add_command = (name, f) ->

    atom.commands.add("atom-workspace", build_command(name), f)


module.exports =

    activate: (state) ->

        add_command("start-terminal-here", () => @start_terminal_here())
        add_command("start-terminal-here-and-run", () => @start_terminal_here_and_run())
        if read_option("context_menu")

            atom.contextMenu.add({
                "atom-workspace": [
                    {
                        label: "Start terminal here"
                        command: build_command("start-terminal-here")
                    },
                    {
                        label: "Start terminal here and run"
                        command: build_command("start-terminal-here-and-run")
                    }
                ]
            })


    start_terminal_here: ->

        start_terminal(read_option("terminal"))


    start_terminal_here_and_run: ->

        file_path = atom.workspace.getActivePaneItem()?.buffer?.file?.path
        line = atom.workspace.getActiveTextEditor()?.lineTextForBufferRow(0)
        if read_option("use_shebang") and line?.indexOf("#!") == 0

            command = line.slice(2) + " #{file_path}"

        else if file_path?

            for pair in read_option("launchers").split(",").map(strip)

                [end, launcher...] = pair.split(" ").map(strip)
                if file_path.indexOf(end, file_path.length - end.length) != -1

                    command = launcher.join(" ")
                    break

        if command?

            start_terminal(
                read_option("terminal"),
                read_option("terminal_exec_arg"),
                command,
            )

        else

            @start_terminal_here()


    config:

        use_exec_working_directory:

            title: "Use exec cwd argument when launching terminal"
            type: "boolean"
            default: true

        use_shebang:

            title: "Use shebang if available"
            type: "boolean"
            default: true

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
