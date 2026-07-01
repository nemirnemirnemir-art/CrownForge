#!/usr/bin/env python3
"""
Godot 4.3 Test Runner - Runs all tests and reports results
"""

import subprocess
import sys
import os

# Change to project directory
os.chdir(r'C:\Godot\clickcer')

GODOT_PATH = r'C:\Godot\Godot_v4.3-stable_win64.exe'
PROJECT_PATH = r'C:\Godot\clickcer'

tests = [
    'test_gamescene_bootstrap.gd',
    'test_gamescene_encounter_flow.gd',
    'test_gamescene_wave_flow.gd',
    'test_gamescene_building_drag.gd',
    'test_gamescenewaves_safe_singleton_lookup.gd',
    'test_gamescenewaves_spawn_service.gd',
    'test_gamescene_prophecy_open_variety.gd',
    'test_gamescene_building_move_state.gd',
    'test_mine_visual_and_runtime_guards.gd',
]

results = {}

print("=" * 60)
print("  GODOT 4.3 HEADLESS TEST RUNNER")
print("=" * 60)
print()

for idx, test_name in enumerate(tests, 1):
    test_path = f'scripts/dev/tests/{test_name}'
    
    print(f"[Test {idx}/{len(tests)}] Running: {test_name}")
    print("-" * 60)
    
    cmd = [GODOT_PATH, '--headless', '--path', PROJECT_PATH, '-s', test_path]
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=120
        )
        
        output = result.stdout + result.stderr
        exit_code = result.returncode
        
        # Print the output
        if output:
            print(output)
        
        # Determine PASS/FAIL
        passed = exit_code == 0 and 'PASS' in output
        failed = 'FAIL' in output or 'ERROR' in output or exit_code != 0
        
        if passed:
            status = "PASS"
        elif failed:
            status = "FAIL"
        else:
            status = "UNKNOWN"
        
        results[test_name] = status
        print(f"[Test {idx}/{len(tests)}] Result: {status} (exit code: {exit_code})")
    
    except subprocess.TimeoutExpired:
        print(f"[Test {idx}/{len(tests)}] TIMEOUT - Test took longer than 120 seconds")
        results[test_name] = "TIMEOUT"
    except Exception as e:
        print(f"[Test {idx}/{len(tests)}] ERROR - {str(e)}")
        results[test_name] = "ERROR"
    
    print()

# Summary
print("=" * 60)
print("  TEST SUMMARY")
print("=" * 60)
print()

pass_count = 0
fail_count = 0
other_count = 0

for test_name, status in results.items():
    print(f"{test_name:50s} {status:10s}")
    if status == "PASS":
        pass_count += 1
    elif status == "FAIL":
        fail_count += 1
    else:
        other_count += 1

print()
print(f"Total: {len(tests)} | Passed: {pass_count} | Failed: {fail_count} | Other: {other_count}")
print("=" * 60)
