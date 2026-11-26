@echo off
rem Runs the whole GdUnit4 suite headless. Exits non-zero on any failure.
rem Needs GODOT_BIN set to a Godot 4 console binary.
cd /d "%~dp0"
if "%GODOT_BIN%"=="" (
    echo Set GODOT_BIN to the Godot 4 console binary.
    exit /b 1
)
rem One import pass so class_name scripts are registered before the runner starts.
"%GODOT_BIN%" --headless --path . --import >nul 2>&1
call addons\gdUnit4\runtest.cmd --headless --ignoreHeadlessMode -a res://test %*
exit /b %ERRORLEVEL%
