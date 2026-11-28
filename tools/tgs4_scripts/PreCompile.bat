@echo off
setlocal
set "TG_BOOTSTRAP_CACHE=%~dp0"
cd /D "%~1" || exit /b 1
set "CBT_BUILD_MODE=TGS"
rem Cobalt runs as a separately configured service and has no build dependency.
call tools\build\build.bat
exit /b %errorlevel%
