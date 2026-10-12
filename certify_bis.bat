@echo off
python certify_bis.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Certification failed!
    exit /b 1
)
