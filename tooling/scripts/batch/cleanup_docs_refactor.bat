@echo off
cd /d "%~dp0"

echo ===============================================
echo Documentation cleanup: candidates for deletion
echo ===============================================
echo.
echo SAFETY:
echo - By default this script DOES NOT delete anything.
echo - To actually delete, set DO_DELETE=1 below.
echo.

set DO_DELETE=1

set TARGET_1=docs\goblin_implement.md
set TARGET_2=docs\03_resources_and_economy.md
set TARGET_3=docs\04_buildings_catalog.md
set TARGET_4=docs\05_units_catalog.md
set TARGET_5=docs\BUILDING_SYSTEM_TEST.md
set TARGET_6=docs\notebook.md

echo Candidates:
echo  1) %TARGET_1%
echo  2) %TARGET_2%
echo  3) %TARGET_3%
echo  4) %TARGET_4%
echo  5) %TARGET_5%
echo  6) %TARGET_6%
echo.
echo Notes:
echo - Docs 1-4 = внешние справки (смотри the_king_is_watching_gdd/*), внутри проекта больше не нужны.
echo - Docs 5-6 = перенесены в wiki/runbooks (отмечены DEPRECATED).
echo.

if "%DO_DELETE%"=="1" (
  echo Deleting files...
  del "%TARGET_1%" 2>nul
  del "%TARGET_2%" 2>nul
  del "%TARGET_3%" 2>nul
  del "%TARGET_4%" 2>nul
  del "%TARGET_5%" 2>nul
  del "%TARGET_6%" 2>nul
  echo.
  echo Done.
) else (
  echo DRY RUN: no files were deleted.
  echo If you agree, edit this bat and set DO_DELETE=1, then run it again.
)

echo.
echo Press any key to exit.
pause >nul
