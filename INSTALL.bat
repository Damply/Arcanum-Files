@echo off
setlocal
title ArcanumLand Friends Toolkit
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-ArcanumLand-Friends.ps1"
if errorlevel 1 (
  echo.
  echo Installation failed. Read the error above; no backup files were deleted.
)
echo.
pause
