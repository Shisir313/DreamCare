@echo off
title DermaCare Flutter Frontend App
echo ========================================================
echo       DermaCare Nepal Dermatology Platform - Frontend
echo ========================================================
cd /d "%~dp0Frontend"

echo [1/2] Fetching Flutter dependencies...
call flutter pub get

echo.
echo [2/2] Launching Flutter app...
echo Choose target device:
echo   [1] Windows Desktop (Default)
echo   [2] Chrome Web Browser
echo   [3] Android / Auto-detect
echo.
set /p choice="Enter choice (1, 2, or 3) [Default 1]: "

if "%choice%"=="2" (
    call flutter run -d chrome
) else if "%choice%"=="3" (
    call flutter run
) else (
    call flutter run -d windows
)

pause
