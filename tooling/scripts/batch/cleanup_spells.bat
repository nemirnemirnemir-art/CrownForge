@echo off
cd /d "%~dp0"
echo Cleaning up old TNT Barrel spell files...

del "C:\Godot\clickcer\resources\spells\configs\tnt_barrel.tres" 2>nul
del "C:\Godot\clickcer\scripts\effects\TNTBarrelEffect.gd" 2>nul
del "C:\Godot\clickcer\scenes\spells\effects\TNTBarrelEffect.tscn" 2>nul
del "C:\Godot\clickcer\assets\spells\tnt_barrel_icon.png" 2>nul

echo Done. Old files removed.
pause
