@echo off
rem Runs the GdUnit4 suite headless: every suite, or only the ones named.
rem   test.cmd                      every suite under test\
rem   test.cmd heat scan_test       only test\heat_test.gd and test\scan_test.gd
rem   test.cmd --verbose [suite...] GdUnit's full coloured output, as it comes
rem Hands everything to test.sh, run by the bash that comes with Git for Windows,
rem so both wrappers print the same lines and exit with the same code.
rem Needs GODOT_BIN set to a Godot 4 console binary.
setlocal
cd /d "%~dp0"
set "GIT_BASH="
for /f "delims=" %%i in ('git --exec-path 2^>nul') do set "GIT_BASH=%%i\..\..\..\bin\bash.exe"
if not defined GIT_BASH goto no_bash
if not exist "%GIT_BASH%" goto no_bash
"%GIT_BASH%" ./test.sh %*
exit /b %ERRORLEVEL%

:no_bash
echo test.cmd needs Git for Windows: its bash runs test.sh. 1>&2
exit /b 1
