@echo off
setlocal
cd /d "%~dp0"
title Blueprint 3D Studio - Kitchen Cabinets - Rojo 7.7.0

echo ==============================================
echo Blueprint 3D Studio - Kitchen Cabinets
echo Starting pinned Rojo 7.7.0...
echo ==============================================
echo.

if not exist "default.project.json" (
  echo ERROR: default.project.json was not found.
  pause
  exit /b 1
)

rojo --version
if errorlevel 1 goto :fail

echo.
echo Rojo server listening on localhost:34872
echo Keep this window open while using Roblox Studio.
echo.
rojo serve default.project.json --port 34872
if errorlevel 1 goto :fail
exit /b 0

:fail
echo.
echo ERROR: Rojo could not start.
echo Run INSTALL.bat first, then try RUN.bat again.
pause
exit /b 1
