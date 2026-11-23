@echo off
title DermaCare Nepal Backend Server
echo ========================================================
echo       DermaCare Nepal Dermatology Platform - Backend
echo ========================================================
cd /d "%~dp0Backend"

echo [1/3] Checking Python virtual environment...
if not exist ".venv\Scripts\python.exe" (
    echo Error: .venv not found in Backend directory!
    pause
    exit /b 1
)

echo [2/3] Applying database migrations and ensuring demo data...
.\.venv\Scripts\python.exe manage.py migrate --noinput
.\.venv\Scripts\python.exe manage.py seed_nepal_demo

echo [3/3] Starting Django API server at http://127.0.0.1:8000/ ...
echo.
echo ========================================================
echo   API Health:      http://127.0.0.1:8000/api/v1/health/
echo   Interactive Doc: http://127.0.0.1:8000/api/docs/
echo   Admin Panel:     http://127.0.0.1:8000/admin/
echo.
echo   Admin Login:     admin@dermacare.np / AdminPassword123!
echo   Patient Login:   sujana@dermacare.np / SujanaPassword123!
echo   Doctor Login:    dr.anjali@dermacare.np / DoctorPassword123!
echo ========================================================
echo.

.\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
pause
