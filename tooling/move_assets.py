import os
import shutil
import glob

moves = [
    ('assets/craft_panel', 'assets/ui/craft_panel'),
    ('assets/digits', 'assets/ui/digits'),
    ('assets/fonts', 'assets/ui/fonts'),
    ('assets/icons', 'assets/ui/icons'),
    ('assets/stage_icons', 'assets/ui/stage_icons'),
    ('assets/status_icons', 'assets/ui/status_icons'),
    ('assets/upgrades_denarii', 'assets/ui/upgrades_denarii'),
    ('assets/items_panel_background.png', 'assets/ui/items_panel_background.png'),
    ('assets/items_panel_background.png.import', 'assets/ui/items_panel_background.png.import'),
    
    ('assets/heroes_from_website', 'assets/characters/heroes_from_website'),
    ('assets/tinyHeroes', 'assets/characters/tinyHeroes'),
    ('assets/bosses', 'assets/characters/bosses'),
    ('assets/enemies', 'assets/characters/enemies'),
    ('assets/Minotaur', 'assets/characters/Minotaur'),
    ('assets/nobody', 'assets/characters/nobody'),
    ('assets/characher_faces', 'assets/characters/character_faces'),
    
    ('assets/backgrounds', 'assets/environment/backgrounds'),
    ('assets/biomes', 'assets/environment/biomes'),
    ('assets/buildings', 'assets/environment/buildings'),
    ('assets/wall', 'assets/environment/wall'),
    
    ('assets/animations', 'assets/vfx/animations'),
    ('assets/Particle FX', 'assets/vfx/Particle FX'),
    ('assets/effects', 'assets/vfx/effects'),
    ('assets/spells', 'assets/vfx/spells'),
    ('assets/spells_visuals', 'assets/vfx/spells_visuals'),
    ('assets/buffs', 'assets/vfx/buffs'),
    ('assets/projective', 'assets/vfx/projectiles'),
    
    ('assets/new_resourses', 'assets/items/resources'),
    ('assets/res', 'assets/items/res'),
    ('assets/seals', 'assets/items/seals'),
    ('assets/gold.png', 'assets/items/gold.png'),
    ('assets/gold.png.import', 'assets/items/gold.png.import'),
    ('assets/heroesgold.png', 'assets/items/heroesgold.png'),
    ('assets/heroesgold.png.import', 'assets/items/heroesgold.png.import'),
    
    ('assets/skills', 'assets/gameplay/skills'),
    
    ('assets/temporal', 'assets/misc/temporal'),
    
    ('assets/docs', 'docs')
]

# Add temp_slices for 1*.png
temp_slices_dir = 'assets/misc/temp_slices'
os.makedirs(temp_slices_dir, exist_ok=True)
for f in os.listdir('assets'):
    if f.startswith('1') and f.endswith('.png'):
        moves.append((f'assets/{f}', f'{temp_slices_dir}/{f}'))
    if f.startswith('1') and f.endswith('.png.import'):
        moves.append((f'assets/{f}', f'{temp_slices_dir}/{f}'))

# Create target directories
dirs_to_create = set()
for old_p, new_p in moves:
    dirs_to_create.add(os.path.dirname(new_p))
for d in dirs_to_create:
    if d:
        os.makedirs(d, exist_ok=True)

# Move files/folders
actual_moves = []
for old_p, new_p in moves:
    if os.path.exists(old_p):
        print(f"Moving {old_p} -> {new_p}")
        shutil.move(old_p, new_p)
        actual_moves.append(('res://' + old_p.replace('\\\\', '/'), 'res://' + new_p.replace('\\\\', '/')))

# Special case for characher_faces typo fix
actual_moves.append(('res://assets/characher_faces', 'res://assets/characters/character_faces'))
actual_moves.append(('res://assets/projective', 'res://assets/vfx/projectiles'))

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

print(f'Moved {len(actual_moves)} items and updated {updated_count} files.')
