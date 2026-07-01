"""
Script to update all goblin mob .tscn files with empty SpriteFrames resources.
Run once to batch-update all scenes.
"""

import os
import re

PROJECT_ROOT = r"C:\Godot\clickcer"
SCENES_DIR = os.path.join(PROJECT_ROOT, "scenes", "mobs")

# Mapping: mob filename -> sprite frames resource name
MOB_FRAMES_MAP = {
    "BlueSlime.tscn": "BlueSlimeFrames.tres",
    "GoblinCrossbowman.tscn": "GoblinCrossbowmanFrames.tres",
    "GoblinSwordsman.tscn": "GoblinSwordsmanFrames.tres",
    "GoblinShaman.tscn": "GoblinShamanFrames.tres",
    "GoblinFireMage.tscn": "GoblinFireMageFrames.tres",
    "GoblinLightningMage.tscn": "GoblinLightningMageFrames.tres",
    "GoblinLizard.tscn": "GoblinLizardFrames.tres",
    "GoblinGiant.tscn": "GoblinGiantFrames.tres",
    "GoblinBatRider.tscn": "GoblinBatRiderFrames.tres",
    "GoblinPig.tscn": "GoblinPigFrames.tres",
    "CrabRider.tscn": "CrabRiderFrames.tres",
    "StoneGolem.tscn": "StoneGolemFrames.tres",
    "Sunfaced.tscn": "SunfacedFrames.tres",
}

def update_tscn_file(tscn_path, frames_resource):
    """Update a .tscn file to use the specified SpriteFrames resource."""
    with open(tscn_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find the last ext_resource ID number
    ext_resources = re.findall(r'id="(\d+)_', content)
    if ext_resources:
        last_id = max(int(x) for x in ext_resources)
        new_id = last_id + 1
    else:
        new_id = 100
    
    # Add the SpriteFrames resource after the last ext_resource
    ext_resource_line = f'[ext_resource type="Resource" path="res://resources/sprite_frames/{frames_resource}" id="{new_id}_frames"]'
    
    # Insert before the first [node or [sub_resource
    insert_pos = re.search(r'\n\[(?:node|sub_resource)', content)
    if insert_pos:
        content = content[:insert_pos.start()] + f'\n{ext_resource_line}' + content[insert_pos.start():]
    
    # Update AnimWalk node
    content = re.sub(
        r'(\[node name="AnimWalk" type="AnimatedSprite2D" parent="\."\])',
        rf'\1\nsprite_frames = ExtResource("{new_id}_frames")\nanimation = &"walk"',
        content
    )
    
    # Update AnimAttack node
    content = re.sub(
        r'(\[node name="AnimAttack" type="AnimatedSprite2D" parent="\."\])',
        rf'\1\nsprite_frames = ExtResource("{new_id}_frames")\nanimation = &"attack"',
        content
    )
    
    # Write back
    with open(tscn_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ Updated {os.path.basename(tscn_path)}")

def main():
    print("Updating mob .tscn files with SpriteFrames...")
    for tscn_file, frames_file in MOB_FRAMES_MAP.items():
        tscn_path = os.path.join(SCENES_DIR, tscn_file)
        if os.path.exists(tscn_path):
            update_tscn_file(tscn_path, frames_file)
        else:
            print(f"⚠ Not found: {tscn_file}")
    print(" Done!")

if __name__ == "__main__":
    main()
