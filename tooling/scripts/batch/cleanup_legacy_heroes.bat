@echo off
cd /d "%~dp0"
echo Cleaning up legacy hero states...
del "scripts\hero_states\HeroSimpleAttackState.gd" 2>nul
del "scripts\hero_states\HeroMovingState.gd" 2>nul
echo Done.
pause
