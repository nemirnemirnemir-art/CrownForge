import subprocess
import sys

godot_path = r"C:\Godot\Godot_v4.3-stable_win64.exe"
project_path = r"C:\Godot\clickcer"

tests = [
    "scripts/dev/tests/test_towncore_build_flow.gd",
    "scripts/dev/tests/test_towncore_save_flow.gd",
    "scripts/dev/tests/test_towncore_population_flow.gd",
    "scripts/dev/tests/test_towncore_upgrade_flow.gd",
]

for i, test in enumerate(tests, 1):
    print(f"\n{'='*70}")
    print(f"TEST {i}: {test}")
    print('='*70)
    
    cmd = [godot_path, "--headless", "--path", project_path, "-s", test]
    
    try:
        result = subprocess.run(cmd, capture_output=False, text=True)
        exit_code = result.returncode
        if exit_code == 0:
            print(f"✓ TEST {i} PASSED")
        else:
            print(f"✗ TEST {i} FAILED (exit code: {exit_code})")
    except Exception as e:
        print(f"✗ TEST {i} FAILED WITH ERROR: {e}")
    
    print()
