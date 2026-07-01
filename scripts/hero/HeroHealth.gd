extends RefCounted
class_name HeroOnFieldHealth

## Управление здоровьем героя
## Health bar, авто-зелья, попапы лечения

var _hero: Node2D
var _hero_id: String
var _health_bar: ProgressBar

func initialize(hero: Node2D, hero_id: String, health_bar: ProgressBar) -> void:
    _hero = hero
    _hero_id = hero_id
    _health_bar = health_bar
    
    if _health_bar:
        var fill_style = StyleBoxFlat.new()
        fill_style.bg_color = Color(0.2, 0.5, 1.0, 1.0)
        _health_bar.add_theme_stylebox_override("fill", fill_style)

func is_dead() -> bool:
    var hero_core := _get_hero_core()
    if hero_core == null:
        return false
    var live_data = hero_core.get("heroes").get(_hero_id)
    if not live_data:
        return true # No data = dead
    return float(live_data.get("hp", 0)) <= 0

func heal(amount: float) -> void:
    var hero_core := _get_hero_core()
    if hero_core != null:
        hero_core.call("heal_hero", _hero_id, int(amount))

func update_health_bar() -> void:
    var hero_core := _get_hero_core()
    if not _health_bar or hero_core == null:
        return

    var live_data = hero_core.get("heroes").get(_hero_id)
    if not live_data:
        return

    # Получаем полные статы (с учетом шмота)
    var total_stats = hero_core.call("get_hero_total_stats", _hero_id)
    var max_hp = float(total_stats.get("maxHp", 10))
    var hp = float(live_data.get("hp", 0))
    
    # Обновляем прогресс бар
    _health_bar.max_value = max_hp
    _health_bar.value = hp
    
    # Обновляем текст если есть лейбл (или создаем его если нужно)
    var label = _health_bar.get_node_or_null("HPLabel")
    if not label:
        label = Label.new()
        label.name = "HPLabel"
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.anchors_preset = Control.PRESET_FULL_RECT
        label.add_theme_font_size_override("font_size", 10)
        label.add_theme_color_override("font_outline_color", Color.BLACK)
        label.add_theme_constant_override("outline_size", 2)
        _health_bar.add_child(label)
        
    label.text = "HP: %.1f / %.1f" % [hp, max_hp]

func check_auto_potion_use() -> void:
    var hero_core := _get_hero_core()
    if hero_core == null:
        return

    var live_data = hero_core.get("heroes").get(_hero_id)
    if not live_data:
        return

    var total_stats = hero_core.call("get_hero_total_stats", _hero_id)
    var hp = float(live_data.get("hp", 0))
    var max_hp = float(total_stats.get("maxHp", 10))
    var potions = live_data.get("potions_carried", 0)
    
    # Auto-use at < 50% HP
    if hp < max_hp * 0.5 and potions > 0:
        if hero_core.call("use_potion", _hero_id):
            print("[HeroHealth] %s used a potion! HP: %.1f/%.1f" % [_hero_id, live_data.get("hp"), max_hp])

func on_hero_healed(healed_hero_id: String, amount: int) -> void:
    if healed_hero_id != _hero_id:
        return

    # Показываем попап только для активных героев (использовали зелье)
    var hero_core := _get_hero_core()
    if hero_core == null:
        return
    var live_data = hero_core.get("heroes").get(_hero_id)
    if live_data and live_data.get("isActive", false):
        var popup_scene = load("res://scenes/ui/overlays/HealingPopup.tscn")
        if popup_scene:
            var popup = popup_scene.instantiate()
            _hero.get_parent().add_child(popup)
            popup.global_position = _hero.global_position + Vector2(0, -20)
            if popup.has_method("setup"):
                popup.setup(amount)

func _get_hero_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("HeroCore")
