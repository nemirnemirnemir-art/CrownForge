@echo off
echo Renaming resource icons to new KoW system...

REM Rename existing files
if exist water_-1.png ren water_-1.png water.png
if exist water_-1.png.import ren water_-1.png.import water.png.import

if exist money_0.png ren money_0.png gold.png
if exist money_0.png.import ren money_0.png.import gold.png.import

if exist wood_1.png ren wood_1.png wood.png
if exist wood_1.png.import ren wood_1.png.import wood.png.import

if exist clay_3.png ren clay_3.png clay.png
if exist clay_3.png.import ren clay_3.png.import clay.png.import

if exist iron_ore_5.png ren iron_ore_5.png iron_ore.png
if exist iron_ore_5.png.import ren iron_ore_5.png.import iron_ore.png.import

if exist iron_ingot_6.png ren iron_ingot_6.png steel.png
if exist iron_ingot_6.png.import ren iron_ingot_6.png.import steel.png.import

if exist wheat_7.png ren wheat_7.png wheat.png
if exist wheat_7.png.import ren wheat_7.png.import wheat.png.import

if exist flour_8.png ren flour_8.png flour.png
if exist flour_8.png.import ren flour_8.png.import flour.png.import

if exist meat_9.png ren meat_9.png meat.png
if exist meat_9.png.import ren meat_9.png.import meat.png.import

REM Delete old unused resources
echo Deleting unused resource files...
if exist stone_2.png del stone_2.png
if exist stone_2.png.import del stone_2.png.import

if exist gold_4.png del gold_4.png
if exist gold_4.png.import del gold_4.png.import

if exist gold_ore_4.png del gold_ore_4.png
if exist gold_ore_4.png.import del gold_ore_4.png.import

if exist mana_8.png del mana_8.png
if exist mana_8.png.import del mana_8.png.import

if exist vegetables_10.png del vegetables_10.png
if exist vegetables_10.png.import del vegetables_10.png.import

if exist food_11.png del food_11.png
if exist food_11.png.import del food_11.png.import

if exist powder_12.png del powder_12.png
if exist powder_12.png.import del powder_12.png.import

echo Done! You still need to create these new icons:
echo - grapes.png
echo - wine.png
echo - oil.png
echo - crystal.png
exit /b 0
