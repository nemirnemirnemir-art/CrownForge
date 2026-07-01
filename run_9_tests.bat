@echo off
setlocal enabledelayedexpansion

cd /d C:\Godot\clickcer

echo.
echo ===================================
echo   GODOT 4.3 HEADLESS TEST RUNNER
echo ===================================
echo.

set "GODOT=C:\Godot\Godot_v4.3-stable_win64.exe"
set "PROJECT_PATH=C:\Godot\clickcer"

set "tests[1]=test_gamescene_bootstrap.gd"
set "tests[2]=test_gamescene_encounter_flow.gd"
set "tests[3]=test_gamescene_wave_flow.gd"
set "tests[4]=test_gamescene_building_drag.gd"
set "tests[5]=test_gamescenewaves_safe_singleton_lookup.gd"
set "tests[6]=test_gamescenewaves_spawn_service.gd"
set "tests[7]=test_gamescene_prophecy_open_variety.gd"
set "tests[8]=test_gamescene_building_move_state.gd"
set "tests[9]=test_mine_visual_and_runtime_guards.gd"

for /l %%i in (1,1,9) do (
    set "test=!tests[%%i]!"
    echo.
    echo [Test %%i/9] Running: !test!
    echo ----------------------------------------
    "!GODOT!" --headless --path "!PROJECT_PATH!" -s scripts/dev/tests/!test!
    set "exit_code=!errorlevel!"
    if !exit_code! equ 0 (
        echo [Test %%i/9] PASS
    ) else (
        echo [Test %%i/9] FAIL (exit code: !exit_code!)
    )
    echo.
)

echo.
echo ===================================
echo   ALL TESTS COMPLETED
echo ===================================
pause
