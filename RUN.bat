@echo off
setlocal
cd /d "%~dp0"
title Blueprint 3D Studio - Kitchen Cabinets - Rojo

echo ==============================================
echo Blueprint 3D Studio - Kitchen Cabinets
echo Starting Rojo...
echo ==============================================
echo.

rojo serve
if errorlevel 1 (
  echo.
  echo ERROR: Rojo could not start.
  echo Run INSTALL.bat first, then try RUN.bat again.
  pause
)
