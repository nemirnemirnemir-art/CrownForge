import os

base_path = r'c:/Users/Maks/Documents/clickcer'
buildings_path = os.path.join(base_path, 'data/buildings')

tres_files = [f for f in os.listdir(buildings_path) if f.endswith('.tres')]

# Filter only Buildings of type BuildingConfig
building_configs = []
for f in tres_files:
    try:
        with open(os.path.join(buildings_path, f), 'r', encoding='utf-8') as file:
            content = file.read()
            if 'script_class="BuildingConfig"' in content:
                building_configs.append(f)
    except:
        pass

# Sort to be consistent
building_configs.sort()

# Generate tscn
# load_steps = script + config_script + n_resources
tscn_header = '[gd_scene load_steps={} format=3 uid="uid://bmrgkadq5krhe"]\n\n'.format(len(building_configs) + 3)
tscn_header += '[ext_resource type="Script" path="res://core/buildings/BuildingRegistry.gd" id="1_registry"]\n'
tscn_header += '[ext_resource type="Script" path="res://core/buildings/BuildingConfig.gd" id="2_config"]\n'

ext_resources = ""
array_elements = []

for idx, f in enumerate(building_configs):
    res_id = idx + 3
    ext_resources += f'[ext_resource type="Resource" path="res://data/buildings/{f}" id="{res_id}_res"]\n'
    array_elements.append(f'ExtResource("{res_id}_res")')

# Generate the Node
tscn_node = '\n[node name="BuildingRegistry" type="Node"]\n'
tscn_node += 'script = ExtResource("1_registry")\n'
tscn_node += 'buildings = Array[ExtResource("2_config")]([' + ", ".join(array_elements) + '])\n'

with open(os.path.join(base_path, 'core/buildings/BuildingRegistry.tscn'), 'w', encoding='utf-8', newline='\n') as f:
    f.write(tscn_header + ext_resources + tscn_node)

print(f"Cleanly updated BuildingRegistry.tscn with {len(building_configs)} buildings.")
