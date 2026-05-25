@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
set "PS1FILE=%~dp0gemini-login-manager-v3.ps1"
if not exist "%PS1FILE%" (
  echo Cannot find: "%PS1FILE%"
  echo Please put this CMD file and gemini-login-manager-v3.ps1 in the same folder.
  echo.
  pause
  exit /b 1
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1FILE%" -Mode menu
set "EC=%ERRORLEVEL%"
echo.
echo Gemini login manager exited. Exit code: %EC%
echo If it failed, copy the error text in this window and send it to ChatGPT.
echo.
pause
endlocal
