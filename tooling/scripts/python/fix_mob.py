import re

# Read the file
with open('c:/Users/Maks/Documents/clickcer/scripts/Mob.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove MobSaveFromStackState from condition
content = re.sub(
    r'if state_name != "MobIdleState" and state_name != "MobDeathState" and state_name != "MobSaveFromStackState":',
    'if state_name != "MobIdleState" and state_name != "MobDeathState":',
    content
)

# Remove transition to MobSaveFromStackState
content = re.sub(
    r'\t\t\t\tif _state_machine:\n\t\t\t\t\t_state_machine\.change_state\("MobSaveFromStackState"\)\n',
    '',
    content
)

# Write back
with open('c:/Users/Maks/Documents/clickcer/scripts/Mob.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed Mob.gd")
