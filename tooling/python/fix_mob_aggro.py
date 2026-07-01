"""
Скрипт для добавления CollisionShape2D к AggroArea во всех сценах мобов.
Также устанавливает collision_mask для AggroArea.
"""

import os
import re

MOB_SCENES_DIR = r"C:\Godot\clickcer\scenes\mobs"
AGGRO_RADIUS = 200.0  # Радиус агро-зоны

def fix_mob_scene(filepath: str) -> bool:
    """Добавляет CollisionShape2D в AggroArea моба если его нет"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Проверяем есть ли уже CollisionShape2D для AggroArea
    if 'parent="AggroArea"' in content and 'CollisionShape2D' in content:
        agro_match = re.search(r'\[node name="CollisionShape2D"[^\]]*parent="AggroArea"', content)
        if agro_match:
            print(f"  {os.path.basename(filepath)}: AggroArea already has CollisionShape2D")
            return False
    
    # Ищем AggroArea
    aggro_match = re.search(r'\[node name="AggroArea" type="Area2D" parent="\."\]\n(.*?)(?=\n\[node)', content, re.DOTALL)
    if not aggro_match:
        print(f"  {os.path.basename(filepath)}: AggroArea not found")
        return False
    
    aggro_node_end = aggro_match.end()
    
    # Ищем позицию для вставки (после AggroArea, перед следующей нодой)
    insert_pos = content.find("[node name=", aggro_node_end)
    if insert_pos == -1:
        insert_pos = len(content)
    
    # Проверяем нужно ли добавить sub_resource для CircleShape2D aggro
    shape_id = "CircleShape2D_aggro_auto"
    sub_resource_text = f'\n[sub_resource type="CircleShape2D" id="{shape_id}"]\nradius = {AGGRO_RADIUS}\n'
    
    # Находим последний sub_resource
    last_sub = content.rfind('[sub_resource')
    if last_sub == -1:
        # Вставляем после ext_resource
        last_ext = content.rfind('[ext_resource')
        if last_ext != -1:
            insert_sub_pos = content.find('\n\n', last_ext)
            if insert_sub_pos == -1:
                insert_sub_pos = content.find('\n', last_ext)
        else:
            insert_sub_pos = 0
    else:
        # Вставляем после последнего sub_resource block
        insert_sub_pos = content.find('\n\n[node', last_sub)
        if insert_sub_pos == -1:
            insert_sub_pos = content.find('\n[node', last_sub)
    
    # Добавляем sub_resource
    if f'id="{shape_id}"' not in content:
        content = content[:insert_sub_pos] + sub_resource_text + content[insert_sub_pos:]
        # Пересчитываем insert_pos для node
        insert_pos = content.find("[node name=", insert_pos + len(sub_resource_text) - 10)
        if insert_pos == -1:
            insert_pos = len(content)
    
    # Добавляем CollisionShape2D node после AggroArea
    collision_node = f'\n[node name="AggroCollision" type="CollisionShape2D" parent="AggroArea"]\nshape = SubResource("{shape_id}")\n'
    
    # Находим позицию сразу после AggroArea
    aggro_end_match = re.search(r'\[node name="AggroArea".*?(?=\n\[node)', content, re.DOTALL)
    if aggro_end_match:
        pos = aggro_end_match.end()
        content = content[:pos] + collision_node + content[pos:]
    
    # Исправляем collision_mask для AggroArea (для поиска героев - маска 1)
    content = re.sub(
        r'(\[node name="AggroArea" type="Area2D" parent="\."\])\n(collision_layer = 0\n)?(script =)',
        r'\1\ncollision_layer = 0\ncollision_mask = 1\n\3',
        content
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"  {os.path.basename(filepath)}: Fixed AggroArea with CollisionShape2D")
    return True

def main():
    print("=== Fixing AggroArea CollisionShape2D in mob scenes ===")
    
    fixed_count = 0
    for filename in os.listdir(MOB_SCENES_DIR):
        if filename.endswith('.tscn'):
            filepath = os.path.join(MOB_SCENES_DIR, filename)
            if fix_mob_scene(filepath):
                fixed_count += 1
    
    print(f"\n=== Done! Fixed {fixed_count} mob scenes ===")

if __name__ == "__main__":
    main()
