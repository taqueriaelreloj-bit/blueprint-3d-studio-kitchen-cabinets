@echo off
setlocal
cd /d "%~dp0"
title Blueprint 3D Studio - Kitchen Cabinets - Install

echo ==============================================
echo Blueprint 3D Studio - Kitchen Cabinets
echo Installing Rojo for this project...
echo ==============================================
echo.

where rokit >nul 2>nul
if errorlevel 1 (
  echo ERROR: Rokit was not found on this computer.
  echo Install Rokit first, then run INSTALL.bat again.
  pause
  exit /b 1
)

rokit add rojo-rbx/rojo
if errorlevel 1 goto :fail

rokit install
if errorlevel 1 goto :fail

echo.
echo Rojo installed successfully.
echo You can now double-click RUN.bat.
pause
exit /b 0

:fail
echo.
echo ERROR: Installation failed. Read the message above.
pause
exit /b 1
