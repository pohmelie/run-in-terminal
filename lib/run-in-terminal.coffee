child_process = require('child_process')
path = require('path')


interpolate = (s, o) ->

    s.replace(
        /{([^{}]*)}/g,
        (a, b) -> if typeof(o[b]) in ["string", "number"] then o[b] else a
    )


strip = (s) ->

    s.replace(/^\s+|\s+$/g, "")


start_terminal = (terminal, exec_arg, command) =>

    file_path = atom.workspace.getActivePaneItem()?.buffer?.file?.path or ""
    file_dir = path.dirname(file_path)
    exec_cwd = if use_exec_cwd and file_path then file_dir else null

    use_exec_cwd = read_option("use_exec_working_directory")
    if read_option("save_before_launch") and file_path

        atom.workspace.getActiveTextEditor()?.save()

    cmd = [terminal]
    if command and file_path

        cmd.push(exec_arg)
        cmd.push(command)

    parameters =

        working_directory: file_dir
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


add_command = (name, f) ->

    atom.commands.add("atom-workspace", "run-in-terminal:#{name}", f)


module.exports =

    activate: (state) ->

        add_command("start-terminal-here", () => @start_terminal_here())
        add_command("start-terminal-here-and-run", () => @start_terminal_here_and_run())


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
