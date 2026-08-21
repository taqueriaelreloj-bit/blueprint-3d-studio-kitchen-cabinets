@echo off
setlocal
cd /d "%~dp0"
title Blueprint 3D Studio - Kitchen Cabinets - Install

echo ==============================================
echo Blueprint 3D Studio - Kitchen Cabinets
echo Installing Rojo 7.6.1 for this project...
echo ==============================================
echo.

where rokit >nul 2>nul
if errorlevel 1 (
  echo ERROR: Rokit was not found on this computer.
  pause
  exit /b 1
)

if not exist rokit.toml (
  echo Creating project manifest...
  rokit init
  if errorlevel 1 goto :fail
)

rokit add rojo-rbx/rojo@7.6.1
if errorlevel 1 goto :fail

rokit install
if errorlevel 1 goto :fail

echo.
echo ==============================================
echo INSTALL COMPLETE
echo Rojo 7.6.1 is ready.
echo Double-click RUN.bat to start Rojo.
echo ==============================================
pause
exit /b 0

:fail
echo.
echo ERROR: Installation failed. Read the message above.
pause
exit /b 1
