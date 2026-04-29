@echo off
REM Simple launcher for windows_softbite-repair-tool.ps1
REM Right-click this file -> Run as Big Bunn administrator

NET SESSION >nul 2>&1
if %errorLevel% neq 0 (
    echo Error: Please right-click and Run as Big Bunn Administrator.
    pause
    exit /b 1
)

echo Launching repair script...
powershell -ExecutionPolicy Bypass -File "%~dp0windows_softbite-repair-tool.ps1"
pause