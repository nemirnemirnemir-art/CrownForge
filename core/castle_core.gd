extends Node
## CastleCore - Autoload singleton for Castle Health and Game State

signal castle_hp_changed(current_hp: int, max_hp: int)
signal game_over()

const MAX_HP: int = 100
var current_hp: int = MAX_HP
var is_game_over: bool = false
var _effective_max_hp: int = MAX_HP
var _encounter_bonus_hp: int = 0

func _ready() -> void:
    refresh_max_hp()

func get_effective_max_hp() -> int:
    return _effective_max_hp

func refresh_max_hp(emit_signal: bool = true) -> void:
    var bonus := 0
    var tree := Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        var artifact_core := tree.root.get_node_or_null("ArtifactCore")
        if artifact_core != null and artifact_core.has_method("get_castle_max_hp_bonus"):
            bonus = int(artifact_core.call("get_castle_max_hp_bonus"))
    _effective_max_hp = max(1, MAX_HP + bonus + _encounter_bonus_hp)
    current_hp = clampi(current_hp, 0, _effective_max_hp)
    if emit_signal:
        castle_hp_changed.emit(current_hp, _effective_max_hp)

func add_bonus_max_hp(amount: int) -> void:
    if amount == 0:
        return
    var prev_max := _effective_max_hp
    _encounter_bonus_hp = max(0, _encounter_bonus_hp + amount)
    refresh_max_hp()
    if amount > 0 and _effective_max_hp > prev_max:
        current_hp = min(_effective_max_hp, current_hp + (_effective_max_hp - prev_max))
        castle_hp_changed.emit(current_hp, _effective_max_hp)

func heal(amount: int) -> void:
    if is_game_over:
        return
    if amount <= 0:
        return
    refresh_max_hp(false)
    current_hp = min(_effective_max_hp, current_hp + amount)
    castle_hp_changed.emit(current_hp, _effective_max_hp)

func take_damage(amount: int) -> void:
    if is_game_over: return
    refresh_max_hp(false)

    current_hp = max(0, current_hp - amount)
    castle_hp_changed.emit(current_hp, _effective_max_hp)
    var damage_taken: int = max(0, amount)
    if damage_taken > 0:
        var tree := Engine.get_main_loop() as SceneTree
        if tree and tree.root:
            var artifact_core := tree.root.get_node_or_null("ArtifactCore")
            if artifact_core != null and artifact_core.has_method("on_castle_damaged"):
                artifact_core.call("on_castle_damaged", damage_taken)
    
    if current_hp <= 0:
        var tree := Engine.get_main_loop() as SceneTree
        if tree and tree.root:
            var artifact_core := tree.root.get_node_or_null("ArtifactCore")
            if artifact_core != null and artifact_core.has_method("try_revive_castle_on_zero_hp"):
                if bool(artifact_core.call("try_revive_castle_on_zero_hp")):
                    return
        _trigger_game_over()

func _trigger_game_over() -> void:
    is_game_over = true
    game_over.emit()
    print("[CastleCore] GAME OVER!")

func reset_game() -> void:
    # Full reset of all systems
    current_hp = MAX_HP
    is_game_over = false
    _effective_max_hp = MAX_HP
    _encounter_bonus_hp = 0
    
    if TownCore: TownCore.reset()
    if HeroCore: HeroCore.reset()
    if EconomyCore and EconomyCore.has_method("reset_progress"): EconomyCore.reset_progress()
    if StageCore: StageCore.load_save_data({"current_stage": 1, "max_stage_reached": 1})
    
    # Reload the game scene to clear all units and state
    var tree = Engine.get_main_loop()
    if tree is SceneTree:
        tree.reload_current_scene()

    refresh_max_hp()
