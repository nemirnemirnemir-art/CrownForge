@echo off
cd /d "%~dp0"

echo === Deleting Legacy StageSlider Files ===

del /q "scenes\StageSlider.tscn" 2>nul
echo Deleted: scenes\StageSlider.tscn

del /q "scripts\StageSlider.gd" 2>nul
echo Deleted: scripts\StageSlider.gd

echo.
echo === Cleanup Complete ===
pause
