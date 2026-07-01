extends RefCounted
class_name GameSceneSignals

## Управление сигналами GameScene
## Подключение всех EventBus и HeroCore сигналов

var _game_scene: Node2D
var _hero_bar: Control
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

func initialize(game_scene: Node2D, hero_bar: Control, hero_card: Control) -> void:
    _game_scene = game_scene
    _hero_bar = hero_bar
    _hero_card = hero_card

func connect_signals() -> void:
    var event_bus := _get_singleton("EventBus")
    if event_bus != null:
        if event_bus.has_signal("stage_changed") and not event_bus.stage_changed.is_connected(_game_scene._on_stage_changed_event):
            event_bus.stage_changed.connect(_game_scene._on_stage_changed_event)
        if event_bus.has_signal("hero_auto_replaced") and not event_bus.hero_auto_replaced.is_connected(_game_scene._on_hero_auto_replaced):
            event_bus.hero_auto_replaced.connect(_game_scene._on_hero_auto_replaced)
    
    if _hero_bar and _hero_card:
        if _hero_bar.has_signal("hero_selected"):
            _hero_bar.hero_selected.connect(_hero_card._on_hero_selected)
    
    var hero_core := _get_singleton("HeroCore")
    if hero_core != null and hero_core.has_signal("squad_changed") and not hero_core.squad_changed.is_connected(_game_scene._on_squad_changed):
        hero_core.squad_changed.connect(_game_scene._on_squad_changed)
    if event_bus != null and event_bus.has_signal("hero_died") and not event_bus.hero_died.is_connected(_game_scene._on_hero_died):
        event_bus.hero_died.connect(_game_scene._on_hero_died)
