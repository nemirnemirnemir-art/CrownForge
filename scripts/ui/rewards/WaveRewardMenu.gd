extends Control
class_name WaveRewardMenu

signal closed
signal opened

## Menu that appears after completing a wave showing 4 fixed rewards

const WaveRewardSubmenuRouterScript := preload("res://scripts/ui/rewards/modules/WaveRewardSubmenuRouter.gd")
const WaveRewardCardBuilderScript := preload("res://scripts/ui/rewards/modules/WaveRewardCardBuilder.gd")
const WaveRewardExecutorScript := preload("res://scripts/ui/rewards/modules/WaveRewardExecutor.gd")
const SUBMENU_WAIT_TIMEOUT_SEC: float = 8.0

@onready var title_label: Label = get_node_or_null("TitleLabel")
@onready var collapse_button: Button = get_node_or_null("CollapseButton")
@onready var claim_next_button: Button = get_node_or_null("ClaimNextButton")
@onready var dim: CanvasItem = get_node_or_null("Dim")
@onready var cards_container: Container = get_node_or_null("CardsContainer")

const WaveRewardCardScene: PackedScene = preload("res://scenes/ui/rewards/WaveRewardCard.tscn")

var _cards: Array[WaveRewardCard] = []
var _collapsed: bool = false
var _prev_tree_paused: bool = false
var _prev_tick_speed: float = 1.0
var _waiting_for_submenu: bool = false
var _submenu_node: Control = null
var _reward_override: Array = []
var _submenu_wait_elapsed: float = 0.0
var _prophecy_level: int = 1
var _use_prophecy_defaults: bool = false
var _submenu_router = WaveRewardSubmenuRouterScript.new()
var _card_builder = WaveRewardCardBuilderScript.new()
var _reward_executor = WaveRewardExecutorScript.new()

func _get_scene_tree() -> SceneTree:
    var main_loop := Engine.get_main_loop()
    return main_loop if main_loop is SceneTree else null

func _get_tick_manager() -> Node:
    var tree := _get_scene_tree()
    if tree == null:
        return null
    return tree.root.get_node_or_null("TickManager")

func _get_economy_core() -> Node:
    var tree := _get_scene_tree()
    if tree == null:
        return null
    return tree.root.get_node_or_null("EconomyCore")

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    if claim_next_button:
        claim_next_button.pressed.connect(_on_claim_next_pressed)
    if collapse_button:
        collapse_button.pressed.connect(_on_collapse_pressed)
    
    visible = false

func _process(_delta: float) -> void:
    if not _waiting_for_submenu:
        return

    _submenu_wait_elapsed += _delta

    if _submenu_node == null or not is_instance_valid(_submenu_node):
        print("[WaveRewardMenu][DEBUG] Waiting for submenu but reference is invalid; recovering")
        _recover_from_submenu_wait("lost submenu reference")
        return

    if not _submenu_node.visible:
        print("[WaveRewardMenu] Submenu closed, restoring visibility")
        _recover_from_submenu_wait("submenu closed")
        return

    if _submenu_wait_elapsed >= SUBMENU_WAIT_TIMEOUT_SEC:
        _debug_dump_state("submenu wait watchdog")
        _submenu_wait_elapsed = 0.0

func open(rewards: Array = [], prophecy_level: int = 1, use_prophecy_defaults: bool = false) -> void:
    _collapsed = false
    _cards.clear()
    _waiting_for_submenu = false
    _submenu_node = null
    _reward_override = rewards
    _submenu_wait_elapsed = 0.0
    _prophecy_level = max(1, prophecy_level)
    _use_prophecy_defaults = use_prophecy_defaults
    
    # Clear existing cards
    if cards_container:
        for ch in cards_container.get_children():
            ch.queue_free()
    
    # Create 4 reward cards
    _create_reward_cards()
    
    _apply_collapsed()
    visible = true
    opened.emit()
    
    var tree := _get_scene_tree()
    if tree:
        _prev_tree_paused = tree.paused
        tree.paused = true
    else:
        push_warning("[WaveRewardMenu] SceneTree not available during open(); menu will stay unpaused")
    var tick_manager := _get_tick_manager()
    if tick_manager:
        _prev_tick_speed = float(tick_manager.get("speed_scale"))
        if tick_manager.has_method("pause"):
            tick_manager.call("pause")
    print("[WaveRewardMenu][DEBUG] open | prev_tree_paused=%s current_tree_paused=%s prev_tick_speed=%.2f current_tick_speed=%s" % [
        str(_prev_tree_paused),
        str(tree.paused if tree else null),
        _prev_tick_speed,
        str(tick_manager.get("speed_scale") if tick_manager else null),
    ])
    
    var shown_count := 0
    if cards_container:
        shown_count = cards_container.get_child_count()
    print("[WaveRewardMenu] Opened with %d rewards" % shown_count)
    _debug_dump_state("open")

func close_menu() -> void:
    print("[WaveRewardMenu] Closing menu, unpausing game")
    visible = false
    var tree := _get_scene_tree()
    if tree:
        tree.paused = _prev_tree_paused
    var tick_manager := _get_tick_manager()
    if tick_manager and tick_manager.has_method("set_speed"):
        tick_manager.call("set_speed", _prev_tick_speed)
    print("[WaveRewardMenu][DEBUG] close | restore_tree_paused=%s current_tree_paused=%s restore_tick_speed=%.2f current_tick_speed=%s" % [
        str(_prev_tree_paused),
        str(tree.paused if tree else null),
        _prev_tick_speed,
        str(tick_manager.get("speed_scale") if tick_manager else null),
    ])
    closed.emit()

func _recover_from_submenu_wait(reason: String) -> void:
    print("[WaveRewardMenu][DEBUG] Recovering submenu wait: %s" % reason)
    _waiting_for_submenu = false
    _submenu_node = null
    _submenu_wait_elapsed = 0.0
    # Check immediately before making visible to avoid empty-menu flash
    var remaining := _get_remaining_card_count()
    if remaining == 0:
        close_menu()
        return
    visible = true

func _debug_dump_state(context: String) -> void:
    var cards_count := 0
    if cards_container:
        cards_count = cards_container.get_child_count()

    var submenu_valid := _submenu_node != null and is_instance_valid(_submenu_node)
    var submenu_name := "null"
    var submenu_visible := false
    if submenu_valid:
        submenu_name = _submenu_node.name
        submenu_visible = _submenu_node.visible

    var tree_paused := false
    var tree: SceneTree = null
    if is_inside_tree():
        tree = _get_scene_tree()
    if tree:
        tree_paused = tree.paused

    var tick_speed := -1.0
    var tick_manager := _get_tick_manager()
    if tick_manager:
        tick_speed = float(tick_manager.get("speed_scale"))

    print("[WaveRewardMenu][DEBUG] %s | visible=%s waiting=%s cards=%d submenu_valid=%s submenu=%s submenu_visible=%s tree_paused=%s tick_speed=%.2f rewards=%d" % [
        context,
        str(visible),
        str(_waiting_for_submenu),
        cards_count,
        str(submenu_valid),
        submenu_name,
        str(submenu_visible),
        str(tree_paused),
        tick_speed,
        _reward_override.size()
    ])

func _create_reward_cards() -> void:
    if not cards_container:
        return
    
    var rewards := _build_rewards_for_cards()
    
    for reward_data in rewards:
        var card := WaveRewardCardScene.instantiate() as WaveRewardCard
        cards_container.add_child(card)
        card.setup(reward_data.type, reward_data.icon, reward_data.text)
        card.claim_reward.connect(_on_reward_claimed)
        _cards.append(card)

func _build_rewards_for_cards() -> Array:
    var build_result: Dictionary = _card_builder.build(_reward_override, _use_prophecy_defaults, _prophecy_level)
    _reward_override = build_result.get("resolved_override", []) as Array
    return build_result.get("cards", []) as Array

func _on_reward_claimed(reward_type: String) -> void:
    print("[WaveRewardMenu] Reward claimed: %s" % reward_type)
    _debug_dump_state("claim_reward %s" % reward_type)

    if _reward_executor.execute(reward_type, _get_economy_core, _open_submenu):
        _check_all_claimed()

func _open_submenu(menu_type: String, amount: int = 0) -> void:
    _submenu_router.open(menu_type, amount, _get_scene_tree(), self, Callable(self, "_recover_from_submenu_wait"), _debug_dump_state)

func _open_established_production_submenu() -> void:
    _open_submenu("production_established")

func _open_infrastructure_submenu() -> void:
    _open_submenu("infrastructure")

func _check_all_claimed() -> void:
    var remaining := _get_remaining_card_count()
    
    print("[WaveRewardMenu] Checking remaining cards: %d" % remaining)
    if _waiting_for_submenu:
        print("[WaveRewardMenu][DEBUG] Waiting for submenu while checking cards")
    
    if remaining == 0 and not _waiting_for_submenu:
        print("[WaveRewardMenu] All rewards claimed, closing and unpausing")
        close_menu()


func _get_remaining_card_count() -> int:
    if cards_container == null:
        return 0

    var remaining := 0
    for child in cards_container.get_children():
        var card := child as WaveRewardCard
        if card == null or not card.is_claimed:
            remaining += 1
    return remaining


func has_active_reward_chain() -> bool:
    if _waiting_for_submenu:
        return true
    if visible:
        return true
    return _get_remaining_card_count() > 0

func _on_claim_next_pressed() -> void:
    # Find first remaining card and claim it
    _debug_dump_state("claim_next pressed")
    if not cards_container:
        return
    
    var children := cards_container.get_children()
    for child in children:
        var first_card := child as WaveRewardCard
        if first_card and first_card.has_method("_on_claim_pressed"):
            first_card._on_claim_pressed()
            return

    print("[WaveRewardMenu][DEBUG] Claim next found no claimable cards")
    close_menu()

func _on_collapse_pressed() -> void:
    _collapsed = not _collapsed
    _apply_collapsed()

func _apply_collapsed() -> void:
    if collapse_button:
        collapse_button.text = "▲" if _collapsed else "▼"
    if title_label:
        title_label.visible = not _collapsed
    if dim:
        dim.visible = not _collapsed
    if claim_next_button:
        claim_next_button.visible = not _collapsed
    if cards_container:
        cards_container.visible = not _collapsed
