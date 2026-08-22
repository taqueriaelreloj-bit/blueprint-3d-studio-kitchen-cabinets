@echo off
setlocal
cd /d "%~dp0"
title Blueprint 3D Studio - Kitchen Cabinets - Install

echo ==============================================
echo Blueprint 3D Studio - Kitchen Cabinets
echo Installing pinned Rojo 7.7.0...
echo ==============================================
echo.

where rokit >nul 2>nul
if errorlevel 1 (
  echo ERROR: Rokit was not found on this computer.
  echo Install Rokit first, then run INSTALL.bat again.
  pause
  exit /b 1
)

if not exist "rokit.toml" (
  echo ERROR: rokit.toml is missing from this project.
  echo Pull the latest files from GitHub Desktop and try again.
  pause
  exit /b 1
)

if not exist "default.project.json" (
  echo ERROR: default.project.json is missing from this project.
  echo Pull the latest files from GitHub Desktop and try again.
  pause
  exit /b 1
)

echo Installing project tools...
rokit install
if errorlevel 1 goto :fail

echo.
echo Checking Rojo version...
rojo --version
if errorlevel 1 goto :fail

echo.
echo ==============================================
echo INSTALL COMPLETE
echo Expected Rojo version: 7.7.0
echo Next: double-click RUN.bat
echo ==============================================
pause
exit /b 0

:fail
echo.
echo ERROR: Installation failed. Read the message above.
pause
exit /b 1
