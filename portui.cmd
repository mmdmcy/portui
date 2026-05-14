@echo off
setlocal

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0portui.ps1" %*
exit /b %ERRORLEVEL%

