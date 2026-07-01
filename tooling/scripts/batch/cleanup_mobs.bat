@echo off
echo === Cleaning Up Redundant Files ===
cd /d "C:\Godot\clickcer"

REM Remove original Goblin.tscn as it's replaced by GoblinBandit.tscn
if exist "scenes\mobs\Goblin.tscn" del /f /q "scenes\mobs\Goblin.tscn"

REM Remove the erroneous creation script
if exist "create_mob_scenes.bat" del /f /q "create_mob_scenes.bat"

echo === Cleanup Complete ===
pause
