"""
Convert hero scenes to dual AnimatedSprite2D system (AnimWalk + AnimAttack).
Each hero will have two separate nodes with their own SpriteFrames resources.
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

def convert_hero_to_dual_sprites(filepath):
    """Convert a hero scene from single AnimationSprite2D to dual AnimWalk/AnimAttack system."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 1. Find the existing SpriteFrames sub_resource ID
    spriteframes_match = re.search(r'\[sub_resource type="SpriteFrames" id="(SpriteFrames_\w+)"\]', content)
    if not spriteframes_match:
        print(f"✗ {os.path.basename(filepath)}: Could not find SpriteFrames sub_resource")
        return False
    
    original_spriteframes_id = spriteframes_match.group(1)
    
    # 2. Extract the full SpriteFrames block
    spriteframes_start = content.find(f'[sub_resource type="SpriteFrames" id="{original_spriteframes_id}"]')
    if spriteframes_start == -1:
        print(f"✗ {os.path.basename(filepath)}: Could not find SpriteFrames block start")
        return False
    
    # Find the end of the SpriteFrames block (next sub_resource or node)
    spriteframes_end = content.find('\n[', spriteframes_start + 1)
    if spriteframes_end == -1:
        spriteframes_end = len(content)
    
    spriteframes_block = content[spriteframes_start:spriteframes_end]
    
    # 3. Split into walk and attack animations
    # Extract walk animation block
    walk_match = re.search(r'(\{[\s\S]*?"name": &"walk"[\s\S]*?\})', spriteframes_block)
    attack_match = re.search(r'(\{[\s\S]*?"name": &"attack"[\s\S]*?\})', spriteframes_block)
    
    if not walk_match or not attack_match:
        print(f"✗ {os.path.basename(filepath)}: Could not extract walk/attack animations")
        return False
    
    walk_anim_block = walk_match.group(1)
    attack_anim_block = attack_match.group(1)
    
    # 4. Create two new SpriteFrames sub_resources
    walk_spriteframes = f"""[sub_resource type="SpriteFrames" id="SpriteFrames_walk"]
animations = [{walk_anim_block}]
"""
    
    attack_spriteframes = f"""[sub_resource type="SpriteFrames" id="SpriteFrames_attack"]
animations = [{attack_anim_block}]
"""
    
    # 5. Replace the original SpriteFrames with the two new ones
    content = content.replace(spriteframes_block, walk_spriteframes + "\n" + attack_spriteframes)
    
    # 6. Find and replace the AnimationSprite2D node
    anim_sprite_pattern = r'\[node name="AnimationSprite2D" type="AnimatedSprite2D" parent="\."\][\s\S]*?(?=\n\[node )'
    anim_sprite_match = re.search(anim_sprite_pattern, content)
    
    if not anim_sprite_match:
        print(f"✗ {os.path.basename(filepath)}: Could not find AnimationSprite2D node")
        return False
    
    anim_sprite_block = anim_sprite_match.group(0)
    
    # Extract important properties (scale, offset, etc.)
    scale_match = re.search(r'scale = (Vector2\([^)]+\))', anim_sprite_block)
    offset_match = re.search(r'offset = (Vector2\([^)]+\))', anim_sprite_block)
    
    scale_prop = scale_match.group(0) if scale_match else "scale = Vector2(0.5, 0.5)"
    offset_prop = offset_match.group(0) if offset_match else "offset = Vector2(0, -30)"
    
    # 7. Create new dual sprite nodes
    new_anim_nodes = f"""[node name="AnimWalk" type="AnimatedSprite2D" parent="."]
{scale_prop}
sprite_frames = SubResource("SpriteFrames_walk")
animation = &"walk"
{offset_prop}

[node name="AnimAttack" type="AnimatedSprite2D" parent="."]
visible = false
{scale_prop}
sprite_frames = SubResource("SpriteFrames_attack")
animation = &"attack"
{offset_prop}
"""
    
    # 8. Replace old AnimationSprite2D with new dual system
    content = content.replace(anim_sprite_block, new_anim_nodes)
    
    # 9. Update AttackComponent animation_sprite_path reference
    content = re.sub(
        r'animation_sprite_path = NodePath\("../AnimationSprite2D"\)',
        'animation_sprite_path = NodePath("../AnimAttack")',
        content
    )
    
    # Write the updated content
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    
    return False

print("Converting hero scenes to dual AnimatedSprite2D system...")
print("=" * 60)

success_count = 0
for hero_file in HERO_FILES:
    filepath = os.path.join(SCENES_DIR, hero_file)
    if os.path.exists(filepath):
        if convert_hero_to_dual_sprites(filepath):
            print(f"✓ Converted {hero_file}")
            success_count += 1
        else:
            print(f"⚠ No changes for {hero_file}")
    else:
        print(f"✗ File not found: {hero_file}")

print("=" * 60)
print(f"Conversion complete! {success_count}/{len(HERO_FILES)} heroes converted.")
print("\nNext steps:")
print("1. Open Godot and verify hero scenes")
print("2. Check that AnimWalk is visible and AnimAttack is hidden")
print("3. Test heroes in game to ensure animations work")
