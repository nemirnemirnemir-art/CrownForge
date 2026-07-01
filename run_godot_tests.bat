@echo off
setlocal enabledelayedexpansion

set GODOT_EXE=C:\Godot\Godot_v4.3-stable_win64.exe
set PROJECT_PATH=C:\Godot\clickcer
set TESTS_DIR=%PROJECT_PATH%\scripts\dev\tests

echo ============================================
echo Running Godot Headless Tests
echo ============================================

set /a test_count=0
set /a pass_count=0
set /a fail_count=0

REM Test 1
set /a test_count+=1
echo.
echo [Test 1/9] Running test_gamescene_bootstrap.gd
"%GODOT_EXE%" --headless --path "%PROJECT_PATH%" -s scripts/dev/tests/test_gamescene_bootstrap.gd
if %errorlevel% equ 0 (
    echo [PASSED] test_gamescene_bootstrap.gd
    set /a pass_count+=1
) else (
    echo [FAILED] test_gamescene_bootstrap.gd (Exit code: %errorlevel%)
    set /a fail_count+=1
)

REM Test 2
set /a test_count+=1
echo.
echo [Test 2/9] Running test_gamescene_encounter_flow.gd
"%GODOT_EXE%" --headless --path "%PROJECT_PATH%" -s scripts/dev/tests/test_gamescene_encounter_flow.gd
if %errorlevel% equ 0 (
    echo [PASSED] test_gamescene_encounter_flow.gd
    set /a pass_count+=1
) else (
    echo [FAILED] test_gamescene_encounter_flow.gd (Exit code: %errorlevel%)
    set /a fail_count+=1
)

REM Test 3
set /a test_count+=1
echo.
echo [Test 3/9] Running test_gamescene_wave_flow.gd
"%GODOT_EXE%" --headless --path "%PROJECT_PATH%" -s scripts/dev/tests/test_gamescene_wave_flow.gd
if %errorlevel% equ 0 (
    echo [PASSED] test_gamescene_wave_flow.gd
    set /a pass_count+=1
) else (
    echo [FAILED] test_gamescene_wave_flow.gd (Exit code: %errorlevel%)
    set /a fail_count+=1
)

REM Test 4
set /a test_count+=1
echo.
echo [Test 4/9] Running test_gamescene_building_drag.gd
"%GODOT_EXE%" --headless --path "%PROJECT_PATH%" -s scripts/dev/tests/test_gamescene_building_drag.gd
if %errorlevel% equ 0 (
    echo [PASSED] test_gamescene_building_drag.gd
    set /a pass_count+=1
) else (
    echo [FAILED] test_gamescene_building_drag.gd (Exit code: %errorlevel%)
    set /a fail_count+=1
)

REM Test 5
set /a test_count+=1
echo.
echo [Test 5/9] Running test_gamescenewaves_safe_singleton_lookup.gd
"%GODOT_EXE%" --headless --path "%PROJECT_PATH%" -s scripts/dev/tests/test_gamescenewaves_safe_singleton_lookup.gd
if %errorlevel% equ 0 (
    echo [PASSED] test_gamescenewaves_safe_singleton_lookup.gd
    set /a pass_count+=1
) else (
    echo [FAILED] test_gamescenewaves_safe_singleton_lookup.gd (Exit code: %errorlevel%)
    set /a fail_count+=1
)

REM Test 6
set /a test_count+=1
echo.
echo [Test 6/9] Running test_gamescenewaves_spawn_service.gd
"%GODOT_EXE%" --headless --path "%PROJECT_PATH%" -s scripts/dev/tests/test_gamescenewaves_spawn_service.gd
if %errorlevel% equ 0 (
    echo [PASSED] test_gamescenewaves_spawn_service.gd
    set /a pass_count+=1
) else (
    echo [FAILED] test_gamescenewaves_spawn_service.gd (Exit code: %errorlevel%)
    set /a fail_count+=1
)

REM Test 7
set /a test_count+=1
echo.
echo [Test 7/9] Running test_gamescene_prophecy_open_variety.gd
"%GODOT_EXE%" --headless --path "%PROJECT_PATH%" -s scripts/dev/tests/test_gamescene_prophecy_open_variety.gd
if %errorlevel% equ 0 (
    echo [PASSED] test_gamescene_prophecy_open_variety.gd
    set /a pass_count+=1
) else (
    echo [FAILED] test_gamescene_prophecy_open_variety.gd (Exit code: %errorlevel%)
    set /a fail_count+=1
)

REM Test 8
set /a test_count+=1
echo.
echo [Test 8/9] Running test_gamescene_building_move_state.gd
"%GODOT_EXE%" --headless --path "%PROJECT_PATH%" -s scripts/dev/tests/test_gamescene_building_move_state.gd
if %errorlevel% equ 0 (
    echo [PASSED] test_gamescene_building_move_state.gd
    set /a pass_count+=1
) else (
    echo [FAILED] test_gamescene_building_move_state.gd (Exit code: %errorlevel%)
    set /a fail_count+=1
)

REM Test 9
set /a test_count+=1
echo.
echo [Test 9/9] Running test_mine_visual_and_runtime_guards.gd
"%GODOT_EXE%" --headless --path "%PROJECT_PATH%" -s scripts/dev/tests/test_mine_visual_and_runtime_guards.gd
if %errorlevel% equ 0 (
    echo [PASSED] test_mine_visual_and_runtime_guards.gd
    set /a pass_count+=1
) else (
    echo [FAILED] test_mine_visual_and_runtime_guards.gd (Exit code: %errorlevel%)
    set /a fail_count+=1
)

echo.
echo ============================================
echo Test Summary
echo ============================================
echo Total Tests: %test_count%
echo Passed: %pass_count%
echo Failed: %fail_count%
echo ============================================

if %fail_count% equ 0 (
    exit /b 0
) else (
    exit /b 1
)
