extends RefCounted
class_name GameSceneInputController

## Handles raw input events and building/spell interaction signals for GameScene.
## Spell state vars (_active_spell_config, _spell_targeting_active, _targeting_circle)
## intentionally remain on GameScene because GameSceneSpells accesses them as typed properties.

const GameSceneSpellsScript = preload("res://scripts/game_scene/GameSceneSpells.gd")

var _scene = null


func initialize(scene) -> void:
    _scene = scene


func _is_text_input_focused() -> bool:
    if _scene == null:
        return false
    var viewport: Viewport = _scene.get_viewport()
    if viewport == null:
        return false
    var focus_owner: Control = viewport.gui_get_focus_owner()
    return focus_owner is LineEdit or focus_owner is TextEdit


func handle_input(event: InputEvent) -> void:
    if event is InputEventKey and _is_text_input_focused():
        return

    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_G:
            _scene.open_town_menu()
            _scene.get_viewport().set_input_as_handled()
            return

    if not _scene.release_mode_enabled:
        _scene._debug_manager.handle_input(event)

    if (not _scene.release_mode_enabled) and event is InputEventKey and event.pressed:
        if event.keycode == KEY_E and not event.echo:
            if _scene._debug_building_upgrades_module:
                _scene._debug_building_upgrades_module.unlock_all_available_upgrades()
            _scene.get_viewport().set_input_as_handled()
            return
        if event.keycode == KEY_R and not event.echo:
            if _scene._debug_building_upgrades_module:
                _scene._debug_building_upgrades_module.unlock_all_upgrades_in_game()
            _scene.get_viewport().set_input_as_handled()
            return
        if event.keycode == KEY_P and not event.echo:
            _scene.open_reward_menu_base_production()
            _scene.get_viewport().set_input_as_handled()
            return
        if event.keycode == KEY_T and not event.echo:
            _scene.open_reward_menu_trader()
            _scene.get_viewport().set_input_as_handled()
            return
        if event.keycode == KEY_C:
            print("[GameScene] Debug: Adding 7 hero types (1 each)")
            var base_ids: Array[String] = [
                "peasant",
                "peasant",
                "slinger",
                "crossbowman",
                "swordsman",
                "militia",
                "small_bones"
            ]
            var hero_core = _get_hero_core()
            if hero_core == null:
                return
            for base_id in base_ids:
                var new_id = hero_core.hire_hero_copy(base_id)
                if new_id != "":
                    hero_core.add_to_squad(new_id)
                    # squad_changed signal will trigger update_heroes_on_field automatically

    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            if _scene._building_drag_manager and _scene._building_drag_manager.has_ghost():
                _scene._building_drag_manager.cancel_drag()
                if _scene.building_menu and _scene.building_menu.has_method("clear_selection"):
                    _scene.building_menu.clear_selection()
                _scene.get_viewport().set_input_as_handled()
                return
        if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
            if _scene._building_drag_manager and _scene._building_drag_manager.has_ghost():
                handle_building_drop()


# --- Building interaction handlers ---

func on_building_drag_started(building_id: String) -> void:
    if _scene._building_drag_manager:
        _scene._building_drag_manager.on_drag_started(building_id)


func on_building_move_started(slot_index: int, building_id: String) -> void:
    if _scene._building_drag_manager:
        _scene._building_drag_manager.on_move_started(slot_index, building_id)


func on_building_selected(building_id: String) -> void:
    if _scene._building_drag_manager:
        _scene._building_drag_manager.on_drag_started(building_id)


func on_slot_clicked(_slot_index: int) -> void:
    pass


func handle_building_drop() -> void:
    if _scene._building_drag_manager:
        _scene._building_drag_manager.handle_drop(_scene.building_menu)


# --- Spell interaction handlers ---

func on_spell_targeting_started(config: SpellConfig) -> void:
    GameSceneSpellsScript.start_targeting(_scene, config)


func on_spell_cast_requested(config: SpellConfig, _viewport_pos: Vector2) -> void:
    var world_pos: Vector2 = _scene.get_global_mouse_position()
    GameSceneSpellsScript.cast_spell(_scene, config, world_pos)


func on_spell_targeting_cancelled() -> void:
    GameSceneSpellsScript.clear_targeting(_scene)


func _get_hero_core():
    if _scene == null:
        return null
    var tree: SceneTree = _scene.get_tree()
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("HeroCore")
