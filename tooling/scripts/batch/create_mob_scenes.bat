@echo off
echo === Creating Goblin Mob Scenes ===
echo.

cd /d "C:\Godot\clickcer"

REM Rename original Goblin to GoblinBandit
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\GoblinBandit.tscn"

REM Create copies for all other mobs
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\BlueSlime.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\GoblinCrossbowman.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\GoblinSwordsman.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\GoblinShaman.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\GoblinFireMage.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\GoblinLightningMage.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\GoblinLizard.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\GoblinGiant.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\WallBuster.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\GoblinBatRider.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\GoblinPig.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\CrabRider.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\StoneGolem.tscn"
copy "scenes\mobs\Goblin.tscn" "scenes\mobs\Sunfaced.tscn"

echo.
echo === Mob scenes copied! ===
echo Now you need to manually edit each .tscn in Godot to:
echo 1. Change root node name
echo 2. Set HP and damage values
echo 3. For ranged mobs: assign projectile_scene
echo 4. For Shaman: add MobHealState
echo 5. For Wall Buster: add AnimDead and MobRunIdleState
pause
