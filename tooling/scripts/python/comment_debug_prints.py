#!/usr/bin/env python3
"""
Comment out all print() statements in GDScript files EXCEPT corpse-related ones.
Corpse-related prints are preserved for debugging.
"""

import os
import re
from pathlib import Path

# Root directory of the project
ROOT_DIR = Path(r"c:\Godot\clickcer")

# Files that contain corpse-related debug prints (these will have special handling)
CORPSE_FILES = {
    "scripts/Mob.gd",
    "scripts/effects/Corpse.gd",
    "scripts/effects/NecromancyEffect.gd"
}

# Keywords that indicate a corpse-related print (case-insensitive)
CORPSE_KEYWORDS = ["corpse", "necromancy"]


def should_preserve_print(line: str, file_path: str) -> bool:
    """Check if this print statement should be preserved."""
    # Normalize file path for comparison
    rel_path = str(Path(file_path).relative_to(ROOT_DIR)).replace("\\", "/")
    
    # If not in a corpse file, comment it out
    if rel_path not in CORPSE_FILES:
        return False
    
    # In corpse files, check if line contains corpse-related keywords
    line_lower = line.lower()
    for keyword in CORPSE_KEYWORDS:
        if keyword in line_lower:
            return True
    
    return False


def comment_out_prints(file_path: Path) -> int:
    """Comment out non-corpse print statements in a file. Returns number of lines changed."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return 0
    
    changed = 0
    new_lines = []
    
    for line in lines:
        # Check if line contains a print statement and is not already commented
        if 'print(' in line and not line.strip().startswith('#'):
            # Check if this print should be preserved
            if should_preserve_print(line, str(file_path)):
                new_lines.append(line)
            else:
                # Comment it out by adding # at the beginning (preserving indentation)
                indent = len(line) - len(line.lstrip())
                commented_line = line[:indent] + '# ' + line[indent:]
                new_lines.append(commented_line)
                changed += 1
        else:
            new_lines.append(line)
    
    if changed > 0:
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            print(f"✓ {file_path.relative_to(ROOT_DIR)}: {changed} prints commented")
        except Exception as e:
            print(f"Error writing {file_path}: {e}")
            return 0
    
    return changed


def main():
    """Process all .gd files in the project."""
    total_changed = 0
    files_processed = 0
    
    print("Starting debug print commenting...")
    print(f"Root: {ROOT_DIR}")
    print(f"Preserving corpse-related prints in: {', '.join(CORPSE_FILES)}")
    print()
    
    for gd_file in ROOT_DIR.rglob("*.gd"):
        # Skip .godot directory
        if ".godot" in gd_file.parts:
            continue
        
        files_processed += 1
        changed = comment_out_prints(gd_file)
        total_changed += changed
    
    print()
    print(f"==== Summary ====")
    print(f"Files processed: {files_processed}")
    print(f"Total prints commented: {total_changed}")
    print()
    print("Corpse-related debug prints preserved in:")
    for file in CORPSE_FILES:
        print(f"  - {file}")


if __name__ == "__main__":
    main()
