import sys
import re

file_path = 'scripts/game/GameScene.gd'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace MapLayout initialization in _initialize_modules
old_map_init = '''        print(\"[GameScene] MapLayout initialized. Portal: %v, Bridge: %v\" % [
            MapMarkerService.get_portal_position(), 
            MapMarkerService.get_bridge_position()
        ])'''
new_map_init = '''        print(\"[GameScene] MapLayout initialized. Portal: %v, Bridge: %v\" % [
            MapMarkerService.get_portal_position(), 
            MapMarkerService.get_bridge_position()
        ])
        
        _building_drag_manager = GameSceneBuildingDrag.new()
        _building_drag_manager.initialize(self, map_layout_node)
        
        _slot_hover_manager = GameSceneSlotHover.new()
        _slot_hover_manager.initialize(map_layout_node)'''
content = content.replace(old_map_init, new_map_init)

# Prophecy / Encounter Pause
content = content.replace('_release_prophecy_pause_state()', '_pause_state_manager.release_prophecy_pause()')
content = content.replace('_apply_encounter_pause_state()', '_pause_state_manager.apply_encounter_pause()')
content = content.replace('_prophecy_pause_applied = false', '_pause_state_manager.set_prophecy_pause_applied(false)')
content = content.replace('_release_encounter_pause_state()', '_pause_state_manager.release_encounter_pause()')

# Delete old pause state functions
pause_pattern = re.compile(r'func _apply_prophecy_pause_state\(\) -> void:.*?_encounter_pause_applied = false\n\n', re.DOTALL)
content = pause_pattern.sub('', content)

# _get_release_wave_interval to just pass through, no need to touch

# Remove old variables for hover and drag
vars_pattern = re.compile(r'var _selected_building_id: String = \"\"[\s\S]*?var _slot_hover_last_real_time_msec: int = 0\n', re.DOTALL)
content = vars_pattern.sub('', content)

# Process function modifications
old_process = '''    var unscaled_hover_delta := _consume_slot_hover_unscaled_delta()
    var is_paused_now: bool = _is_effectively_paused()
    if is_paused_now:
        if _ghost_building:
            _ghost_building.global_position = get_global_mouse_position()
            _clear_slot_hover_state()
        else:
            _update_slot_hover_tooltip_paused(unscaled_hover_delta)
        return

    _heroes_manager.check_dead_heroes_cleanup()
    
    if _ghost_building:
        _ghost_building.global_position = get_global_mouse_position()
        
        var target_slot = _find_slot_at_mouse()
        if target_slot:
            _ghost_building.modulate = Color(1, 1, 1, 0.8)
        else:
            _ghost_building.modulate = Color(1, 1, 1, 0.5)
        _clear_slot_hover_state()
    else:
        _update_slot_hover_tooltip(delta)'''

new_process = '''    var unscaled_hover_delta := 0.0
    if _slot_hover_manager:
        unscaled_hover_delta = _slot_hover_manager.consume_unscaled_delta()
    var is_paused_now: bool = _pause_state_manager.is_effectively_paused() if _pause_state_manager else false
    if is_paused_now:
        if _building_drag_manager and _building_drag_manager.has_ghost():
            _building_drag_manager.update_ghost_position()
            if _slot_hover_manager:
                _slot_hover_manager.clear_hover_state()
        else:
            if _slot_hover_manager:
                _slot_hover_manager.update_tooltip_paused(self, unscaled_hover_delta)
        return

    _heroes_manager.check_dead_heroes_cleanup()
    
    if _building_drag_manager and _building_drag_manager.has_ghost():
        _building_drag_manager.update_ghost_position()
        if _slot_hover_manager:
            _slot_hover_manager.clear_hover_state()
    else:
        if _slot_hover_manager:
            _slot_hover_manager.update_tooltip(self, delta)'''
content = content.replace(old_process, new_process)

# Update drag handlers
content = content.replace('''func _on_building_drag_started(building_id: String) -> void:
    _source_slot_index = -1 # New construction
    _start_drag(building_id)

func _on_building_move_started(slot_index: int, building_id: String) -> void:
    _source_slot_index = slot_index
    _start_drag(building_id)
    # Visual feedback: hide building in source slot
    if map_layout_node and slot_index < map_layout_node.slots.size():
        map_layout_node.slots[slot_index].sprite.modulate.a = 0.2''', '''func _on_building_drag_started(building_id: String) -> void:
    if _building_drag_manager:
        _building_drag_manager.on_drag_started(building_id)

func _on_building_move_started(slot_index: int, building_id: String) -> void:
    if _building_drag_manager:
        _building_drag_manager.on_move_started(slot_index, building_id)''')

drag_funcs = re.compile(r'func _start_drag\(building_id: String\) -> void:.*?func _find_slot_at_mouse\(allow_occupied: bool = false\) -> MapSlot:\n[ \t]*var mouse_pos = get_global_mouse_position\(\)\n[ \t]*if map_layout_node:\n[ \t]*for slot in map_layout_node.slots:\n[ \t]*if not slot.is_building_slot:\n[ \t]*continue\n[ \t]*if not allow_occupied and slot.current_building_id != \"\":\n[ \t]*continue\n[ \t]*var slot_pos = slot.global_position\n[ \t]*# Using a slightly larger area for easier dropping\n[ \t]*var rect = Rect2\(slot_pos - Vector2\(50, 50\), Vector2\(100, 100\)\)\n[ \t]*if rect.has_point\(mouse_pos\):\n[ \t]*return slot\n[ \t]*return null', re.DOTALL)

def replace_drag_funcs(match):
    return '''func _handle_building_drop() -> void:
    if _building_drag_manager:
        _building_drag_manager.handle_drop(building_menu)'''

content = drag_funcs.sub(replace_drag_funcs, content)

# Remove slot hover functions
hover_funcs = re.compile(r'func _update_slot_hover_tooltip\(delta: float\) -> void:.*?return false\n\nfunc _is_effectively_paused', re.DOTALL)
content = hover_funcs.sub('func _is_effectively_paused', content)
content = content.replace('func _is_effectively_paused() -> bool:\n    var tree: SceneTree = get_tree()\n    if tree and tree.paused:\n        return true\n    if TickManager:\n        return float(TickManager.speed_scale) <= PAUSE_SPEED_EPSILON\n    return false', '')


# Reward Menus updates
old_rewards = '''func open_reward_menu_base_production() -> void:
    if not reward_menu_base_production:
        return
    if reward_menu_base_production.visible:
        return
    reward_menu_base_production.open()

func open_reward_menu_established_production() -> void:
    if not reward_menu_established_production:
        return
    if reward_menu_established_production.visible:
        return
    reward_menu_established_production.building_category = int(BuildingConfig.BuildingCategory.ESTABLISHED_PRODUCTION)
    reward_menu_established_production.menu_title = "Choose established production building"
    reward_menu_established_production.open()

func open_reward_menu_advanced_production() -> void:
    if not reward_menu_established_production:
        return
    if reward_menu_established_production.visible:
        return
    reward_menu_established_production.building_category = int(BuildingConfig.BuildingCategory.ADVANCED_PRODUCTION)
    reward_menu_established_production.menu_title = "Choose advanced production building"
    reward_menu_established_production.open()

func open_reward_menu_kingdom_infrastructure() -> void:
    if not reward_menu_kingdom_infrastructure:
        return
    if reward_menu_kingdom_infrastructure.visible:
        return
    reward_menu_kingdom_infrastructure.open()

func open_reward_menu_levy_barracks() -> void:
    if not reward_menu_levy_barracks:
        return
    if reward_menu_levy_barracks.visible:
        return
    reward_menu_levy_barracks.building_category = int(BuildingConfig.BuildingCategory.LEVY_BARRACKS)
    reward_menu_levy_barracks.menu_title = "Choose a levy barracks building"
    reward_menu_levy_barracks.open()

func open_reward_menu_veteran_barracks() -> void:
    if not reward_menu_levy_barracks:
        return
    if reward_menu_levy_barracks.visible:
        return
    reward_menu_levy_barracks.building_category = int(BuildingConfig.BuildingCategory.VETERAN_BARRACKS)
    reward_menu_levy_barracks.menu_title = "Choose a veteran barracks building"
    reward_menu_levy_barracks.open()

func open_reward_menu_elite_barracks() -> void:
    if not reward_menu_levy_barracks:
        return
    if reward_menu_levy_barracks.visible:
        return
    reward_menu_levy_barracks.building_category = int(BuildingConfig.BuildingCategory.ELITE_BARRACKS)
    reward_menu_levy_barracks.menu_title = "Choose an elite barracks building"
    reward_menu_levy_barracks.open()

func open_reward_menu_artifacts() -> void:
    if not reward_menu_artifacts:
        return
    if reward_menu_artifacts.visible:
        return
    reward_menu_artifacts.open()

func open_reward_menu_troop_bonuses() -> void:
    if not reward_menu_troop_bonuses:
        return
    if reward_menu_troop_bonuses.visible:
        return
    reward_menu_troop_bonuses.open()

func open_reward_menu_building_upgrades() -> void:
    if not reward_menu_building_upgrades:
        return
    if reward_menu_building_upgrades.visible:
        return
    reward_menu_building_upgrades.open()

func open_reward_menu_resources(amount: int = 0) -> void:
    if not reward_menu_resources:
        return
    if reward_menu_resources.visible:
        return
    reward_menu_resources.open(amount)

func open_reward_menu_spells() -> void:
    if not reward_menu_spells:
        return
    if reward_menu_spells.visible:
        return
    reward_menu_spells.legendary_only = false
    reward_menu_spells.open()

func open_reward_menu_legendary_spells() -> void:
    if not reward_menu_legendary_spells:
        return
    if reward_menu_legendary_spells.visible:
        return
    reward_menu_legendary_spells.legendary_only = true
    reward_menu_legendary_spells.open()

func open_reward_menu_trader() -> void:
    if not reward_menu_trader:
        return
    if reward_menu_trader.visible:
        return
    reward_menu_trader.open()

func open_reward_menu_prophecy() -> void:
    if not prophecy_menu:
        return
    if prophecy_menu.visible:
        _pending_open_prophecy = false
        return
    _pending_open_prophecy = false
    _apply_prophecy_pause_state()
    if _waves_manager:
        _waves_manager.set_paused(true)
    var lvl: int = 1
    var locked_slots: int = 0
    if _waves_manager and _waves_manager.has_method("get_prophecy_level"):
        lvl = int(_waves_manager.get_prophecy_level())
    if _waves_manager and _waves_manager.has_method("get_locked_prophecy_slot_count"):
        locked_slots = int(_waves_manager.get_locked_prophecy_slot_count())
    prophecy_menu.open(prophecy_pattern_pool, lvl, locked_slots)'''

new_rewards = '''func open_reward_menu_base_production() -> void:
    if _reward_menus_manager:
        _reward_menus_manager.open_base_production()

func open_reward_menu_established_production() -> void:
    if reward_menu_established_production:
        reward_menu_established_production.building_category = int(BuildingConfig.BuildingCategory.ESTABLISHED_PRODUCTION)
        reward_menu_established_production.menu_title = "Choose established production building"
        if not reward_menu_established_production.visible:
            reward_menu_established_production.open()

func open_reward_menu_advanced_production() -> void:
    if reward_menu_established_production:
        reward_menu_established_production.building_category = int(BuildingConfig.BuildingCategory.ADVANCED_PRODUCTION)
        reward_menu_established_production.menu_title = "Choose advanced production building"
        if not reward_menu_established_production.visible:
            reward_menu_established_production.open()

func open_reward_menu_kingdom_infrastructure() -> void:
    if reward_menu_kingdom_infrastructure and not reward_menu_kingdom_infrastructure.visible:
        reward_menu_kingdom_infrastructure.open()

func open_reward_menu_levy_barracks() -> void:
    if reward_menu_levy_barracks:
        reward_menu_levy_barracks.building_category = int(BuildingConfig.BuildingCategory.LEVY_BARRACKS)
        reward_menu_levy_barracks.menu_title = "Choose a levy barracks building"
        if _reward_menus_manager:
            _reward_menus_manager.open_levy_barracks()

func open_reward_menu_veteran_barracks() -> void:
    if reward_menu_levy_barracks:
        reward_menu_levy_barracks.building_category = int(BuildingConfig.BuildingCategory.VETERAN_BARRACKS)
        reward_menu_levy_barracks.menu_title = "Choose a veteran barracks building"
        if _reward_menus_manager:
            _reward_menus_manager.open_levy_barracks()

func open_reward_menu_elite_barracks() -> void:
    if reward_menu_levy_barracks:
        reward_menu_levy_barracks.building_category = int(BuildingConfig.BuildingCategory.ELITE_BARRACKS)
        reward_menu_levy_barracks.menu_title = "Choose an elite barracks building"
        if _reward_menus_manager:
            _reward_menus_manager.open_levy_barracks()

func open_reward_menu_artifacts() -> void:
    if _reward_menus_manager:
        _reward_menus_manager.open_artifacts()

func open_reward_menu_troop_bonuses() -> void:
    if _reward_menus_manager:
        _reward_menus_manager.open_troop_bonuses()

func open_reward_menu_building_upgrades() -> void:
    if _reward_menus_manager:
        _reward_menus_manager.open_building_upgrades()

func open_reward_menu_resources(amount: int = 0) -> void:
    if _reward_menus_manager:
        _reward_menus_manager.open_resources(amount)

func open_reward_menu_spells() -> void:
    if _reward_menus_manager:
        _reward_menus_manager.open_spells()

func open_reward_menu_legendary_spells() -> void:
    if _reward_menus_manager:
        _reward_menus_manager.open_legendary_spells()

func open_reward_menu_trader() -> void:
    if _reward_menus_manager:
        _reward_menus_manager.open_trader()

func open_reward_menu_prophecy() -> void:
    if _reward_menus_manager and _pause_state_manager:
        var opened = _reward_menus_manager.open_prophecy(_pause_state_manager, _pending_open_prophecy)
        if opened:
            _pending_open_prophecy = false'''

content = content.replace(old_rewards, new_rewards)

# Update _input
old_input = '''    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
            if _ghost_building:
                _handle_building_drop()'''
new_input = '''    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
            if _building_drag_manager and _building_drag_manager.has_ghost():
                _handle_building_drop()'''
content = content.replace(old_input, new_input)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
