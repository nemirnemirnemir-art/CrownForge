extends RefCounted
class_name HeroOnFieldVisuals

## Handles visual-related logic for HeroOnField (selection outlines, hurtbox tooltips)

var hero: Node2D
var hero_id: String = ""
var animation_sprite: AnimatedSprite2D = null

const UnitSelectionOutlineScene: PackedScene = preload("res://scenes/ui/widgets/UnitSelectionOutline.tscn")
var _selection_outline: Node2D = null
var _selection_outline_back: CanvasItem = null
var _selection_outline_front: CanvasItem = null

static var _cached_generic_death_frames: SpriteFrames = null

func setup(hero_ref: Node2D, id: String) -> void:
    hero = hero_ref
    hero_id = id
    
    animation_sprite = hero.get_node_or_null("AnimationSprite2D")
    if not animation_sprite: animation_sprite = hero.get_node_or_null("AnimWalk")
    if not animation_sprite: animation_sprite = hero.get_node_or_null("AnimatedSprite2D")
    
    var health_bar = hero.get_node_or_null("HealthBar")
    if health_bar: health_bar.visible = false
    
    if animation_sprite:
        animation_sprite.visible = true

    _setup_selection_outline()
    _connect_selection_signals()
    _setup_hurtbox()
    _ensure_anim_dead()

func ensure_anim_dead(_hero: Node2D) -> void:
    hero = _hero if hero == null else hero
    _ensure_anim_dead()

func _setup_selection_outline() -> void:
    _selection_outline_back = hero.get_node_or_null("SelectionOutlineBack")
    _selection_outline_front = hero.get_node_or_null("SelectionOutlineFront")
    if _selection_outline_back or _selection_outline_front:
        if _selection_outline_back: _selection_outline_back.visible = false
        if _selection_outline_front: _selection_outline_front.visible = false
        return
    
    if _selection_outline != null and is_instance_valid(_selection_outline):
        return
    if UnitSelectionOutlineScene == null:
        return
    _selection_outline = UnitSelectionOutlineScene.instantiate() as Node2D
    if _selection_outline == null:
        return
    hero.add_child(_selection_outline)
    _selection_outline.visible = false

func _connect_selection_signals() -> void:
    var tree := hero.get_tree()
    var event_bus = _get_event_bus(tree)
    if event_bus == null:
        return
    if not event_bus.has_signal("hero_selected_for_ui"):
        return
    var cb := Callable(self, "_on_hero_selected_for_ui")
    if not event_bus.hero_selected_for_ui.is_connected(cb):
        event_bus.hero_selected_for_ui.connect(cb)

func _on_hero_selected_for_ui(selected_hero_id: String) -> void:
    var current_hero_id := _get_current_hero_id()
    var should_show := (current_hero_id != "" and selected_hero_id == current_hero_id)
    if _selection_outline_back or _selection_outline_front:
        if _selection_outline_back: _selection_outline_back.visible = should_show
        if _selection_outline_front: _selection_outline_front.visible = should_show
        return
    if _selection_outline == null or not is_instance_valid(_selection_outline):
        return
    _selection_outline.visible = should_show

func sync_selection_outline_flip() -> void:
    if _selection_outline_back == null and _selection_outline_front == null:
        return
    var main_flip := false
    if animation_sprite and is_instance_valid(animation_sprite):
        main_flip = animation_sprite.flip_h
    elif hero.get_node_or_null("AnimWalk") is AnimatedSprite2D:
        main_flip = (hero.get_node("AnimWalk") as AnimatedSprite2D).flip_h
    else:
        return
    if _selection_outline_back and is_instance_valid(_selection_outline_back):
        if _selection_outline_back.flip_h != main_flip:
            _selection_outline_back.flip_h = main_flip
    if _selection_outline_front and is_instance_valid(_selection_outline_front):
        if _selection_outline_front.flip_h != main_flip:
            _selection_outline_front.flip_h = main_flip

func _setup_hurtbox() -> void:
    var hurtbox := hero.get_node_or_null("Hurtbox")
    if hurtbox:
        hurtbox.input_pickable = true
        if not hurtbox.mouse_entered.is_connected(_on_hurtbox_mouse_enter):
            hurtbox.mouse_entered.connect(_on_hurtbox_mouse_enter)
        if not hurtbox.mouse_exited.is_connected(_on_hurtbox_mouse_exit):
            hurtbox.mouse_exited.connect(_on_hurtbox_mouse_exit)
        if not hurtbox.input_event.is_connected(_on_hurtbox_input_event):
            hurtbox.input_event.connect(_on_hurtbox_input_event)

func _on_hurtbox_mouse_enter() -> void:
    var ui: Node = null
    var tree := hero.get_tree()
    if tree and tree.current_scene:
        ui = tree.current_scene.get_node_or_null("UILayer/MainUI")
    if ui == null and tree:
        ui = tree.get_first_node_in_group("main_ui")
    if ui and ui.has_method("show_hero_hp_tooltip"):
        ui.show_hero_hp_tooltip(hero)

func _on_hurtbox_mouse_exit() -> void:
    var ui: Node = null
    var tree := hero.get_tree()
    if tree and tree.current_scene:
        ui = tree.current_scene.get_node_or_null("UILayer/MainUI")
    if ui == null and tree:
        ui = tree.get_first_node_in_group("main_ui")
    if ui and ui.has_method("hide_hero_hp_tooltip"):
        ui.hide_hero_hp_tooltip(hero)

func _on_hurtbox_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
            var tree := hero.get_tree()
            var event_bus = _get_event_bus(tree)
            var current_hero_id := _get_current_hero_id()
            if event_bus and event_bus.has_signal("hero_selected_for_ui") and current_hero_id != "":
                event_bus.hero_selected_for_ui.emit(current_hero_id)

func _get_event_bus(tree: SceneTree) -> Node:
    if tree == null:
        return null
    var root := tree.root
    if root == null:
        return null
    var direct_node := root.get_node_or_null("EventBus")
    if direct_node != null:
        return direct_node
    return root.get_node_or_null("/root/EventBus")

func _get_current_hero_id() -> String:
    if hero != null:
        var live_id := String(hero.get("hero_id"))
        if live_id != "":
            return live_id
    return hero_id

func _ensure_anim_dead() -> void:
    var dead_node := hero.get_node_or_null("AnimDead") as AnimatedSprite2D
    if dead_node: return
    
    var walk_node = animation_sprite
    dead_node = AnimatedSprite2D.new()
    dead_node.name = "AnimDead"
    dead_node.visible = false
    if walk_node:
        dead_node.position = walk_node.position
        dead_node.scale = walk_node.scale
        dead_node.offset = walk_node.offset
        dead_node.flip_h = walk_node.flip_h

    if _cached_generic_death_frames == null:
        var eff_scene: PackedScene = preload("res://scenes/effects/DeathEffect.tscn")
        var inst: Node = eff_scene.instantiate()
        var spr: AnimatedSprite2D = inst.get_node_or_null("AnimatedSprite2D")
        if spr and spr.sprite_frames:
            _cached_generic_death_frames = spr.sprite_frames
    
    if _cached_generic_death_frames:
        dead_node.sprite_frames = _cached_generic_death_frames
        if dead_node.sprite_frames.has_animation("default"):
            dead_node.animation = "default"
    hero.add_child(dead_node)
