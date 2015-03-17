child_process = require('child_process')
path = require('path')
os = require('os')


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
    console.log(cmd_line)
    child_process.exec(cmd_line, cwd: exec_cwd)


read_option = (name) ->

    atom.config.get("run-in-terminal.#{name}")


module.exports =

    activate: (state) ->

        atom.commands.add("atom-workspace", "run-in-terminal:start-terminal-here", @start_terminal_here)

    start_terminal_here: ->

        start_terminal(read_option("terminal"), read_option("terminal_arguments"))

    config:

        terminal:

            title: "Terminal"
            type: "string"
            default: "your-favorite-terminal"

        terminal_arguments:

            title: "Terminal arguments"
            description: "Interpolation will be applied."
            type: "string"
            default: "terminal-arguments"
