# run-in-terminal package

Atom package for executing your current file directly in terminal, or just open the terminal with a specified directory.

## Why?
Some packages can run terminal «here», some can run scripts not in terminal, but tabs/views/etc. I prefer terminal, so this one can run terminal «here» with any arguments and run scripts or any kind of shell «one-liners».

## Features
* start terminal here
* start terminal here and run some command
* start terminal here and run some command with extra arguments
* string interpolation with arguments
* understanding shebang (utf-8 only)
* launchers — file extension based launcher chooser
* separate context menus for tabs, tree and editor

## What's new ([changelog](https://github.com/pohmelie/run-in-terminal/blob/master/CHANGELOG.md))
#### 1.0.0 - Improved OS X support
* feature: OS X users can now run any file directly in the terminal, based on configurable Applescript command.
* feature: default settings added for OS X and Windows users.
* fix: disappearing arguments input field.
* note: not backward compatible with previous versions, please update your settings. You should remove all `run-in-terminal` settings from `config.cson` file.
* note: autoquotation removed from the settings menu, as quotes can now be directly edited in the commands.

## Options

| Field                          |   Type  |                Description                               |        Default value             |                 Example value                   |
|:------------------------------:|:-------:|:--------------------------------------------------------:|:--------------------------------:|:-----------------------------------------------:|
| Launch file in terminal command| string  | command to start the terminal and run a program based on filetype or shebang       | operating system dependent       | konsole --noclose --workdir "{working_directory}" -e {launcher} "{file_dir}" |
| Save file before run terminal  | boolean | Saves the open file before the terminal is started       | true                             | -                                               |
| Launch directory in terminal command   | string  | command to start the terminal and open a directory   | operating system dependent   | konsole --noclose --workdir "{working_directory}" |
| List of programs by extension  | string  | comma separated pairs: extension-program                 | your-programs                    | .py python3, .lua lua                           |
| Use exec cwd                   | boolean | child_process.exec cwd parameter                         | true                             | -                                               |
| Use shebang                    | boolean | use shebang if available                                 | true                             | -                                               |


## Interpolation parameters
| Parameter           | Description                       |
|:-------------------:|:---------------------------------:|
| {file_path}         | path to current file              |
| {launcher}          | selected program from list or shebang|
| {args}              | additional (optional) arguments   |
| {working_directory} | path to current working directory |
| {project_directory} | path to project's root directory  |
| {git_directory}     | path to nearest git root directory|


## How it works
In deep, run-in-terminal uses the node.js child_process.exec function, so exec have cwd (current working directory) argument. But it doesn't work for all terminals. Some of them need the launch «working directory» argument. That's why run-in-terminal have string interpolation of arguments. What does string interpolation mean? run-in-terminal builds full command at first step and replace predefined substrings with parameters at second. For values from «example value» column above we can have such scenario:

Current opened file in Atom: /path/to/somedir/foo.py, which has #!/usr/bin/python3 as shebang.

    start-terminal-here-and-run -> konsole --noclose --workdir "{working_directory}" -e /usr/bin/python3 "{file_path}"

this will be interpolated to:

    start-terminal-here-and-run -> konsole --noclose --workdir "/path/to/somedir" -e /usr/bin/python3 "/path/to/somedir/foo.py"

If run-in-terminal can't determine launcher or file_path (file not saved and has no name) it will do start-terminal-here.

## Thanks to:
[bobrocke](https://github.com/bobrocke), [clintwood](https://github.com/clintwood), [LeoVerto](https://github.com/LeoVerto), [marales](https://github.com/marales), [djengineerllc](https://github.com/djengineerllc), [LevPasha](https://github.com/LevPasha), [Kee-Wang](https://github.com/Kee-Wang), [jnelissen](https://github.com/jnelissen).
