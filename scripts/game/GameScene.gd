extends Node2D
class_name GameScene

## Main game scene managing mob waves and stage progression
## Controller coordinating all GameScene modules

## Preload modules
const GameSceneWavesScript = preload("res://scripts/game_scene/GameSceneWaves.gd")
const WaveEnemyHUDScript = preload("res://scripts/ui/hud/WaveEnemyHUD.gd")
const GameSceneStagesScript = preload("res://scripts/game_scene/GameSceneStages.gd")
const GameSceneHeroesScript = preload("res://scripts/game_scene/GameSceneHeroes.gd")
const GameSceneDebugScript = preload("res://scripts/game_scene/GameSceneDebug.gd")
const GameSceneSignalsScript = preload("res://scripts/game_scene/GameSceneSignals.gd")
const GameSceneSpellsScript = preload("res://scripts/game_scene/GameSceneSpells.gd")
const GameScenePendingRewardsScript = preload("res://scripts/game_scene/GameScenePendingRewards.gd")
const GameSceneEncounterFlowScript = preload("res://scripts/game_scene/GameSceneEncounterFlow.gd")
const GameSceneWaveFlowScript = preload("res://scripts/game_scene/GameSceneWaveFlow.gd")
const GameSceneBootstrapScript = preload("res://scripts/game_scene/GameSceneBootstrap.gd")
const ArtifactSpellRewardsScript = preload("res://core/artifacts/ArtifactSpellRewards.gd")
const HeroSceneRegistryScript = preload("res://scripts/hero/HeroSceneRegistry.gd")
const EncounterServiceScript = preload("res://scripts/encounters/EncounterService.gd")
const BuildingsTooltipScene: PackedScene = preload("res://scenes/ui/town/BuildingsTooltip.tscn")
const GameSceneRewardDispatcherScript = preload("res://scripts/game_scene/GameSceneRewardDispatcher.gd")
const GameSceneActionDispatcherScript = preload("res://scripts/game_scene/GameSceneActionDispatcher.gd")
const GameSceneInputControllerScript = preload("res://scripts/game_scene/GameSceneInputController.gd")
const WaveMusicControllerScript = preload("res://scripts/systems/audio/wave_music_controller.gd")
const GameSceneProcessLoopScript = preload("res://scripts/game_scene/GameSceneProcessLoop.gd")
const VictoryPanelScene: PackedScene = preload("res://scenes/ui/overlays/VictoryPanel.tscn")

const CUSTOM_CURSOR_TEX: Texture2D = preload("res://assets/ui/icons/Cursor_01.png")
const SLOT_HOVER_TOOLTIP_DELAY := 1.0
const SLOT_HOVER_TOOLTIP_OFFSET_Y := 56.0
const PAUSE_SPEED_EPSILON := 0.001
static var runtime_content_scale_override: float = -1.0

@export var mute_all_audio: bool = false

## Scene references
@onready var background: Sprite2D = $Background
@onready var biome_layer: Node2D = $WorldYSort/BiomeLayer
@onready var map_container: Node2D = $WorldYSort/MapContainer
@onready var battlefield_bounds_node: Node = get_node_or_null("WorldYSort/MapContainer/BattlefieldBounds2D")
@onready var hero_container: Node2D = null
@onready var hero_bar: Control = $UILayer/HeroBar
@onready var hero_card: Control = get_node_or_null("UILayer/HeroCard")
@onready var reward_menu_base_production: RewardMenuBaseProduction = $UILayer/RewardMenuBaseProduction
@onready var reward_menu_established_production: RewardMenuBaseProduction = get_node_or_null("UILayer/RewardMenuEstablishedProduction")
@onready var reward_menu_kingdom_infrastructure: RewardMenuBaseProduction = get_node_or_null("UILayer/RewardMenuKingdomInfrastructure")
@onready var reward_menu_levy_barracks: RewardMenuLevyBarracks = get_node_or_null("UILayer/RewardMenuLevyBarracks")
@onready var reward_menu_artifacts: RewardMenuArtifacts = $UILayer/RewardMenuArtifacts
@onready var reward_menu_troop_bonuses: RewardMenuTroopBonuses = $UILayer/RewardMenuTroopBonuses
@onready var reward_menu_building_upgrades: RewardMenuBuildingUpgrades = $UILayer/RewardMenuBuildingUpgrades
@onready var reward_menu_resources: RewardMenuResources = get_node_or_null("UILayer/RewardMenuResources")
@onready var reward_menu_spells: RewardMenuSpells = get_node_or_null("UILayer/RewardMenuSpells")
@onready var reward_menu_legendary_spells: RewardMenuSpells = get_node_or_null("UILayer/RewardMenuLegendarySpells")
@onready var reward_menu_trader: Control = get_node_or_null("UILayer/RewardMenuTrader") as Control
@onready var wave_reward_menu: WaveRewardMenu = get_node_or_null("UILayer/WaveRewardMenu")
@onready var prophecy_menu = get_node_or_null("UILayer/ProphecyMenu")
@onready var encounter_menu = get_node_or_null("UILayer/EncounterMenu")
@onready var prophecy_pattern_pool = get_node_or_null("UILayer/ProphecyPatternPool")
@onready var _town_menu: TownMenu = get_node_or_null("UILayer/TownMenu") as TownMenu
var _wave_timer_bar: WaveTimerBar = null

## Background settings
@export var background_scale: float = 1.0
@export var background_auto_scale_multiplier: float = 0.8

@export_group("Day Night settings")
@export var pause_day_night: bool = false:
    set(val):
        pause_day_night = val
        var day_night_cycle := _get_day_night_cycle()
        if day_night_cycle:
            day_night_cycle.set_paused(val)

@export_group("Debug settings")
@export var waves_paused: bool = false:
    set(val):
        waves_paused = val
        if _waves_manager:
            _waves_manager.set_paused(val)
        print("[GameScene] Waves paused: %s" % val)

@export_group("Game Version")
@export var release_mode_enabled: bool = true

@export_group("Start Bypass")
@export var skip_character_creation_setup: bool = false
@export var bypass_default_class_id: String = "chivalry"
@export var bypass_default_active_spell_id: String = "tough_guys"
@export var bypass_default_passive_spell_id: String = ""
@export_range(16, 99, 1) var bypass_default_age: int = 16
@export var bypass_default_name: String = "King"

@export_group("Viewport")
@export var force_content_scale: bool = true
@export_range(0.5, 1.5, 0.01) var content_scale_factor: float = 0.75

@export_group("Combat")
@export_range(0.0, 300.0, 1.0) var wall_attack_range: float = 50.0:
    set(val):
        wall_attack_range = maxf(0.0, val)
        if _waves_manager and _waves_manager.has_method("set_wall_attack_stop_distance"):
            _waves_manager.set_wall_attack_stop_distance(wall_attack_range)

## Map bounds
const MAP_HALF_EXTENT: float = 1000.0
const MAP_SIZE: Vector2 = Vector2(MAP_HALF_EXTENT * 2.0, MAP_HALF_EXTENT * 2.0)
var map_bounds: Rect2 = Rect2(
    -MAP_HALF_EXTENT,
    -MAP_HALF_EXTENT,
    MAP_SIZE.x,
    MAP_SIZE.y
)
var portal_spawn_position: Vector2 = Vector2.ZERO

## Module instances
var _waves_manager: GameSceneWaves
var _stages_manager: GameSceneStages
var _heroes_manager: GameSceneHeroes
var _debug_manager: GameSceneDebug
var _signals_manager: GameSceneSignals
var _wave_enemy_hud: Control = null
var _building_drag_manager: GameSceneBuildingDrag
var _slot_hover_manager: GameSceneSlotHover
var _pause_state_manager: GameScenePauseState
var _reward_menus_manager: GameSceneRewardMenus
var _pending_rewards_manager: GameScenePendingRewards
var _boss_spawn_manager: GameSceneBossSpawn
var _encounter_flow_manager: GameSceneEncounterFlow
var _wave_flow_manager: GameSceneWaveFlow
var _bootstrap_manager: GameSceneBootstrap
var _reward_dispatcher: GameSceneRewardDispatcher
var _action_dispatcher: GameSceneActionDispatcher
var _input_controller: GameSceneInputController
var _process_loop_manager: GameSceneProcessLoop

var _pending_open_prophecy: bool = false
var _encounter_service = null
var _debug_building_upgrades_module: DebugBuildingUpgradesModule
var _victory_panel_instance: VictoryPanel = null

const HomeseekerBossScene: PackedScene = preload("res://scenes/mobs/HomeseekerBoss.tscn")
const MinotaurBossScene: PackedScene = preload("res://scenes/mobs/MinotaurBoss.tscn")
const MinotaurFaceTex: Texture2D = preload("res://assets/characters/faces/bosses/Minotaur_face.png")
const AudioEventsScript = preload("res://scripts/systems/audio/audio_events.gd")

@onready var boss_container: Node2D = get_node_or_null("WorldYSort/MapContainer/BossPivot") as Node2D
@onready var homeseeker_arrival_overlay: HomeseekerArrivalOverlay = get_node_or_null("UILayer/HomeseekerArrivalOverlay") as HomeseekerArrivalOverlay
@onready var minotaur_arrival_overlay: MinotaurArrivalOverlay = get_node_or_null("UILayer/MinotaurArrivalOverlay") as MinotaurArrivalOverlay
@onready var boss_hp_bar: BossHpBar = get_node_or_null("UILayer/BossHpBar") as BossHpBar
@onready var camera_shake: CameraShake2D = get_node_or_null("CameraShake") as CameraShake2D


## Public accessors for backward compatibility
var active_heroes_on_field: Dictionary:
    get:
        if _heroes_manager:
            return _heroes_manager.active_heroes_on_field
        var empty_heroes: Dictionary = {}
        return empty_heroes

## Public debug API: spawn mobs by enemy_id (for debug menu buttons)
## Uses waves manager spawn path to ensure proper portal area spawning, not direct instantiate
func debug_spawn_enemy_id(enemy_id: String, count: int = 1) -> int:
    if _waves_manager:
        var spawned = _waves_manager.debug_spawn_enemy_id(enemy_id, count)
        print("[GameScene] Debug spawn %s x%d -> %d" % [enemy_id, count, spawned])
        return spawned
    else:
        push_warning("[GameScene] Waves manager not ready, cannot spawn %s" % enemy_id)
        return 0

func debug_set_prophecy_level(level: int) -> void:
    if _waves_manager:
        _waves_manager.debug_set_prophecy_level(level)

func debug_force_boss_wave() -> void:
    if _waves_manager:
        _waves_manager.debug_force_boss_wave()

func debug_skip_to_next_prophecy_level() -> void:
    if _waves_manager:
        _waves_manager.debug_skip_to_next_prophecy_level()

func spawn_goblin_bandit(count: int = 1) -> void:
    if _waves_manager:
        var spawned = _waves_manager.debug_spawn_enemy_id("goblin_bandit", count)
        print("[GameScene] Debug spawn goblin_bandit x%d -> %d" % [count, spawned])
    else:
        push_warning("[GameScene] Waves manager not ready, cannot spawn goblin bandit")

func spawn_dragon(count: int = 1) -> void:
    if _waves_manager:
        var spawned = _waves_manager.debug_spawn_enemy_id("dragon", count)
        print("[GameScene] Debug spawn dragon x%d -> %d" % [count, spawned])
    else:
        push_warning("[GameScene] Waves manager not ready, cannot spawn dragon")

func open_town_menu() -> void:
    if _town_menu:
        _town_menu.open_menu()

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _apply_content_scale_settings()
    _apply_character_creation_bypass_if_enabled()
    print("[GameScene] _ready called")
    print("[GameScene] Position: %s, Global Position: %s" % [position, global_position])
    add_to_group("game_scene")

    var building_registry := _get_building_registry()
    if building_registry and building_registry.has_method("set_release_mode_enabled"):
        building_registry.set_release_mode_enabled(release_mode_enabled)
    if release_mode_enabled:
        _apply_release_starting_recipes()

    if CUSTOM_CURSOR_TEX:
        Input.set_custom_mouse_cursor(CUSTOM_CURSOR_TEX, Input.CURSOR_ARROW, Vector2.ZERO)
    
    _ensure_hero_container()
    if not release_mode_enabled:
        _setup_debug_menu()
    HeroAnimationLoader.create_all_hero_spriteframes()
    
    var day_night_cycle := _get_day_night_cycle()
    if day_night_cycle:
        day_night_cycle.skip_to_phase("day")
        day_night_cycle.set_paused(pause_day_night)
    
    _initialize_modules()

    # Start wave music controller and ambient main track
    var wave_music := WaveMusicController.new()
    wave_music.name = "WaveMusicController"
    add_child(wave_music)
    AudioManager.play_music(AudioEventsScript.MUSIC_MAIN, 2.0)
    # Connect reward menu for music dimming
    if wave_reward_menu:
        wave_music.connect_to_reward_menu(wave_reward_menu)

    _encounter_service = EncounterServiceScript.new()
    _signals_manager.connect_signals()
    _stages_manager.load_background()
    
    _boss_spawn_manager = GameSceneBossSpawn.new()
    _boss_spawn_manager.initialize(self, map_container, boss_container, boss_hp_bar, homeseeker_arrival_overlay, minotaur_arrival_overlay)
    
    _pause_state_manager = GameScenePauseState.new()
    _pause_state_manager.initialize(self)
    
    _reward_menus_manager = GameSceneRewardMenus.new()
    _reward_menus_manager.initialize(reward_menu_base_production, reward_menu_levy_barracks, reward_menu_artifacts, reward_menu_troop_bonuses, reward_menu_building_upgrades, reward_menu_resources, reward_menu_spells, reward_menu_legendary_spells, reward_menu_trader, prophecy_menu, prophecy_pattern_pool, _waves_manager)
    var ui_layer := get_node_or_null("UILayer") as CanvasLayer
    _pending_rewards_manager = GameScenePendingRewardsScript.new()
    _pending_rewards_manager.initialize(self, ui_layer)
    _encounter_flow_manager = GameSceneEncounterFlowScript.new()
    _encounter_flow_manager.initialize(
        self,
        _waves_manager,
        _pause_state_manager,
        encounter_menu,
        _encounter_service,
        [],
        Callable(self, "_is_pause_after_prophecy_enabled"),
        Callable(self, "_run_encounter_ui_action"),
        Callable(self, "_recover_production_after_encounter")
    )
    _wave_flow_manager = GameSceneWaveFlowScript.new()
    _wave_flow_manager.initialize(self, _waves_manager, wave_reward_menu, Callable(self, "open_reward_menu_prophecy"))

    _reward_dispatcher = GameSceneRewardDispatcherScript.new()
    _reward_dispatcher.initialize(self)
    _action_dispatcher = GameSceneActionDispatcherScript.new()
    _action_dispatcher.initialize(self, _reward_dispatcher)
    _input_controller = GameSceneInputControllerScript.new()
    _input_controller.initialize(self)

    if prophecy_menu and prophecy_menu.has_signal("confirmed") and not prophecy_menu.confirmed.is_connected(_on_prophecy_confirmed):
        prophecy_menu.confirmed.connect(_on_prophecy_confirmed)
    if encounter_menu and encounter_menu.has_signal("option_selected") and not encounter_menu.option_selected.is_connected(_on_encounter_option_selected):
        encounter_menu.option_selected.connect(_on_encounter_option_selected)
    if encounter_menu and encounter_menu.has_signal("closed") and not encounter_menu.closed.is_connected(_on_encounter_closed):
        encounter_menu.closed.connect(_on_encounter_closed)
    if wave_reward_menu and wave_reward_menu.has_signal("closed") and not wave_reward_menu.closed.is_connected(_on_wave_reward_menu_closed):
        wave_reward_menu.closed.connect(_on_wave_reward_menu_closed)
    if _waves_manager and _waves_manager.has_signal("prophecy_batch_finished") and not _waves_manager.prophecy_batch_finished.is_connected(_on_prophecy_batch_finished):
        _waves_manager.prophecy_batch_finished.connect(_on_prophecy_batch_finished)
    _connect_encounter_reward_menu_signals()

    if mute_all_audio:
        AudioManager.set_muted(true)
        print("[GameScene] Audio muted via inspector flag")

    if OS.is_debug_build():
        _dev_validate_startup()
    
    # Apply initial wave pause setting
    if _waves_manager:
        _waves_manager.set_paused(waves_paused)
    
    # Check map container position
    if map_container:
        print("[GameScene] MapContainer position: %s" % map_container.position)
    
    call_deferred("update_heroes_on_field")
    
    print("[GameScene] Starting wave (deferred)...")
    # Defer start_wave to ensure current_scene is updated and viewport is ready
    call_deferred("_start_initial_wave")
    
    # print("[GameScene] Ready.")


func _apply_character_creation_bypass_if_enabled() -> void:
    if not skip_character_creation_setup:
        return

    var character_creation_state := get_node_or_null("/root/CharacterCreationState")
    if character_creation_state != null and character_creation_state.has_method("apply_selection"):
        character_creation_state.call(
            "apply_selection",
            bypass_default_class_id,
            bypass_default_active_spell_id,
            bypass_default_passive_spell_id,
            bypass_default_age,
            bypass_default_name
        )

    if KingSpellState != null:
        KingSpellState.begin_run_from_character_creation(character_creation_state)

    if GameStartSettings != null and GameStartSettings.has_method("set_start_via_character_creation"):
        GameStartSettings.set_start_via_character_creation(false)

    var king_spell_hud := get_node_or_null("UILayer/MainUI/KingSpellHud")
    if king_spell_hud != null and king_spell_hud.has_method("refresh_selected_spell_slots"):
        king_spell_hud.call_deferred("refresh_selected_spell_slots")

func _apply_content_scale_settings() -> void:
    GameSceneViewport.apply_settings(get_window(), force_content_scale, content_scale_factor, runtime_content_scale_override)

func set_runtime_content_scale_override(new_factor: float) -> void:
    runtime_content_scale_override = GameSceneViewport.set_runtime_override(get_window(), new_factor)

func _dev_validate_startup() -> void:
    GameSceneStartupValidator.validate(self)

func _ensure_hero_container() -> void:
    hero_container = GameSceneBootstrap.ensure_hero_container(self)

func _setup_debug_menu() -> void:
    GameSceneDebug.setup_debug_menu(self)

func _apply_release_starting_recipes() -> void:
    GameSceneReleaseSetup.apply_starting_recipes()

func spawn_homeseeker_boss() -> void:
    if _boss_spawn_manager:
        _boss_spawn_manager.spawn_homeseeker()

func spawn_minotaur_boss() -> void:
    if _boss_spawn_manager:
        _boss_spawn_manager.spawn_minotaur()

func _spawn_homeseeker_boss_sequence() -> void:
    if _boss_spawn_manager:
        _boss_spawn_manager.spawn_homeseeker_sequence()

func _spawn_minotaur_boss_sequence() -> void:
    if _boss_spawn_manager:
        _boss_spawn_manager.spawn_minotaur_sequence()

func _start_initial_wave() -> void:
    print("[GameScene] _start_initial_wave called. Current scene: %s" % get_tree().current_scene)
    pass

const MapLayoutScript = preload("res://scripts/map/MapLayout.gd")
const BuildingMenuScript = preload("res://scripts/ui/building/BuildingMenu.gd")

@onready var map_layout_node: MapLayoutScript = null
@onready var building_menu: BuildingMenu = null

func _initialize_modules() -> void:
    map_bounds = _resolve_runtime_map_bounds()
    _waves_manager = GameSceneWavesScript.new()
    _waves_manager.initialize(self, map_container, map_bounds, wall_attack_range)
    
    _stages_manager = GameSceneStagesScript.new()
    _stages_manager.initialize(self, biome_layer, background)
    
    _heroes_manager = GameSceneHeroesScript.new()
    _heroes_manager.initialize(self, hero_container, map_bounds)
    
    _debug_manager = GameSceneDebugScript.new()
    _debug_manager.initialize(self, hero_card)
    
    _debug_building_upgrades_module = DebugBuildingUpgradesModule.new()
    _debug_building_upgrades_module.setup(_get_singleton_node("BuildingUpgradeCore"))
    
    _signals_manager = GameSceneSignalsScript.new()
    _signals_manager.initialize(self, hero_bar, hero_card)
    _bootstrap_manager = GameSceneBootstrapScript.new()
    _bootstrap_manager.initialize(
        self,
        _waves_manager,
        Callable(self, "_setup_spell_panel_bootstrap"),
        func() -> Variant: return GameSceneBuildingDrag.new(),
        func() -> Variant: return GameSceneSlotHover.new(),
        func() -> Variant: return WaveEnemyHUDScript.new(),
        func() -> Variant: return GameSceneProcessLoopScript.new()
    )
    _bootstrap_manager.run()

    _apply_runtime_map_bounds()

func _setup_spell_panel_bootstrap() -> void:
    GameSceneSpellsScript.setup_spell_panel(self)

func _get_wave_timer_bar() -> WaveTimerBar:
    return _wave_timer_bar

func _get_map_layout_node() -> Node:
    return get_node_or_null("WorldYSort/MapContainer/MapLayout")

func _get_building_menu() -> Node:
    return get_node_or_null("UILayer/BuildingMenu")

func _get_ui_layer() -> CanvasLayer:
    return get_node_or_null("UILayer") as CanvasLayer

func _on_wave_spawned(wave_number: int) -> void:
    _action_dispatcher.on_wave_spawned(wave_number)

func _on_enemies_cleared() -> void:
    if not is_inside_tree():
        return
    if _heroes_manager:
        _heroes_manager.on_enemies_cleared()

func _on_wave_completed(wave_number: int) -> void:
    _action_dispatcher.on_wave_completed(wave_number)

func _on_wave_reward_menu_closed() -> void:
    _action_dispatcher.on_wave_reward_menu_closed()

func _on_prophecy_batch_finished() -> void:
    _action_dispatcher.on_prophecy_batch_finished()

func _on_prophecy_confirmed(selected_waves: Array) -> void:
    _action_dispatcher.on_prophecy_confirmed(selected_waves)

func _try_open_encounter_after_prophecy() -> bool:
    return _action_dispatcher.try_open_encounter_after_prophecy()

func _get_game_settings() -> Node:
    if not is_inside_tree():
        return null
    var scene_tree: SceneTree = get_tree()
    if scene_tree == null or scene_tree.root == null:
        return null
    return scene_tree.root.get_node_or_null("GameSettings")

func _is_pause_after_prophecy_enabled() -> bool:
    var game_settings := _get_game_settings()
    if game_settings and game_settings.has_method("is_pause_after_prophecy_enabled"):
        return bool(game_settings.is_pause_after_prophecy_enabled())
    return true

func _on_encounter_option_selected(encounter_id: String, option_id: String) -> void:
    _action_dispatcher.on_encounter_option_selected(encounter_id, option_id)


func _execute_encounter_ui_actions(actions: Array) -> void:
    _action_dispatcher.execute_encounter_ui_actions(actions)


func _connect_encounter_reward_menu_signals() -> void:
    _action_dispatcher.connect_encounter_reward_menu_signals()


func _on_encounter_reward_menu_visibility_changed() -> void:
    _action_dispatcher.on_encounter_reward_menu_visibility_changed()


func _is_any_encounter_reward_menu_visible() -> bool:
    return _action_dispatcher.is_any_encounter_reward_menu_visible()


func _open_next_encounter_ui_action() -> void:
    _action_dispatcher.open_next_encounter_ui_action()


func _run_encounter_ui_action(action_id: String) -> bool:
    return _action_dispatcher.run_encounter_ui_action(action_id)


func _on_encounter_closed() -> void:
    _action_dispatcher.on_encounter_closed()


func _resolve_runtime_map_bounds() -> Rect2:
    if battlefield_bounds_node and battlefield_bounds_node.has_method("get_world_rect"):
        var runtime_bounds := battlefield_bounds_node.call("get_world_rect") as Rect2
        if runtime_bounds.size != Vector2.ZERO:
            return runtime_bounds
    return map_bounds


func _apply_runtime_map_bounds() -> void:
    map_bounds = _resolve_runtime_map_bounds()
    if _waves_manager and _waves_manager.has_method("update_map_bounds"):
        _waves_manager.update_map_bounds(map_bounds)
    if _heroes_manager and _heroes_manager.has_method("update_map_bounds"):
        _heroes_manager.update_map_bounds(map_bounds)


func _recover_production_after_encounter() -> void:
    if map_layout_node == null:
        return
    var recovered_slots := 0
    for raw_slot in map_layout_node.slots:
        var slot := raw_slot as Node
        if slot == null:
            continue
        if slot.has_method("recover_after_encounter_pause") and bool(slot.call("recover_after_encounter_pause")):
            recovered_slots += 1
    if recovered_slots > 0:
        print("[GameScene][ProductionRecovery] recovered %d slots after encounter" % recovered_slots)


func _setup_wave_timer_bar() -> void:
    if _bootstrap_manager:
        _bootstrap_manager.setup_wave_timer_bar()


## Spell targeting system
const SpellTargetingCircleScene = preload("res://scenes/ui/spells/SpellTargetingCircle.tscn")
var _spell_panel: Control = null
var _active_spell_config: SpellConfig = null
var _spell_targeting_active: bool = false
var _targeting_circle: Node2D = null

func _on_building_drag_started(building_id: String) -> void:
    _input_controller.on_building_drag_started(building_id)

func _on_building_move_started(slot_index: int, building_id: String) -> void:
    _input_controller.on_building_move_started(slot_index, building_id)

func _on_building_selected(building_id: String) -> void:
    _input_controller.on_building_selected(building_id)

func _on_slot_clicked(slot_index: int) -> void:
    _input_controller.on_slot_clicked(slot_index)

func _handle_building_drop() -> void:
    _input_controller.handle_building_drop()



func _on_spell_targeting_started(config: SpellConfig) -> void:
    _input_controller.on_spell_targeting_started(config)

func _on_spell_cast_requested(config: SpellConfig, _viewport_pos: Vector2) -> void:
    _input_controller.on_spell_cast_requested(config, _viewport_pos)

func _on_spell_targeting_cancelled() -> void:
    _input_controller.on_spell_targeting_cancelled()

func _input(event: InputEvent) -> void:
    _input_controller.handle_input(event)

func open_reward_menu_base_production() -> void:
    _reward_dispatcher.open_reward_menu_base_production()

func open_reward_menu_established_production() -> void:
    _reward_dispatcher.open_reward_menu_established_production()

func open_reward_menu_advanced_production() -> void:
    _reward_dispatcher.open_reward_menu_advanced_production()

func open_reward_menu_kingdom_infrastructure() -> void:
    _reward_dispatcher.open_reward_menu_kingdom_infrastructure()

func open_reward_menu_levy_barracks() -> void:
    _reward_dispatcher.open_reward_menu_levy_barracks()

func open_reward_menu_veteran_barracks() -> void:
    _reward_dispatcher.open_reward_menu_veteran_barracks()

func open_reward_menu_elite_barracks() -> void:
    _reward_dispatcher.open_reward_menu_elite_barracks()

func open_reward_menu_artifacts(offered_count: int = 2, legendary_only: bool = false) -> void:
    _reward_dispatcher.open_reward_menu_artifacts(offered_count, legendary_only)

func open_reward_menu_troop_bonuses() -> void:
    _reward_dispatcher.open_reward_menu_troop_bonuses()

func open_reward_menu_building_upgrades() -> void:
    _reward_dispatcher.open_reward_menu_building_upgrades()

func open_reward_menu_resources(amount: int = 0) -> void:
    _reward_dispatcher.open_reward_menu_resources(amount)

func open_reward_menu_spells(offered_count: int = 2, legendary_only: bool = false) -> void:
    _reward_dispatcher.open_reward_menu_spells(offered_count, legendary_only)

func open_reward_menu_legendary_spells(offered_count: int = 2) -> void:
    _reward_dispatcher.open_reward_menu_legendary_spells(offered_count)

func open_reward_menu_trader() -> void:
    _reward_dispatcher.open_reward_menu_trader()

func enqueue_pending_reward(reward: Dictionary) -> void:
    _reward_dispatcher.enqueue_pending_reward(reward)

func enqueue_resource_choice_reward(amount: int, count: int = 1) -> void:
    _reward_dispatcher.enqueue_resource_choice_reward(amount, count)

func enqueue_spell_grant_reward(spell_id: String, count: int = 1) -> void:
    _reward_dispatcher.enqueue_spell_grant_reward(spell_id, count)

func enqueue_spell_choice_reward(offered_count: int = 2, legendary_only: bool = false, count: int = 1) -> void:
    _reward_dispatcher.enqueue_spell_choice_reward(offered_count, legendary_only, count)

func enqueue_established_production_reward() -> void:
    _reward_dispatcher.enqueue_established_production_reward()

func enqueue_base_production_reward() -> void:
    _reward_dispatcher.enqueue_base_production_reward()

func enqueue_advanced_production_reward() -> void:
    _reward_dispatcher.enqueue_advanced_production_reward()

func enqueue_kingdom_infrastructure_reward() -> void:
    _reward_dispatcher.enqueue_kingdom_infrastructure_reward()

func enqueue_levy_barracks_reward() -> void:
    _reward_dispatcher.enqueue_levy_barracks_reward()

func enqueue_veteran_barracks_reward() -> void:
    _reward_dispatcher.enqueue_veteran_barracks_reward()

func enqueue_elite_barracks_reward() -> void:
    _reward_dispatcher.enqueue_elite_barracks_reward()

func enqueue_artifact_reward() -> void:
    _reward_dispatcher.enqueue_artifact_reward()

func enqueue_building_upgrade_reward() -> void:
    _reward_dispatcher.enqueue_building_upgrade_reward()

func enqueue_troop_bonus_reward() -> void:
    _reward_dispatcher.enqueue_troop_bonus_reward()

func can_open_pending_reward() -> bool:
    return _reward_dispatcher.can_open_pending_reward()

func open_pending_reward(reward: Dictionary) -> bool:
    return _reward_dispatcher.open_pending_reward(reward)

func open_reward_menu_prophecy() -> void:
    _reward_dispatcher.open_reward_menu_prophecy()

func has_active_reward_chain() -> bool:
    if wave_reward_menu != null and wave_reward_menu.has_method("has_active_reward_chain"):
        if bool(wave_reward_menu.call("has_active_reward_chain")):
            return true
    if _pending_rewards_manager != null and _pending_rewards_manager.has_method("has_pending_rewards"):
        if bool(_pending_rewards_manager.has_pending_rewards()):
            return true
    return false

func show_prophecy_victory() -> void:
    if _waves_manager:
        _waves_manager.set_paused(true)
    if get_tree():
        get_tree().paused = true
    if _victory_panel_instance == null and VictoryPanelScene != null:
        var created := VictoryPanelScene.instantiate() as VictoryPanel
        if created != null:
            _victory_panel_instance = created
            var ui_layer := _get_ui_layer()
            if ui_layer != null:
                ui_layer.add_child(_victory_panel_instance)
            else:
                add_child(_victory_panel_instance)
    if _victory_panel_instance != null:
        _victory_panel_instance.show_victory()

func _get_release_wave_interval(wave_number: int) -> float:
    if _waves_manager and _waves_manager.has_method("get_wave_interval_for_number"):
        return float(_waves_manager.get_wave_interval_for_number(wave_number))
    if wave_number < 0:
        return 0.0
    if wave_number == 0:
        return 100.0
    return 60.0


func _update_spell_targeting_process_loop() -> void:
    GameSceneSpellsScript.update_targeting(self)

func _process(delta: float) -> void:
    if _process_loop_manager:
        _process_loop_manager.tick(delta)

## === WAVE LOGIC ===

func spawn_mobs() -> void:
    pass # Managed by GameSceneWaves/WaveTimerBar logic

func clear_mobs() -> void:
    if _waves_manager:
        _waves_manager.clear_mobs()

func get_alive_mobs() -> Array:
    if _waves_manager:
        return _waves_manager.get_alive_mobs()
    var empty_mobs: Array = []
    return empty_mobs

func _on_mob_died(mob: Mob) -> void:
    _waves_manager._on_mob_died(mob)


## === STAGE LOGIC ===

func get_biome_name(stage: int) -> String:
    return _stages_manager.get_biome_name(stage)

func load_background() -> void:
    _stages_manager.load_background()

func _on_stage_changed_event(_new_stage: int) -> void:
    if not is_inside_tree():
        return
    
    var tree = get_tree()
    if tree == null or tree.current_scene != self:
        return
    
    load_background()
    pass

## === HEROES ON FIELD ===

func update_heroes_on_field() -> void:
    _heroes_manager.update_heroes_on_field()

func spawn_hero_on_field(hero_id: String, _hero_data: Dictionary = {}) -> void:
    _heroes_manager.spawn_hero_on_field(hero_id)

func spawn_temporary_hero_on_field(unit_id: String, duration: float, override_position: Vector2 = Vector2.INF) -> void:
    _heroes_manager.spawn_temporary_hero_on_field(unit_id, duration, override_position)

func despawn_hero_from_field(hero_id: String) -> void:
    _heroes_manager.despawn_hero_from_field(hero_id)

func _on_squad_changed() -> void:
    update_heroes_on_field()

func _on_hero_died(hero_id: String) -> void:
    despawn_hero_from_field(hero_id)

func reset_scene() -> void:
    if _heroes_manager.has_method("reset"):
        _heroes_manager.reset()

func _on_hero_auto_replaced(dead_id: String, new_id: String) -> void:
    var hero_core: Variant = _get_singleton_node("HeroCore")
    if hero_core != null and hero_core.query != null and hero_core.query.has_hero(new_id):
        # Try to get the dying hero's position (hero is still on field at this point)
        var death_pos: Vector2 = _heroes_manager.get_hero_position(dead_id)
        if death_pos == Vector2.INF and _heroes_manager.has_method("pop_death_position"):
            death_pos = _heroes_manager.pop_death_position(dead_id)
        if death_pos != Vector2.INF:
            # Spawn cloud/dust effect at death position for rider transformation
            _spawn_rider_transform_effect(death_pos)
            _heroes_manager.spawn_hero_on_field(new_id, death_pos)
        else:
            _heroes_manager.spawn_hero_on_field(new_id)

func _spawn_rider_transform_effect(pos: Vector2) -> void:
    # Load and spawn spawn dust effect for rider transformation
    var dust_scene: PackedScene = load("res://scenes/effects/SpawnDustEffect.tscn") as PackedScene
    if dust_scene == null:
        return
    var dust: Node2D = dust_scene.instantiate()
    var container := get_node_or_null("WorldYSort/MapContainer")
    if container:
        container.add_child(dust)
        dust.global_position = pos
    else:
        add_child(dust)
        dust.global_position = pos

func _check_dead_heroes_cleanup() -> void:
    _heroes_manager.check_dead_heroes_cleanup()

## Deprecated - use MapMarkerService directly
func set_portal_spawn_position(_world_position: Vector2) -> void:
    pass  # MapMarkerService now manages positions

## Deprecated - use MapMarkerService.get_bridge_position()
func get_bridge_position() -> Vector2:
    var marker_service: Variant = _get_singleton_node("MapMarkerService")
    return marker_service.get_bridge_position() if marker_service else Vector2.ZERO

func get_portal_position() -> Vector2:
    var marker_service: Variant = _get_singleton_node("MapMarkerService")
    return marker_service.get_portal_position() if marker_service else Vector2.ZERO

func _get_day_night_cycle() -> Node:
    if not is_inside_tree():
        return null
    var scene_tree: SceneTree = get_tree()
    if scene_tree == null or scene_tree.root == null:
        return null
    return scene_tree.root.get_node_or_null("DayNightCycle")

func _get_building_registry() -> Node:
    if not is_inside_tree():
        return null
    var scene_tree: SceneTree = get_tree()
    if scene_tree == null or scene_tree.root == null:
        return null
    return scene_tree.root.get_node_or_null("BuildingRegistry")

func _get_singleton_node(node_name: String) -> Node:
    if not is_inside_tree():
        return null
    var scene_tree: SceneTree = get_tree()
    if scene_tree == null or scene_tree.root == null:
        return null
    return scene_tree.root.get_node_or_null(node_name)
