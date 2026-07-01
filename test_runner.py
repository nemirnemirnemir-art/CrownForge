#!/usr/bin/env python3
"""
Godot 4.3 Test Runner
Runs all 9 tests and reports PASS/FAIL status
"""

import subprocess
import sys
import os
from datetime import datetime
from pathlib import Path

def main():
    # Configuration
    GODOT_PATH = r'C:\Godot\Godot_v4.3-stable_win64.exe'
    PROJECT_PATH = r'C:\Godot\clickcer'
    
    # Change to project directory
    os.chdir(PROJECT_PATH)
    
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
    detailed_output = {}
    
    # Header
    print("\n" + "=" * 80)
    print("  GODOT 4.3 HEADLESS TEST RUNNER")
    print(f"  Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80 + "\n")
    
    # Run each test
    for idx, test_name in enumerate(tests, 1):
        test_path = f'scripts/dev/tests/{test_name}'
        
        print(f"[{idx}/{len(tests)}] Running: {test_name}")
        print("-" * 80)
        
        cmd = [GODOT_PATH, '--headless', '--path', PROJECT_PATH, '-s', test_path]
        
        try:
            # Run the test
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=120
            )
            
            output = result.stdout + result.stderr
            exit_code = result.returncode
            
            # Store detailed output
            detailed_output[test_name] = {
                'output': output,
                'exit_code': exit_code
            }
            
            # Print output
            if output.strip():
                print(output)
            else:
                print("[No output captured]")
            
            # Determine result
            # PASS: exit code 0 AND contains "PASS"
            # FAIL: exit code non-zero OR contains "FAIL" or "ERROR"
            if exit_code == 0 and 'PASS' in output:
                status = "✓ PASS"
                results[test_name] = "PASS"
            elif exit_code != 0 or 'FAIL' in output or 'ERROR' in output:
                status = "✗ FAIL"
                results[test_name] = "FAIL"
            else:
                status = "? UNKNOWN"
                results[test_name] = "UNKNOWN"
            
            print(f"\nResult: {status} (exit code: {exit_code})")
        
        except subprocess.TimeoutExpired:
            print(f"✗ TIMEOUT - Test exceeded 120 second timeout")
            results[test_name] = "TIMEOUT"
            detailed_output[test_name] = {'output': 'TIMEOUT', 'exit_code': -1}
        
        except FileNotFoundError:
            print(f"✗ ERROR - Godot executable not found at: {GODOT_PATH}")
            results[test_name] = "ERROR"
            detailed_output[test_name] = {'output': f'Godot not found: {GODOT_PATH}', 'exit_code': -1}
        
        except Exception as e:
            print(f"✗ ERROR - {str(e)}")
            results[test_name] = "ERROR"
            detailed_output[test_name] = {'output': str(e), 'exit_code': -1}
        
        print()
    
    # Summary
    print("\n" + "=" * 80)
    print("  SUMMARY")
    print("=" * 80 + "\n")
    
    pass_count = sum(1 for status in results.values() if status == "PASS")
    fail_count = sum(1 for status in results.values() if status == "FAIL")
    other_count = len(results) - pass_count - fail_count
    
    for test_name, status in results.items():
        symbol = "✓" if status == "PASS" else "✗" if status == "FAIL" else "?"
        print(f"  {symbol} {test_name:50s} {status:10s}")
    
    print()
    print(f"  Total: {len(tests)} | Passed: {pass_count} | Failed: {fail_count} | Other: {other_count}")
    print("=" * 80)
    
    # Exit code
    if fail_count == 0 and other_count == 0:
        print("\n✓ All tests passed!\n")
        return 0
    else:
        print(f"\n✗ {fail_count + other_count} test(s) failed or had issues.\n")
        return 1

if __name__ == '__main__':
    exit_code = main()
    sys.exit(exit_code)
