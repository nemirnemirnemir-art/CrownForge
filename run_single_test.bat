@echo off
setlocal enabledelayedexpansion

REM Test 1
echo Running test_gamescene_bootstrap.gd...
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescene_bootstrap.gd
echo.
echo.

REM Test 2
echo Running test_gamescene_encounter_flow.gd...
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescene_encounter_flow.gd
echo.
echo.

REM Test 3
echo Running test_gamescene_wave_flow.gd...
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescene_wave_flow.gd
echo.
echo.

REM Test 4
echo Running test_gamescene_building_drag.gd...
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescene_building_drag.gd
echo.
echo.

REM Test 5
echo Running test_gamescenewaves_safe_singleton_lookup.gd...
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescenewaves_safe_singleton_lookup.gd
echo.
echo.

REM Test 6
echo Running test_gamescenewaves_spawn_service.gd...
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescenewaves_spawn_service.gd
echo.
echo.

REM Test 7
echo Running test_gamescene_prophecy_open_variety.gd...
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescene_prophecy_open_variety.gd
echo.
echo.

REM Test 8
echo Running test_gamescene_building_move_state.gd...
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescene_building_move_state.gd
echo.
echo.

REM Test 9
echo Running test_mine_visual_and_runtime_guards.gd...
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_mine_visual_and_runtime_guards.gd
echo.
echo.
