import subprocess
import sys

godot_path = r"C:\Godot\Godot_v4.3-stable_win64.exe"
project_path = r"C:\Godot\clickcer"

tests = [
    "scripts/dev/tests/test_gamescene_bootstrap.gd",
    "scripts/dev/tests/test_gamescene_encounter_flow.gd",
    "scripts/dev/tests/test_gamescene_wave_flow.gd",
    "scripts/dev/tests/test_gamescene_building_drag.gd",
    "scripts/dev/tests/test_gamescenewaves_safe_singleton_lookup.gd",
    "scripts/dev/tests/test_gamescenewaves_spawn_service.gd",
    "scripts/dev/tests/test_gamescene_prophecy_open_variety.gd",
    "scripts/dev/tests/test_gamescene_building_move_state.gd",
    "scripts/dev/tests/test_mine_visual_and_runtime_guards.gd",
]

results = []

for i, test in enumerate(tests, 1):
    print(f"\n{'='*70}")
    print(f"TEST {i}/9: {test}")
    print('='*70)
    
    cmd = [godot_path, "--headless", "--path", project_path, "-s", test]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        exit_code = result.returncode
        output = result.stdout + result.stderr
        
        # Check for PASS or FAIL/ERROR
        has_pass = "PASS" in output
        has_fail = "FAIL" in output or "ERROR" in output
        is_error_exit = exit_code != 0
        
        # Determine if test passed
        test_passed = (exit_code == 0 and has_pass) or (not is_error_exit and has_pass)
        test_failed = has_fail or is_error_exit
        
        if test_passed and not test_failed:
            status = "✓ PASSED"
            results.append((i, test.split('/')[-1], "PASSED"))
        else:
            status = "✗ FAILED"
            results.append((i, test.split('/')[-1], "FAILED"))
        
        print(f"{status} (exit code: {exit_code})")
        print("\nOUTPUT:")
        print(output)
        
    except subprocess.TimeoutExpired:
        print(f"✗ TIMEOUT (120 seconds exceeded)")
        results.append((i, test.split('/')[-1], "TIMEOUT"))
    except Exception as e:
        print(f"✗ ERROR: {e}")
        results.append((i, test.split('/')[-1], "ERROR"))
    
    print()

# Summary
print("\n" + "="*70)
print("SUMMARY")
print("="*70)
for test_num, test_name, status in results:
    print(f"{test_num}. {test_name}: {status}")
