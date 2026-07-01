@echo off
cd /d "%~dp0"

echo Cleaning up orphaned .import files...

del "assets\mana_background.png.import" 2>nul

echo Removing obsolete kitchen specs...

rmdir /s /q "specs\026-kitchen-system" 2>nul

echo Removing obsolete farm specs...

rmdir /s /q "specs\024-rules-number-15" 2>nul

echo Removing processed upgrade screenshots...

rmdir /s /q "assets\delete after 502" 2>nul

echo Removing obsolete wiki pages (farm variants)...

del "assets\docs\wiki_pages\Animal_Farm.md" 2>nul
del "assets\docs\wiki_pages\Blacksmith's_Farm.md" 2>nul
del "assets\docs\wiki_pages\Goldsmith's_Farm.md" 2>nul
del "assets\docs\wiki_pages\Lumberjack's_Farm.md" 2>nul
del "assets\docs\wiki_pages\Potter's_Farm.md" 2>nul

echo Removing obsolete farm building assets...

del "assets\buildings\farm.png" 2>nul
del "assets\buildings\farm.png.import" 2>nul
del "assets\buildings\Vegitables_farm.png" 2>nul
del "assets\buildings\Vegitables_farm.png.import" 2>nul

echo Done! Press any key to exit.
pause >nul
