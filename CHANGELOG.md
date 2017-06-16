## 1.0.1 - Add atom v1.19 support
* fix [#19](https://github.com/pohmelie/run-in-terminal/issues/19)

Thanks to [maxbrunsfeld](https://github.com/maxbrunsfeld)

## 1.0.0 - Improved OS X support
* feature: OS X users can now run any file directly in the terminal, based on configurable Applescript command.
* feature: default settings added for OS X and Windows users.
* fix: disappearing arguments input field.
* note: not backward compatible with previous versions, please update your settings. You should remove all `run-in-terminal` settings from `config.cson` file.
* note: autoquotation removed from the settings menu, as quotes can now be directly edited in the commands.

Thanks to [jnelissen](https://github.com/jnelissen).

## 0.6.0 - run with arguments
* feature: start terminal and run with extra arguments

Thanks to [LevPasha](https://github.com/LevPasha)

## 0.5.0 - separate areas (probably [djengineerllc](https://github.com/pohmelie/run-in-terminal/issues/12) request)
* feature: start terminal (and run) for any directory/file in tree/tab by context menu

## 0.4.3 - bugfix
* fixed: start terminal on unsaved/unnamed file crashes when trying to save.

Thanks to [marales](https://github.com/marales)

## 0.4.2 - bugfix
* fixed: terminal starts on «strange» folder, when there is no open file tab(s) (on windows).

Thanks to [clintwood](https://github.com/clintwood)

## 0.4.1 - readme typo

## 0.4.0 - autoquotation
* option for autoquotation (adding double quotation mark to paths)

Thanks to [LeoVerto](https://github.com/LeoVerto)

## 0.3.0 - New interpolation parameters and bugfix
* new interpolation parameters
* "exec_cwd" bugfix

Thanks to [clintwood](https://github.com/clintwood)

## 0.2.2 - Readme improvement
* some help for os x users.

## 0.2.1 - Context menu ([bobrocke](https://github.com/pohmelie/run-in-terminal/issues/2) request)
* context menu commands for «start terminal here» and «start terminal
here and run»
* option for toggle context menu items

## 0.2.0 - Options change
* «terminal arguments» option deprecated since now, put your terminal arguments and interpolation variables into «terminal» option.

## 0.1.2 - Bugfixes
* start terminal when there is no tabs/files opened

## 0.1.1 - Bugfixes
* launchers dispatched by extension bug fixed

## 0.1.0 - First release
