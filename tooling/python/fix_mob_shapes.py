import os
import re

PROJECT_ROOT = r"C:\Godot\clickcer"
SCENES_DIR = os.path.join(PROJECT_ROOT, "scenes", "mobs")

MOBS_TO_FIX = [
    "BlueSlime.tscn",
    "GoblinCrossbowman.tscn",
    "GoblinSwordsman.tscn",
    "GoblinShaman.tscn",
    "GoblinFireMage.tscn",
    "GoblinLightningMage.tscn",
    "GoblinLizard.tscn",
    "GoblinGiant.tscn",
    "WallBuster.tscn",
    "GoblinBatRider.tscn",
    "GoblinPig.tscn",
    "CrabRider.tscn",
    "StoneGolem.tscn",
    "Sunfaced.tscn",
]

# Standard shapes as sub_resources
STANDARD_SHAPES_BLOCK = """
[sub_resource type="CircleShape2D" id="CircleShape2D_aggro"]
radius = 180.0

[sub_resource type="CircleShape2D" id="CircleShape2D_hurt"]
radius = 70.0

[sub_resource type="CircleShape2D" id="CircleShape2D_hit"]
radius = 40.0

[sub_resource type="CircleShape2D" id="CircleShape2D_wallcol"]
radius = 20.0

[sub_resource type="RectangleShape2D" id="RectangleShape2D_click"]
size = Vector2(50, 60)
"""

def fix_tscn(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add standard shapes to sub-resources if missing
    if 'id="CircleShape2D_aggro"' not in content:
        # Find position to insert sub-resources (after the last ext_resource)
        last_ext = 0
        for m in re.finditer(r'\[ext_resource .*?\]', content):
            last_ext = m.end()
        
        if last_ext > 0:
            content = content[:last_ext] + "\n" + STANDARD_SHAPES_BLOCK + content[last_ext:]
        else:
            # Fallback if no ext_resources (shouldn't happen)
            content = content.replace('\n', '\n' + STANDARD_SHAPES_BLOCK, 1)

    # 2. Fix AttackShapeCast
    # Replace [node name="AttackShapeCast" type="ShapeCast2D" parent="."] followed by potential properties
    # ensuring it has shape = SubResource("CircleShape2D_hit")
    content = re.sub(
        r'(\[node name="AttackShapeCast" type="ShapeCast2D" parent="\."\]\n)(visible = false\n)?',
        r'\1visible = false\nshape = SubResource("CircleShape2D_hit")\n',
        content
    )

    # 3. Fix WallCollision
    content = re.sub(
        r'(\[node name="WallCollision" type="CollisionShape2D" parent="\."\]\n)(position = .*?\n)?',
        r'\1\2shape = SubResource("CircleShape2D_wallcol")\n',
        content
    )

    # 4. Fix AggroArea (add child if missing)
    if '[node name="CollisionShape2D" parent="AggroArea"]' not in content:
        content = re.sub(
            r'(\[node name="AggroArea" type="Area2D" parent="\."\]\n.*?script = ExtResource\("\d+_aggro"\).*?\n)',
            r'\1\n[node name="CollisionShape2D" type="CollisionShape2D" parent="AggroArea"]\nshape = SubResource("CircleShape2D_aggro")\n',
            content
        )

    # 5. Fix Hurtbox
    if '[node name="CollisionShape2D" parent="Hurtbox"]' not in content:
        content = re.sub(
            r'(\[node name="Hurtbox" type="Area2D" parent="\."\]\n.*?script = ExtResource\("\d+_hurt"\).*?\n)',
            r'\1\n[node name="CollisionShape2D" type="CollisionShape2D" parent="Hurtbox"]\nshape = SubResource("CircleShape2D_hurt")\n',
            content
        )

    # 6. Fix Hitbox
    if '[node name="CollisionShape2D" parent="Hitbox"]' not in content:
        content = re.sub(
            r'(\[node name="Hitbox" type="Area2D" parent="\."\]\n.*?script = ExtResource\("\d+_hit"\).*?\n)',
            r'\1\n[node name="CollisionShape2D" type="CollisionShape2D" parent="Hitbox"]\nshape = SubResource("CircleShape2D_hit")\n',
            content
        )

    # 7. Fix ClickArea
    if '[node name="CollisionShape2D" parent="ClickArea"]' not in content:
        content = re.sub(
            r'(\[node name="ClickArea" type="Area2D" parent="\."\]\n)',
            r'\1\n[node name="CollisionShape2D" type="CollisionShape2D" parent="ClickArea"]\nposition = Vector2(0, -30)\nshape = SubResource("RectangleShape2D_click")\n',
            content
        )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Starting fix process...")
for mob in MOBS_TO_FIX:
    p = os.path.join(SCENES_DIR, mob)
    if os.path.exists(p):
        fix_tscn(p)
        print(f"Fixed {mob}")
    else:
        print(f"Skipped {mob} (not found)")
print("Done!")
