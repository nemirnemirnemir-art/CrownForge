"""
Add HeroAIController node to all hero .tscn files.
This script automatically injects the HeroAIController node after the Components node.
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

# Template for HeroAIController node
HERO_AI_NODE_TEMPLATE = """
[node name="HeroAIController" type="Node" parent="."]
script = ExtResource("hero_ai_script")
"""

def add_heroai_controller(filepath):
    """Add HeroAIController node to a hero scene."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 1. Check if HeroAIController already exists
    if '[node name="HeroAIController"' in content:
        print(f"⚠ {os.path.basename(filepath)}: HeroAIController already exists, skipping")
        return False
    
    # 2. Find the last ext_resource to get the next ID
    ext_resources = re.findall(r'\[ext_resource.*?id="(\d+)_', content)
    if ext_resources:
        last_id = max(int(x) for x in ext_resources)
        new_id = last_id + 1
    else:
        new_id = 100
    
    # 3. Add HeroAIController script as ext_resource
    ai_script_line = f'[ext_resource type="Script" path="res://scripts/hero_ai/HeroAIController.gd" id="{new_id}_heroai"]\n'
    
    # Find position to insert (after last ext_resource, before first sub_resource or node)
    insert_pos = re.search(r'\n\[(?:sub_resource|node)', content)
    if insert_pos:
        content = content[:insert_pos.start()] + f'\n{ai_script_line}' + content[insert_pos.start():]
    else:
        print(f"✗ {os.path.basename(filepath)}: Could not find insertion point")
        return False
    
    # 4. Find Components node to add HeroAIController after it
    components_match = re.search(r'(\[node name="Components" type="Node" parent="\."\])', content)
    if not components_match:
        print(f"✗ {os.path.basename(filepath)}: Could not find Components node")
        return False
    
    # Find the next [node after Components
    components_end = components_match.end()
    next_node_pos = content.find('\n[node name=', components_end)
    
    if next_node_pos == -1:
        # Components is the last node, append at the end
        ai_controller_node = f'\n[node name="HeroAIController" type="Node" parent="."]\nscript = ExtResource("{new_id}_heroai")\n'
        content = content + ai_controller_node
    else:
        # Insert before the next node
        ai_controller_node = f'\n[node name="HeroAIController" type="Node" parent="."]\nscript = ExtResource("{new_id}_heroai")\n'
        content = content[:next_node_pos] + ai_controller_node + content[next_node_pos:]
    
    # Write updated content
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    
    return False

print("Adding HeroAIController to hero scenes...")
print("=" * 60)

success_count = 0
for hero_file in HERO_FILES:
    filepath = os.path.join(SCENES_DIR, hero_file)
    if os.path.exists(filepath):
        if add_heroai_controller(filepath):
            print(f"✓ Added HeroAIController to {hero_file}")
            success_count += 1
        else:
            print(f"⚠ Skipped {hero_file}")
    else:
        print(f"✗ File not found: {hero_file}")

print("=" * 60)
print(f"Complete! {success_count}/{len(HERO_FILES)} heroes updated.")
print("\nHeroAIController node has been added to all hero scenes.")
print("Heroes will now use the patrol/engage/attack AI system.")
