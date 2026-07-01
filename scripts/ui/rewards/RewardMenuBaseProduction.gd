extends Control
class_name RewardMenuBaseProduction

@export var building_category: int = int(BuildingConfig.BuildingCategory.BASIC_PRODUCTION)
@export var menu_title: String = "Choose a building"

@export var offered_count: int = 3
@export var rerolls_left: int = 999
@export var exclude_limit: int = 8
@export var recycle_reward_gold: float = 5.0

const EXCLUDED_BUILDING_IDS := {
    "well": true,
}

@onready var title_label: Label = get_node_or_null("TitleLabel")
@onready var collapse_button: Button = get_node_or_null("CollapseButton")
@onready var reroll_button: Button = get_node_or_null("RerollButton")
@onready var recycle_button: Button = get_node_or_null("RecycleButton")
@onready var dim: CanvasItem = get_node_or_null("Dim")

@onready var reroll_popup: Control = get_node_or_null("RerollPopup")
@onready var reroll_popup_label: Label = get_node_or_null("RerollPopup/CostRow/CostLabel")
@onready var recycle_popup: Control = get_node_or_null("RecyclePopup")

var _cards: Array = []
var _excluded: Dictionary = {}
var _excludes_left: int = 0
var _collapsed: bool = false
var _current_ids: Array[String] = []
var _prev_tree_paused: bool = false
var _rerolls_done: int = 0
var _exclude_used_this_open: bool = false

func _get_autoload(name: String) -> Node:
    return get_node_or_null("/root/%s" % name)

func _event_bus() -> Node:
    return _get_autoload("EventBus")

func _economy_core() -> Node:
    return _get_autoload("EconomyCore")

func _building_registry() -> Node:
    return _get_autoload("BuildingRegistry")

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _excludes_left = exclude_limit
    _cards = [
        get_node_or_null("Card1"),
        get_node_or_null("Card2"),
        get_node_or_null("Card3"),
    ]
    _current_ids.clear()
    _current_ids.resize(_cards.size())
    for i in range(_current_ids.size()):
        _current_ids[i] = ""
    for c in _cards:
        if c == null:
            continue
        if c.has_signal("selected"):
            c.selected.connect(_on_card_selected)
        if c.has_signal("excluded"):
            c.excluded.connect(_on_card_excluded)
    _hide_popups()
    visible = false

    if reroll_button:
        reroll_button.pressed.connect(_on_reroll_pressed)
        reroll_button.mouse_entered.connect(_on_reroll_hover_entered)
        reroll_button.mouse_exited.connect(_on_reroll_hover_exited)
    if recycle_button:
        recycle_button.pressed.connect(_on_recycle_pressed)
        recycle_button.mouse_entered.connect(_on_recycle_hover_entered)
        recycle_button.mouse_exited.connect(_on_recycle_hover_exited)
    if collapse_button:
        collapse_button.pressed.connect(_on_collapse_pressed)

    var event_bus: Node = _event_bus()
    if event_bus != null and event_bus.has_signal("gold_changed"):
        event_bus.connect("gold_changed", Callable(self, "_on_gold_changed"))

func open() -> void:
    _collapsed = false
    _rerolls_done = 0
    _exclude_used_this_open = false
    if title_label and menu_title.strip_edges() != "":
        title_label.text = menu_title
    _apply_collapsed()
    visible = true
    if get_tree():
        _prev_tree_paused = get_tree().paused
        get_tree().paused = true
    _roll_cards()

func close_menu() -> void:
    visible = false
    _hide_popups()
    if get_tree():
        get_tree().paused = _prev_tree_paused

func _get_pool_ids() -> Array[String]:
    var ids: Array[String] = []
    var building_registry: Node = _building_registry()
    if building_registry != null:
        var category_to_use := clampi(
            building_category,
            int(BuildingConfig.BuildingCategory.BASIC_PRODUCTION),
            int(BuildingConfig.BuildingCategory.OTHER)
        )
        var configs: Array = building_registry.call("get_buildings_by_category", category_to_use)
        for c in configs:
            if c and c is BuildingConfig and (c as BuildingConfig).building_id != "":
                var building_id := (c as BuildingConfig).building_id
                if EXCLUDED_BUILDING_IDS.has(building_id):
                    continue
                ids.append(building_id)
    return ids

func _roll_cards() -> void:
    var pool := _get_pool_ids()
    var available: Array[String] = []
    for id in pool:
        if not _excluded.has(id):
            available.append(id)
    available.shuffle()

    var allow_exclude := (_excludes_left > 0) and (not _exclude_used_this_open)
    for c in _cards:
        if c and c.has_method("set_exclude_remaining"):
            c.set_exclude_remaining(_excludes_left)
        if c and c.has_method("set_exclude_enabled"):
            c.set_exclude_enabled(allow_exclude)

    for i in range(_cards.size()):
        var card = _cards[i]
        if card == null:
            continue
        var should_show := i < offered_count and i < available.size()
        if should_show:
            _current_ids[i] = available[i]
        else:
            _current_ids[i] = ""
        card.visible = (not _collapsed) and should_show
        if card.visible and card.has_method("setup"):
            card.setup(_current_ids[i])

    _update_popups_text()

    _update_reroll_button_state()

    if recycle_button:
        recycle_button.disabled = _exclude_used_this_open

func _update_popups_text() -> void:
    if reroll_popup_label:
        var cost := _get_reroll_cost()
        var economy_core: Node = _economy_core()
        var have := int(economy_core.call("get_gold")) if economy_core != null else 0
        reroll_popup_label.text = "%d / %d" % [have, cost]

func _hide_popups() -> void:
    if reroll_popup:
        reroll_popup.visible = false
    if recycle_popup:
        recycle_popup.visible = false

func _on_card_selected(building_id: String) -> void:
    var building_registry: Node = _building_registry()
    if building_registry != null and building_registry.has_method("add_recipe"):
        building_registry.call("add_recipe", building_id, 1)
    close_menu()

func _on_card_excluded(building_id: String) -> void:
    if _exclude_used_this_open:
        return
    if _excludes_left <= 0:
        return
    _excluded[building_id] = true
    _excludes_left -= 1
    _exclude_used_this_open = true

    # Hide excluded card without rerolling.
    var idx := _current_ids.find(building_id)
    if idx != -1:
        _current_ids[idx] = ""
        var card = _cards[idx]
        if card:
            card.visible = false

    # Disable further exclude + other global actions after exclude.
    for c in _cards:
        if c and c.has_method("set_exclude_remaining"):
            c.set_exclude_remaining(_excludes_left)
        if c and c.has_method("set_exclude_enabled"):
            c.set_exclude_enabled(false)

    if reroll_button:
        reroll_button.disabled = true
    if recycle_button:
        recycle_button.disabled = true
    _hide_popups()

func _on_reroll_pressed() -> void:
    if _exclude_used_this_open:
        return
    if not _try_pay_reroll():
        return
    _rerolls_done += 1
    _roll_cards()

func _on_recycle_pressed() -> void:
    if _exclude_used_this_open:
        return
    var economy_core: Node = _economy_core()
    if economy_core != null:
        economy_core.call("add_gold", recycle_reward_gold)
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
    for i in range(_cards.size()):
        var c = _cards[i]
        if c:
            c.visible = (not _collapsed) and _current_ids[i] != ""
            if c.visible and c.has_method("setup"):
                c.setup(_current_ids[i])
    if reroll_button:
        reroll_button.visible = not _collapsed
    if recycle_button:
        recycle_button.visible = not _collapsed
    _hide_popups()

func _update_reroll_button_state() -> void:
    if reroll_button == null:
        return
    if _exclude_used_this_open:
        reroll_button.disabled = true
        return
    var economy_core: Node = _economy_core()
    if economy_core == null:
        reroll_button.disabled = true
        return
    reroll_button.disabled = not _can_afford_reroll()

func _artifact_core() -> Node:
    return _get_autoload("ArtifactCore")

func _get_reroll_cost() -> int:
    var artifact_core: Node = _artifact_core()
    if artifact_core != null and artifact_core.has_method("get_reward_reroll_cost"):
        return int(artifact_core.call("get_reward_reroll_cost", _rerolls_done))
    return RerollCost.get_next_reroll_cost(_rerolls_done)

func _try_pay_reroll() -> bool:
    var artifact_core: Node = _artifact_core()
    if artifact_core != null and artifact_core.has_method("try_pay_reward_reroll"):
        var ok := bool(artifact_core.call("try_pay_reward_reroll", _rerolls_done))
        if not ok:
            _update_reroll_button_state()
        return ok
    var economy_core: Node = _economy_core()
    return economy_core != null and bool(economy_core.call("spend_gold", float(_get_reroll_cost())))

func _can_afford_reroll() -> bool:
    var artifact_core: Node = _artifact_core()
    if artifact_core != null and artifact_core.has_method("can_afford_reward_reroll"):
        return bool(artifact_core.call("can_afford_reward_reroll", _rerolls_done))
    var economy_core: Node = _economy_core()
    return economy_core != null and bool(economy_core.call("can_afford", float(_get_reroll_cost())))

func _on_gold_changed(_new_amount: float, _delta: float) -> void:
    _update_popups_text()
    _update_reroll_button_state()

func _on_reroll_hover_entered() -> void:
    if reroll_popup:
        _update_popups_text()
        reroll_popup.visible = true

func _on_reroll_hover_exited() -> void:
    if reroll_popup:
        reroll_popup.visible = false

func _on_recycle_hover_entered() -> void:
    if recycle_popup:
        recycle_popup.visible = true

func _on_recycle_hover_exited() -> void:
    if recycle_popup:
        recycle_popup.visible = false
