"""
Update all hero script files to integrate HeroAIController.
Adds AI controller initialization and update calls to existing hero scripts.
"""

import os
import re

PROJECT_ROOT = r"C:\Godot\clickcer"
SCRIPTS_DIR = os.path.join(PROJECT_ROOT, "scripts")

# Map hero scene names to their script files
HERO_SCRIPTS = {
    "Peasant.tscn": "PeasantOnField.gd",
    "Archer.tscn": "ArcherOnField.gd",
    "Light_Legionary.tscn": "LightLegionaryOnField.gd",
    "Light_Spearman.tscn": "LightSpearmanOnField.gd",
    "Mercenary.tscn": "MercenaryOnField.gd",
    "Slinger.tscn": "SlingerOnField.gd"
}

SETUP_CODE = """
	# NEW: Setup HeroAIController for patrol/engage/attack behavior
	var hero_ai = get_node_or_null("HeroAIController")
	if hero_ai:
		hero_ai.setup(self, _c_nav, _c_animations, get_node_or_null("AttackComponent"))
		
		# Set patrol zone near castle
		var castle_pos = MapMarkerService.get_bridge_position()
		hero_ai.set_patrol_zone(castle_pos, 100.0)
		
		print("[%s] HeroAIController initialized, patrol zone set" % name)
	
	# NEW: Reference dual animation sprites (AnimWalk/AnimAttack)
	var anim_walk_node = get_node_or_null("AnimWalk")
	var anim_attack_node = get_node_or_null("AnimAttack")
	if anim_walk_node and anim_attack_node:
		# Dual sprite system (like mobs)
		anim_walk_node.visible = true
		anim_attack_node.visible = false
		print("[%s] Using dual sprite system (AnimWalk/AnimAttack)" % name)
"""

UPDATE_CODE = """
	# NEW: Update HeroAIController
	var hero_ai = get_node_or_null("HeroAIController")
	if hero_ai and hero_ai.has_method("update"):
		hero_ai.update(delta)
"""

def add_ai_to_script(filepath):
    """Add HeroAIController integration to a hero script."""
    if not os.path.exists(filepath):
        return False
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Check if already added
    if 'HeroAIController initialized' in content:
        print(f"⚠ {os.path.basename(filepath)}: Already has HeroAIController code")
        return False
    
    # 1. Add setup code to _ready() function
    # Find "_c_gohome.setup(self)" line and add after it
    gohome_pattern = r'(\tif _c_gohome and _c_gohome\.has_method\("setup"\):\n\t\t_c_gohome\.setup\(self\))'
    
    if re.search(gohome_pattern, content):
        content = re.sub(gohome_pattern, r'\1' + SETUP_CODE, content)
    
    # 2. Add update code to _process() function
    # Find the combat update and add after it
    combat_update_pattern = r'(\tif _c_combat and _c_combat\.has_method\("update"\):\n\t\t_c_combat\.update\(delta\))'
    
    if re.search(combat_update_pattern, content):
        content = re.sub(combat_update_pattern, r'\1' + UPDATE_CODE, content)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    
    return False

print("Updating hero scripts with HeroAIController integration...")
print("=" * 60)

# For now, we've manually updated PeasantOnField.gd
# This script can be used to update the others if they have similar structure
print("✓ PeasantOnField.gd already updated manually")
print("\nNote: Other hero scripts (Archer, Light_Legionary, etc.)")
print("may need manual updates if their structure differs from Peasant.")
print("\nTo update other heroes, run this script after confirming")
print("they have similar _c_gohome and _c_combat patterns.")
print("=" * 60)
