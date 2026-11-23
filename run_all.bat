@echo off
title DermaCare Full Stack Launcher
echo ========================================================
echo       Starting DermaCare Full Stack System
echo ========================================================
echo Launching Backend in a separate window...
start "DermaCare Backend" cmd /k "%~dp0run_backend.bat"

timeout /t 3 /nobreak >nul

echo Launching Frontend in a separate window...
start "DermaCare Frontend" cmd /k "%~dp0run_frontend.bat"

echo.
echo Both services have been launched!
echo Keep the backend console window open while using the app.
