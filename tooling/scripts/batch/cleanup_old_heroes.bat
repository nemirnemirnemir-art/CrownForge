@echo off
cd /d "%~dp0"
echo Cleaning up old hero assets and legacy scripts...

REM Old asset folders
rd /s /q "assets\heroes_from_website\slinger" 2>nul
rd /s /q "assets\heroes_from_website\Archer" 2>nul
rd /s /q "assets\heroes_from_website\peasant" 2>nul
rd /s /q "assets\heroes_from_website\Light_legionary" 2>nul
rd /s /q "assets\heroes_from_website\Light_Spearman" 2>nul
rd /s /q "assets\heroes_from_website\Mercenary" 2>nul

REM Legacy scripts
del "scripts\PeasantOnField_new.gd" 2>nul

echo Done! Verify deletions in Godot.
pause
