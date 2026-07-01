@echo off
cd /d "%~dp0"
echo Removing old Corpse.tscn...
del /f /q "scenes\effects\Corpse.tscn" 2>nul
del /f /q "scenes\effects\Corpse.tscn.remap" 2>nul
echo Done!
pause
