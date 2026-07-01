extends RefCounted
class_name GameSceneDebug

## Отладочные функции GameScene
## Тестовые функции, дебаг-сообщения

const FloatingTextScene: PackedScene = preload("res://scenes/ui/overlays/FloatingText.tscn")
const GameSceneSpellsScript = preload("res://scripts/game_scene/GameSceneSpells.gd")

var _game_scene: Node2D
var _hero_card: Control

func _get_singleton(node_name: String) -> Node:
    if _game_scene == null or not is_instance_valid(_game_scene):
        return null
    if not _game_scene.is_inside_tree():
        return null
    var tree := _game_scene.get_tree()
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null(node_name)

func initialize(game_scene: Node2D, hero_card: Control) -> void:
    _game_scene = game_scene
    _hero_card = hero_card


## Instantiate and attach the debug spawn menu.  Called before modules are ready,
## so this is a static helper that only needs a parent node.
static func setup_debug_menu(parent: Node) -> void:
    var debug_menu_scene = load("res://scenes/ui/debug/DebugSpawnMenu.tscn")
    if debug_menu_scene:
        var debug_menu = debug_menu_scene.instantiate()
        parent.add_child(debug_menu)
        print("[GameScene] Debug menu added (F10 to toggle)")

func handle_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_X:
            _handle_tavern_buff()
        elif event.keycode == KEY_N:
            _deal_damage_to_castle(1)
        elif event.keycode == KEY_Z:
            _apply_test_buff_and_mana()
        elif event.keycode == KEY_K:
            if _game_scene and _game_scene.has_method("spawn_homeseeker_boss"):
                _game_scene.spawn_homeseeker_boss()
        elif event.keycode == KEY_L:
            if _game_scene and _game_scene.has_method("spawn_minotaur_boss"):
                _game_scene.spawn_minotaur_boss()
        elif event.keycode == KEY_B:
            if _game_scene and _game_scene.has_method("spawn_goblin_bandit"):
                _game_scene.spawn_goblin_bandit()
        elif event.keycode == KEY_DELETE:
            _kill_selected_hero()
        elif event.keycode == KEY_Q:
            _cast_debug_meteorite()


func _move_to_crypt() -> void:
    var stage_core := _get_singleton("StageCore")
    if stage_core != null:
        # We need to set max_stage_reached to at least 81 to allow teleporting
        if stage_core.get_max_stage_reached() < 81:
            stage_core._max_stage_reached = 81
        
        stage_core.set_stage(81)
        show_debug_message("Moved to Crypt (Stage 81)")
    else:
        show_debug_message("StageCore not found!")

func _handle_tavern_buff() -> void:
    var hero_to_buff: String = ""
    if _hero_card:
        hero_to_buff = _hero_card.selected_hero_id
    var hero_core := _get_singleton("HeroCore")
    if hero_to_buff == "" or hero_core == null or not hero_core.heroes.has(hero_to_buff):
        show_debug_message("Select hero first to buff")
        return
    
    var economy_core := _get_singleton("EconomyCore")
    if economy_core != null:
        economy_core.add_test_base_damage(100.0)
        economy_core.add_gold(10000.0)
    var resource_core := _get_singleton("ResourceCore")
    if resource_core != null:
        resource_core.add_resource("wood", 1000)
        resource_core.add_resource("clay", 1000)

    
    var buff_stats = {
        "damage_bonus_percent": 0.20,
        "damage_reduction_percent": 0.15,
        "instant_heal_percent": 0.10
    }
    hero_core.add_buff(hero_to_buff, "good_rest", 3, buff_stats)
    
    # Обновить UI
    var tree = _game_scene.get_tree()
    if is_instance_valid(tree):
        var main_ui: Node = null
        if tree.current_scene:
            main_ui = tree.current_scene.get_node_or_null("UILayer/MainUI")
        if main_ui == null:
            main_ui = tree.get_first_node_in_group("main_ui")
        if main_ui and main_ui.has_method("_update_all_display"):
            main_ui._update_all_display()
    
    # Обновить HeroCard для отображения баффа
    if _hero_card and _hero_card.has_method("update_display"):
        _hero_card.update_display()
    
    show_debug_message("Tavern buff applied to %s" % hero_to_buff)

func _kill_selected_hero() -> void:
    var hero_to_kill: String = ""
    if _hero_card:
        hero_to_kill = _hero_card.selected_hero_id
    var hero_core := _get_singleton("HeroCore")
    if hero_to_kill == "" or hero_core == null or not hero_core.heroes.has(hero_to_kill):
        show_debug_message("Select hero first to kill")
        return
    hero_core.mark_hero_dead(hero_to_kill)
    show_debug_message("Killed hero %s" % hero_to_kill)

func _apply_test_buff_and_mana() -> void:
    _apply_test_buff()
    
    # Добавляем все ресурсы
    var economy_core := _get_singleton("EconomyCore")
    if economy_core != null:
        economy_core.add_gold(100000.0)
    
    var resource_core := _get_singleton("ResourceCore")
    if resource_core != null:
        for res_id in resource_core.RESOURCE_IDS:
            resource_core.add_resource(res_id, 1000)
            
    # Food system removed from KoW resource system
        
    show_debug_message("Applied test buff + restored mana + ALL RESOURCES")

func _apply_test_buff() -> void:
    var hero_core := _get_singleton("HeroCore")
    if hero_core == null:
        return
    
    var all_heroes = hero_core.heroes.keys()
    if all_heroes.is_empty():
        return
    
    var random_hero_id = all_heroes[randi() % all_heroes.size()]
    var buff_stats = {
        "damage_bonus_percent": 0.20,
        "damage_reduction_percent": 0.15,
        "instant_heal_percent": 0.10
    }
    
    hero_core.add_buff(random_hero_id, "good_rest", 3, buff_stats)
    print("[GameSceneDebug] Applied test buff to hero: %s" % random_hero_id)

func _deal_damage_to_castle(damage: int) -> void:
    var castle_core := _get_singleton("CastleCore")
    if castle_core == null:
        show_debug_message("CastleCore not found")
        return
    
    castle_core.take_damage(damage)
    show_debug_message("Castle took %d damage" % damage)

func show_debug_message(msg: String) -> void:
    var label = Label.new()
    label.text = msg
    label.add_theme_font_size_override("font_size", 32)
    label.add_theme_color_override("font_color", Color.YELLOW)
    
    label.position = _game_scene.get_viewport().get_visible_rect().size / 2
    label.anchor_left = 0.5
    label.anchor_right = 0.5
    label.anchor_top = 0.5
    label.anchor_bottom = 0.5
    label.pivot_offset = Vector2(label.size.x / 2, label.size.y / 2)
    
    _game_scene.add_child(label)
    
    await _game_scene.get_tree().create_timer(2.0).timeout
    if is_instance_valid(label):
        label.queue_free()

func _cast_debug_meteorite() -> void:
    if not _game_scene:
        return
    
    # Load meteorite config
    var meteorite_config = load("res://resources/spells/configs/meteorite.tres")
    if not meteorite_config:
        show_debug_message("Meteorite config not found")
        return
    
    var target_pos := _game_scene.get_global_mouse_position()
    
    # Use the real spell pipeline so damage multipliers are applied correctly.
    # GameSceneSpells.cast_spell() is a static method that reads ArtifactCore
    # and BuildingUpgradeCore multipliers through the full pipeline.
    var success := GameSceneSpellsScript.cast_spell(_game_scene, meteorite_config, target_pos)
    if success:
        show_debug_message("Meteorite cast at mouse position (Q key)")
    else:
        show_debug_message("Meteorite cast failed")

func _on_damage_dealt(position: Vector2, damage: float) -> void:
    _show_floating_damage(position, damage)

func _show_floating_damage(position: Vector2, damage: float) -> void:
    if _game_scene == null or not is_instance_valid(_game_scene):
        return

    var popup_parent: Node = _game_scene.get_node_or_null("WorldYSort")
    if popup_parent == null:
        popup_parent = _game_scene

    if FloatingTextScene != null:
        var popup := FloatingTextScene.instantiate()
        if popup is FloatingText:
            var floating := popup as FloatingText
            floating.set("_fade_duration", 3.0)
            popup_parent.add_child(floating)
            floating.global_position = position
            floating.setup("%.0f" % damage, Color.YELLOW, 40)
            return

    var label_root := Node2D.new()
    var label := Label.new()
    label_root.add_child(label)
    label.text = "%.0f" % damage
    label.add_theme_font_size_override("font_size", 40)
    label.add_theme_color_override("font_color", Color.YELLOW)
    label.add_theme_color_override("font_outline_color", Color.BLACK)
    label.add_theme_constant_override("outline_size", 2)
    popup_parent.add_child(label_root)
    label_root.global_position = position

    var tween = _game_scene.create_tween()
    tween.set_parallel(true)
    tween.set_trans(Tween.TRANS_LINEAR)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(label_root, "global_position:y", position.y - 80, 3.0)
    tween.tween_property(label_root, "modulate:a", 0.0, 3.0)
    await tween.finished
    if is_instance_valid(label_root):
        label_root.queue_free()
