import os
import shutil
import glob

moves = [
    # Markdown docs
    ('FINAL_STEPS.md', 'docs/FINAL_STEPS.md'),
    ('AGENTS.md', 'docs/AGENTS.md'),
    ('Prohesy_mates.md', 'docs/Prohesy_mates.md'),
    ('RESOURCE_MIGRATION_PLAN.md', 'docs/RESOURCE_MIGRATION_PLAN.md'),
    ('RESOURCE_REFACTOR_SUMMARY.md', 'docs/RESOURCE_REFACTOR_SUMMARY.md'),
    ('artefact_progress250126.md', 'docs/artefact_progress250126.md'),
    ('faceRigEditor.md', 'docs/faceRigEditor.md'),
    ('project_description.md', 'docs/project_description.md'),
    
    # Text files
    ('ascii_patterns.txt', 'docs/ascii_patterns.txt'),
    ('patterns_generated.txt', 'docs/patterns_generated.txt'),
    ('result_patterns.txt', 'docs/result_patterns.txt'),
    ('script_output.txt', 'docs/script_output.txt'),
    
    # Scripts
    ('fix_icons.gd', 'tooling/fix_icons.gd'),
    ('move_assets.py', 'tooling/move_assets.py'),
    
    # Scenes and Assets
    ('Arrow.tscn', 'scenes/projectiles/Arrow.tscn'),
    ('Icon_09.png', 'assets/misc/Icon_09.png'),
    ('Icon_09.png.import', 'assets/misc/Icon_09.png.import')
]

# Create target directories if they don't exist
os.makedirs('docs', exist_ok=True)
os.makedirs('tooling', exist_ok=True)
os.makedirs('scenes/projectiles', exist_ok=True)
os.makedirs('assets/misc', exist_ok=True)

# Process deletions
files_to_delete = ['assets вЂ” СЏСЂР»С‹Рє.lnk', 'nul']
for f in files_to_delete:
    if os.path.exists(f):
        print(f"Deleting {f}")
        try:
            os.remove(f)
        except Exception as e:
            print(f"Failed to delete {f}: {e}")

# Process moves
actual_moves = []
for old_p, new_p in moves:
    if os.path.exists(old_p):
        print(f"Moving {old_p} -> {new_p}")
        shutil.move(old_p, new_p)
        # Store full res:// paths for search and replace
        actual_moves.append((f'res://{old_p}', f'res://{new_p}'))

# Sort by length descending to prevent partial match issues
actual_moves.sort(key=lambda x: len(x[0]), reverse=True)

# Find all files to update
files_to_check = []
for ext in ['*.gd', '*.tscn', '*.tres']:
    files_to_check.extend(glob.glob(f'**/{ext}', recursive=True))

updated_count = 0
for filepath in files_to_check:
    if '.godot' in filepath:
        continue
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original_content = content
        for old_path, new_path in actual_moves:
            content = content.replace(old_path, new_path)
            
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            updated_count += 1
            print(f'Updated {filepath}')
    except Exception as e:
        print(f"Could not process {filepath}: {e}")

print(f'Moved {len(actual_moves)} items and updated {updated_count} files.')

