"""
Remove idle animation from all hero scene files.
Removes the idle animation block from SpriteFrames sub-resources.
"""

import os
import re

PROJECT_ROOT = r"C:\Godot\clickcer"
SCENES_DIR = os.path.join(PROJECT_ROOT, "scenes")

HERO_FILES = [
    "Peasant.tscn",
    "Archer.tscn",
    "Light_Legionary.tscn",
    "Light_Spearman.tscn",
    "Mercenary.tscn",
    "Slinger.tscn"
]

def remove_idle_animation(content):
    """Remove the idle animation block from SpriteFrames."""
    # Pattern to match the idle animation block within the animations array
    # This matches from the start of the idle frames array to the closing brace
    idle_pattern = r',\s*\{\n\s*"frames":\s*\[[\s\S]*?\],\n\s*"loop":\s*true,\n\s*"name":\s*&"idle",\n\s*"speed":\s*[\d.]+\n\s*\}'
    
    content = re.sub(idle_pattern, '', content)
    return content

def remove_idle_ext_resources(content):
    """Remove ext_resource lines for idle animation textures."""
    # Find all ext_resource lines that reference peasant_idle, archer_idle, etc.
    idle_resource_pattern = r'\[ext_resource.*?(?:peasant_idle|archer_idle|light_legionary_idle|light_spearman_idle|mercenary_idle|slinger_idle).*?\]\n'
    
    content = re.sub(idle_resource_pattern, '', content, flags=re.IGNORECASE)
    return content

def fix_hero_scene(filepath):
    """Remove idle animation from a hero scene file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Remove idle animation block
    content = remove_idle_animation(content)
    
    # Remove idle texture ext_resources
    content = remove_idle_ext_resources(content)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

print("Removing idle animations from hero scenes...")
for hero_file in HERO_FILES:
    filepath = os.path.join(SCENES_DIR, hero_file)
    if os.path.exists(filepath):
        if fix_hero_scene(filepath):
            print(f"✓ Removed idle animation from {hero_file}")
        else:
            print(f"⚠ No changes needed for {hero_file}")
    else:
        print(f"✗ File not found: {hero_file}")

print("\nDone! All hero scenes updated.")
print("Next: Open each hero scene in Godot Editor to verify idle animation is removed.")
