@echo off
setlocal
cd /d "%~dp0"
title Blueprint 3D Studio - Kitchen Cabinets - Rojo 7.6.1

echo ==============================================
echo Blueprint 3D Studio - Kitchen Cabinets
echo Starting pinned Rojo 7.6.1...
echo ==============================================
echo.

rojo --version
if errorlevel 1 goto :fail

echo.
rojo serve default.project.json
if errorlevel 1 goto :fail
exit /b 0

:fail
echo.
echo ERROR: Rojo could not start.
echo Run INSTALL.bat first, then try RUN.bat again.
pause
exit /b 1
