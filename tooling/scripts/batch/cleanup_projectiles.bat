@echo off
cd /d "%~dp0"
echo Cleaning up duplicate projectile files...

REM Delete duplicate projectile scenes (keep only Projectile.tscn)
del /f /q "scenes\HeroProjectile.tscn" 2>nul
del /f /q "scenes\projectiles\ProjectileCrossbowman.tscn" 2>nul
del /f /q "scenes\projectiles\ProjectileFireMage.tscn" 2>nul
del /f /q "scenes\projectiles\ProjectileLightningMage.tscn" 2>nul
del /f /q "scenes\projectiles\ProjectileShaman.tscn" 2>nul

REM Delete duplicate projectile scripts (keep only Projectile.gd)
del /f /q "scripts\HeroProjectile.gd" 2>nul

echo Cleanup complete!
echo Please verify in Godot that all ranged units use scenes/projectiles/Projectile.tscn
pause
