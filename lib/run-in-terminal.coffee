child_process = require('child_process')
path = require('path')


interpolate = (s, o) ->

    s.replace(
        /{([^{}]*)}/g,
        (a, b) -> if typeof(o[b]) in ["string", "number"] then o[b] else a
    )


start_terminal = (terminal, args, exec_arg, command) =>

    use_exec_cwd = read_option("use_exec_working_directory")
    file_path = atom.workspace.getActivePaneItem().buffer?.file?.path or ""
    file_dir = path.dirname(file_path)
    exec_cwd = if use_exec_cwd and file_path then file_dir else null

    cmd = [terminal, args]
    if command

        cmd.push(exec_arg)
        cmd.push(command)

    parameters =

        working_directory: file_dir
        file_path: file_path

    cmd_line = interpolate(cmd.join(" "), parameters)
    console.log("running terminal", cmd_line)
    child_process.exec(cmd_line, cwd: exec_cwd)


read_option = (name) ->

    atom.config.get("run-in-terminal.#{name}")


add_command = (name, f) ->

    atom.commands.add("atom-workspace", "run-in-terminal:#{name}", f)


module.exports =

    activate: (state) ->

        add_command("start-terminal-here", @start_terminal_here)
        add_command("start-terminal-here-and-run", @start_terminal_here_and_run)


    start_terminal_here: ->

        start_terminal(read_option("terminal"), read_option("terminal_args"))


    start_terminal_here_and_run: ->

        if read_option("use_shebang")

            line = atom.workspace.getActiveTextEditor()?.lineTextForBufferRow(0)
            if line.indexOf("#!") == 0

                command = line.slice(2)


    config:

        use_exec_working_directory:

            title: "Use exec cwd argument when launching terminal"
            type: "boolean"
            default: true

        use_shebang:

            title: "Use shebang if available"
            type: "boolean"
            default: true

        terminal:

            title: "Terminal"
            type: "string"
            default: "your-favorite-terminal"

        terminal_args:

            title: "Terminal arguments"
            description: "Interpolation will be applied (see readme for more information)"
            type: "string"
            default: "terminal-arguments"

        terminal_exec_arg:

            title: "Terminal execution argument"
            description: "This is the last flag for executing command directly in terminal (see readme for more information)"
            type: "string"
            default: "terminal-execution-argument"

        launchers:

            title: "List of launchers by extension"
            description: "Format: extension launcher, … (see readme for more information)"
            type: "string"
            default: ".py python3, .lua lua"
