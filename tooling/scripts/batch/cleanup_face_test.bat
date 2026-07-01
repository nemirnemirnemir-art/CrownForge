@echo off
cd /d "%~dp0"

echo Removing legacy face_test assets...

rmdir /s /q "assets\face_test" 2>nul

echo Done! Press any key to exit.
pause >nul
