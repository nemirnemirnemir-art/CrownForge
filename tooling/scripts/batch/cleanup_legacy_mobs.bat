@echo off
echo === Cleanup Legacy Mobs ===
echo.

REM Change to project directory first
cd /d "C:\Godot\clickcer"
echo Working in: %CD%
echo.

REM Delete legacy mob scenes
del /F /Q "C:\Godot\clickcer\scenes\mobs\AxeMob.tscn" 2>nul
del /F /Q "C:\Godot\clickcer\scenes\mobs\Bat.tscn" 2>nul
del /F /Q "C:\Godot\clickcer\scenes\mobs\BoneMob.tscn" 2>nul
del /F /Q "C:\Godot\clickcer\scenes\mobs\DeliveryMob.tscn" 2>nul
del /F /Q "C:\Godot\clickcer\scenes\mobs\GreenSlime.tscn" 2>nul
del /F /Q "C:\Godot\clickcer\scenes\mobs\KingMob.tscn" 2>nul
del /F /Q "C:\Godot\clickcer\scenes\mobs\Lizard.tscn" 2>nul
del /F /Q "C:\Godot\clickcer\scenes\mobs\MagMob.tscn" 2>nul
del /F /Q "C:\Godot\clickcer\scenes\mobs\MiniDrake.tscn" 2>nul
del /F /Q "C:\Godot\clickcer\scenes\mobs\Mushroom.tscn" 2>nul
del /F /Q "C:\Godot\clickcer\scenes\mobs\SwordmanMob.tscn" 2>nul
del /F /Q "C:\Godot\clickcer\scenes\mobs\WoodenBoy.tscn" 2>nul
echo Mob scenes deleted.

REM Delete legacy mob states
del /F /Q "C:\Godot\clickcer\scripts\mob_states\MobBatAttackState.gd" 2>nul
del /F /Q "C:\Godot\clickcer\scripts\mob_states\MobIdleState.gd" 2>nul
del /F /Q "C:\Godot\clickcer\scripts\mob_states\MobWanderingAroundPortalState.gd" 2>nul
echo Mob states deleted.

echo.
echo === Checking Results ===
echo Remaining files in scenes\mobs:
dir "C:\Godot\clickcer\scenes\mobs" /B

echo.
echo === Cleanup Complete! ===
pause
