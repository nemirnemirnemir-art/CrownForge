@echo off
setlocal enabledelayedexpansion

echo ===== TEST 1: test_vzorzone_model.gd =====
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_vzorzone_model.gd
echo Exit Code: !ERRORLEVEL!
echo.
echo ===== TEST 2: test_mapslot_vzor_visual_flow.gd =====
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_mapslot_vzor_visual_flow.gd
echo Exit Code: !ERRORLEVEL!
echo.
echo ===== TEST 3: test_monument_gaze_uses_grid_neighbors.gd =====
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_monument_gaze_uses_grid_neighbors.gd
echo Exit Code: !ERRORLEVEL!
