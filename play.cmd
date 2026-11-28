@echo off
rem Plays the game from this folder: start menu first.
rem   play.cmd
rem Runs Godot's import pass first. Without it, a folder whose .godot cache is
rem older than the newest class_name script fails to compile the start menu,
rem and the window opens on its title with nothing to choose.
rem Needs GODOT_BIN set to a Godot 4.7 binary (the _console.exe build shows errors).
setlocal
cd /d "%~dp0"
if not defined GODOT_BIN goto no_godot
if not exist "%GODOT_BIN%" goto no_godot
echo Importing...
"%GODOT_BIN%" --headless --path . --import >nul 2>&1
"%GODOT_BIN%" --path . %*
exit /b %ERRORLEVEL%

:no_godot
echo play.cmd needs GODOT_BIN set to a Godot 4.7 binary, for example: 1>&2
echo   set GODOT_BIN=C:\path\to\Godot_v4.7.2-stable_win64_console.exe 1>&2
exit /b 1
