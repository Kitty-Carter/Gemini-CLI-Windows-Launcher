@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
set "PS1FILE=%~dp0gemini-login-manager-v3.ps1"
if not exist "%PS1FILE%" (
  echo Cannot find: "%PS1FILE%"
  pause
  exit /b 1
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1FILE%" -Mode account
set "EC=%ERRORLEVEL%"
echo.
echo Account-login launcher exited. Exit code: %EC%
echo If Gemini shows "Press R to restart", press R in the Gemini window.
echo.
pause
endlocal
