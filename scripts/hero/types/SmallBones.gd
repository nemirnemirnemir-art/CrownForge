extends CharacterBody2D

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const HeroAssetLoaderScript := preload("res://scripts/utils/HeroAssetLoader.gd")
const HeroSelectionOutlineScript := preload("res://scripts/hero/shared/HeroSelectionOutline.gd")
const HeroHurtboxUIScript := preload("res://scripts/hero/shared/HeroHurtboxUI.gd")
const HeroAnimationHelperScript := preload("res://scripts/hero/shared/HeroAnimationHelper.gd")
const FriendlyDamageBlockHelperScript := preload("res://scripts/hero/shared/FriendlyDamageBlockHelper.gd")

## Small Bones - temporary skeleton summoned by Necromancy spell
## Now uses full hero system (state machine + components) instead of custom AI

## Preload state classes
const HeroIdleState = preload("res://scripts/hero/states/HeroIdleState.gd")
const HeroAttackingState = preload("res://scripts/hero/states/HeroAttackingState.gd")
const HeroMovingToCombatState = preload("res://scripts/hero/states/HeroMovingToCombatState.gd")
const HeroDeathState = preload("res://scripts/hero/states/HeroDeathState.gd")

@onready var anim_walk: AnimatedSprite2D = $AnimWalk
@onready var anim_attack: AnimatedSprite2D = $AnimAttack
@onready var health_bar: ProgressBar = $HealthBar
@onready var radial_timer: Sprite2D = $RadialTimer
@onready var aggro_area: Area2D = $AggroArea
@onready var hurtbox_component: Area2D = $Hurtbox
@onready var hitbox_component: Area2D = $Hitbox

var _selection_outline_helper: RefCounted = null
var _hurtbox_ui_helper: RefCounted = null
var _animation_helper: RefCounted = null

## --- Hero System Compatibility Properties (Mandatory for HeroStates) ---
var hero_id: String = ""  # Empty = not in HeroCore (summon)
var is_summon: bool = true
var current_target: Node2D = null
var is_dead: bool = false
var attack_range: float = 35.0
var max_range: float = 35.0
var attack_cooldown: float = 1.0
var is_melee: bool = true
var move_speed: float = 80.0
var projectile_scene: PackedScene = null
var damage_taken_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var evasion_chance: float = 0.0
var is_invincible: bool = false

## State Machine expects this property
var animation_sprite: Node2D:
    get:
        if anim_attack and anim_attack.visible: return anim_attack
        return anim_walk

## -----------------------------------------------------------------------

## Summon-specific variables
const SUMMON_DURATION: float = 30.0
const ATTACK_DAMAGE: float = 10.0

var summon_duration: float = SUMMON_DURATION
var _elapsed: float = 0.0
var _is_being_consumed: bool = false
var is_permanent: bool = false  # If true, acts like regular hero (no timer, no despawn)

## Hero system components
var _state_machine: Node = null
var _aggro_area: Area2D = null
var HeroCore: Node = null
var EventBus: Node = null
var _floating_text: Node = null

## Radial progress textures (cached)
var _radial_textures: Array[Texture2D] = []

## HP tracking for summons
var max_hp: float = 45.0
var current_hp: float = 45.0

var _temp_damage_bonus_until_ms: int = 0
var _temp_damage_bonus_mult: float = 1.0

func _enter_tree() -> void:
    HeroCore = get_node_or_null("/root/HeroCore")
    EventBus = get_node_or_null("/root/EventBus")
    _floating_text = get_node_or_null("/root/FloatingText")

func _ready() -> void:
    add_to_group("hero")  # Behave as hero for combat
    add_to_group("summon")  # Mark as temporary unit

    _selection_outline_helper = HeroSelectionOutlineScript.new()
    _hurtbox_ui_helper = HeroHurtboxUIScript.new()
    _animation_helper = HeroAnimationHelperScript.new()
    if _selection_outline_helper:
        _selection_outline_helper.setup(self, EventBus)
    if _hurtbox_ui_helper:
        _hurtbox_ui_helper.setup(self, hurtbox_component, EventBus)

    _setup_selection_outline()
    _connect_selection_signals()
    _setup_hurtbox_ui_events()
    
    # Physics setup (same as HeroOnField)
    collision_layer = 1   # Layer 1: Heroes
    var wall_layer_mask: int = 1 << (8 - 1)  # Wall StaticBody2D layer
    collision_mask = 2 | wall_layer_mask     # Mobs + wall solid
    
    # Cache component references
    _aggro_area = aggro_area
    
    # Cache radial textures
    _load_radial_textures()
    
    # Setup health bar
    if health_bar:
        health_bar.visible = false  # Show only when damaged
    
    # Hide radial timer if permanent
    if is_permanent and radial_timer:
        radial_timer.visible = false
    
    # Setup hero state machine
    _setup_state_machine()

func initialize(id: String) -> void:
    hero_id = id.to_lower()
    is_summon = false
    is_permanent = true
    if radial_timer:
        radial_timer.visible = false

    var unit_base_id := hero_id
    if unit_base_id.contains("_"):
        var parts := unit_base_id.rsplit("_", true, 1)
        if parts.size() == 2 and String(parts[1]).is_valid_int():
            unit_base_id = String(parts[0])

    var placeholder_frames := HeroAssetLoaderScript.load_hero_sprite_frames(hero_id)
    if placeholder_frames != null:
        if anim_walk:
            anim_walk.sprite_frames = placeholder_frames
        if anim_attack:
            anim_attack.sprite_frames = placeholder_frames

    var unit_cfg := PathRegistryScript.load_unit_config(unit_base_id)
    if unit_cfg != null:
        if "attack_range" in unit_cfg:
            attack_range = float(unit_cfg.attack_range)
        if "max_range" in unit_cfg:
            max_range = float(unit_cfg.max_range)
        if "projectile_type" in unit_cfg:
            var projectile_type := String(unit_cfg.projectile_type).strip_edges().to_lower()
            is_melee = projectile_type == ""
            projectile_scene = null if is_melee else projectile_scene
        if unit_base_id == "familiar":
            move_speed = 52.0

    if HeroCore != null and hero_id != "":
        var total_stats: Dictionary = HeroCore.get_hero_total_stats(hero_id)
        max_hp = float(total_stats.get("maxHp", max_hp)) if total_stats is Dictionary else max_hp
        if HeroCore.query:
            current_hp = float(HeroCore.query.get_hero_hp(hero_id))
        else:
            current_hp = max_hp
        if current_hp <= 0.0:
            current_hp = max_hp
            HeroCore.update_hero(hero_id, {"hp": max_hp, "maxHp": max_hp})
        move_speed *= _get_intrinsic_speed_multiplier(hero_id)

    if _state_machine and _state_machine.has_method("start"):
        _state_machine.start()

func _setup_selection_outline() -> void:
    if _selection_outline_helper:
        _selection_outline_helper.setup_selection_outline()

func _connect_selection_signals() -> void:
    if _selection_outline_helper:
        _selection_outline_helper.connect_selection_signals(Callable(self, "_on_hero_selected_for_ui"))

func _on_hero_selected_for_ui(selected_hero_id: String) -> void:
    if _selection_outline_helper:
        _selection_outline_helper.on_hero_selected_for_ui(selected_hero_id)

func _setup_hurtbox_ui_events() -> void:
    if _hurtbox_ui_helper:
        _hurtbox_ui_helper.setup_hurtbox_ui_events(
            Callable(self, "_on_hurtbox_mouse_enter"),
            Callable(self, "_on_hurtbox_mouse_exit"),
            Callable(self, "_on_hurtbox_input_event")
        )

func _on_hurtbox_mouse_enter() -> void:
    if _hurtbox_ui_helper:
        _hurtbox_ui_helper.on_hurtbox_mouse_enter()

func _on_hurtbox_mouse_exit() -> void:
    if _hurtbox_ui_helper:
        _hurtbox_ui_helper.on_hurtbox_mouse_exit()

func _on_hurtbox_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if _hurtbox_ui_helper:
        _hurtbox_ui_helper.on_hurtbox_input_event(event)

func _load_radial_textures() -> void:
    for i in range(1, 21):
        var path := "res://assets/ui/radialProgressBar/%d.png" % i
        if ResourceLoader.exists(path):
            var tex := load(path) as Texture2D
            if tex:
                _radial_textures.append(tex)

func _setup_state_machine() -> void:
    # Create state machine node
    _state_machine = Node.new()
    _state_machine.name = "HeroStateMachine"
    _state_machine.set_script(preload("res://scripts/hero/states/HeroStateMachine.gd"))
    
    # Create states BEFORE adding state machine to tree (so initial_state is set when _ready runs)
    var idle_state = HeroIdleState.new()
    idle_state.name = "HeroIdleState"
    _state_machine.add_child(idle_state)
    
    var moving_state = HeroMovingToCombatState.new()
    moving_state.name = "HeroMovingToCombatState"
    _state_machine.add_child(moving_state)
    
    var attacking_state = HeroAttackingState.new()
    attacking_state.name = "HeroAttackingState"
    _state_machine.add_child(attacking_state)
    
    var death_state = HeroDeathState.new()
    death_state.name = "HeroDeathState"
    _state_machine.add_child(death_state)
    
    # Set initial state BEFORE adding to tree
    _state_machine.set("initial_state", idle_state)
    
    # Now add state machine to tree - its _ready() will see initial_state and auto-start
    add_child(_state_machine)


func _get_intrinsic_speed_multiplier(id: String) -> float:
    if HeroCore == null or id == "" or not HeroCore.has_method("get_hero"):
        return 1.0
    var hero_data: Variant = HeroCore.get_hero(id)
    if not (hero_data is Dictionary):
        return 1.0
    return float((hero_data as Dictionary).get("intrinsic_speed_multiplier", 1.0))

func initialize_as_summon(duration: float) -> void:
    summon_duration = duration
    _elapsed = 0.0
    current_hp = max_hp
    is_permanent = false  # Explicitly mark as temporary
    
    # Show radial timer for temporary summons
    if radial_timer:
        radial_timer.visible = true
    
    # Start state machine
    if _state_machine and _state_machine.has_method("start"):
        _state_machine.start()

func _process(delta: float) -> void:
    if _is_being_consumed or is_dead:
        return
    
    # Skip timer logic if permanent
    if is_permanent:
        return
    
    # Update summon lifetime (only for temporary summons)
    _elapsed += delta
    _update_radial_timer()
    
    # Auto-despawn when time expires
    if _elapsed >= summon_duration:
        _despawn()

func _update_radial_timer() -> void:
    if not radial_timer or _radial_textures.is_empty():
        return
    
    # Calculate progress (0.0 to 1.0)
    var progress: float = clampf(_elapsed / summon_duration, 0.0, 1.0)
    
    # Map to texture index (0-19)
    var tex_idx: int = int(progress * float(_radial_textures.size() - 1))
    tex_idx = clampi(tex_idx, 0, _radial_textures.size() - 1)
    
    radial_timer.texture = _radial_textures[tex_idx]

## Hero system compatibility methods
func take_damage(amount: float, _is_crit: bool = false, block_roll_provider: Callable = Callable()) -> void:
    if is_dead:
        return

    if is_invincible:
        return

    var total_evasion_chance := clampf(evasion_chance, 0.0, 1.0)

    if hero_id == "":
        var tree := get_tree()
        if tree and tree.root:
            var artifact_core := tree.root.get_node_or_null("ArtifactCore")
            if artifact_core != null and artifact_core.has_method("get_friendly_evasion_chance"):
                var evade_chance := float(artifact_core.call("get_friendly_evasion_chance"))
                total_evasion_chance = clampf(total_evasion_chance + evade_chance, 0.0, 1.0)

    if total_evasion_chance > 0.0 and randf() < total_evasion_chance:
        if _floating_text and get_parent():
            _floating_text.spawn_evade(get_parent(), global_position + Vector2(0, -30))
        if hero_id == "":
            var until_ms := Time.get_ticks_msec() + 3000
            _temp_damage_bonus_until_ms = until_ms
            _temp_damage_bonus_mult = 1.5
        return

    if FriendlyDamageBlockHelperScript.should_block_damage(self, block_roll_provider):
        if _floating_text and get_parent():
            _floating_text.spawn_evade(get_parent(), global_position + Vector2(0, -30))
        return

    var adjusted_amount := maxf(1.0, amount * maxf(0.0, damage_taken_multiplier))

    if hero_id != "" and HeroCore != null and HeroCore.has_method("take_damage"):
        HeroCore.take_damage(hero_id, adjusted_amount)
        if HeroCore.query and HeroCore.query.is_hero_dead(hero_id):
            die()
            return
        if HeroCore.query:
            current_hp = float(HeroCore.query.get_hero_hp(hero_id))
        else:
            var hero: Dictionary = HeroCore.get_hero(hero_id)
            current_hp = float(hero.get("hp", current_hp)) if hero is Dictionary else current_hp
    else:
        current_hp -= adjusted_amount
    
    # Update health bar
    if health_bar:
        health_bar.visible = true
        health_bar.value = (current_hp / max_hp) * 100.0
    # Die if HP depleted
    if current_hp <= 0:
        die()

func get_current_hp() -> float:
    if hero_id != "" and HeroCore != null and HeroCore.query:
        return float(HeroCore.query.get_hero_hp(hero_id))
    return current_hp

func get_max_hp() -> float:
    if hero_id != "" and HeroCore != null:
        var total_stats: Dictionary = HeroCore.get_hero_total_stats(hero_id)
        return max(1.0, float(total_stats.get("maxHp", max_hp))) if total_stats is Dictionary else max_hp
    return max_hp

func die() -> void:
    if is_dead:
        return
    
    is_dead = true
    
    # Change to death state
    if _state_machine and _state_machine.has_method("change_state"):
        _state_machine.change_state("HeroDeathState")
    else:
        # Fallback: immediate despawn
        _despawn()

func _despawn() -> void:
    _is_being_consumed = true
    
    # Fade out and remove
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.5)
    await tween.finished
    queue_free()

## State machine helper methods (expected by hero states)
func get_aggro_area() -> Area2D:
    return _aggro_area

func get_current_target() -> Node2D:
    return current_target

func set_current_target(target: Node2D) -> void:
    current_target = target

func get_move_speed() -> float:
    return move_speed * maxf(0.0, speed_multiplier)

func get_attack_damage() -> float:
    if hero_id != "" and HeroCore != null:
        var total_stats: Dictionary = HeroCore.get_hero_total_stats(hero_id)
        if total_stats is Dictionary and total_stats.has("damage"):
            return float(total_stats.get("damage", ATTACK_DAMAGE))

    if _temp_damage_bonus_until_ms > 0 and Time.get_ticks_msec() < _temp_damage_bonus_until_ms:
        return ATTACK_DAMAGE * _temp_damage_bonus_mult
    return ATTACK_DAMAGE

func is_target_dead(target: Node2D) -> bool:
    if target == null or not is_instance_valid(target):
        return true
    if target is CharacterBody2D and "is_dead" in target:
        return target.is_dead
    return false

func check_attack_range() -> bool:
    if current_target == null or not is_instance_valid(current_target):
        return false
    var distance = global_position.distance_to(current_target.global_position)
    return distance <= attack_range

## Animation helpers (expected by hero states)
func _play_sprite_animation(sprite: AnimatedSprite2D, primary_name: String, fallback_name: String = "") -> void:
    if _animation_helper:
        _animation_helper.play_sprite_animation(sprite, primary_name, fallback_name)

func _update_animation(anim_name: String) -> void:
    if _animation_helper:
        _animation_helper.update_animation(anim_name, anim_walk, anim_attack)

func set_attack_animation_playing(_value: bool) -> void:
    pass # For state compatibility

func flip_sprite(flip_h: bool) -> void:
    if anim_walk:
        anim_walk.flip_h = flip_h
    if anim_attack:
        anim_attack.flip_h = flip_h
    if _selection_outline_helper:
        _selection_outline_helper.set_outline_flip(flip_h)
