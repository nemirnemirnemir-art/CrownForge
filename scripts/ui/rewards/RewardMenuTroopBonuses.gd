extends Control
class_name RewardMenuTroopBonuses

@export var offered_count: int = 3
@export var rerolls_left: int = 999
@export var bonus_amount: float = 0.15

@onready var title_label: Label = get_node_or_null("TitleLabel")
@onready var collapse_button: Button = get_node_or_null("CollapseButton")
@onready var reroll_button: Button = get_node_or_null("RerollButton")
@onready var reroll_popup: Control = get_node_or_null("RerollPopup")
@onready var reroll_popup_label: Label = get_node_or_null("RerollPopup/CostRow/CostLabel")
@onready var dim: CanvasItem = get_node_or_null("Dim")

var _cards: Array = []
var _current_ids: Array[String] = []
var _prev_tree_paused: bool = false
var _rerolls_done: int = 0
var _collapsed: bool = false

func _get_autoload(name: String) -> Node:
    return get_node_or_null("/root/%s" % name)

func _event_bus() -> Node:
    return _get_autoload("EventBus")

func _economy_core() -> Node:
    return _get_autoload("EconomyCore")

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

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

    if reroll_button:
        reroll_button.pressed.connect(_on_reroll_pressed)
        reroll_button.mouse_entered.connect(_on_reroll_hover_entered)
        reroll_button.mouse_exited.connect(_on_reroll_hover_exited)

    if collapse_button:
        collapse_button.pressed.connect(_on_collapse_pressed)

    if dim and dim.has_signal("gui_input"):
        dim.gui_input.connect(_on_dim_gui_input)

    if reroll_popup:
        reroll_popup.visible = false

    var event_bus: Node = _event_bus()
    if event_bus != null and event_bus.has_signal("gold_changed"):
        event_bus.connect("gold_changed", Callable(self, "_on_gold_changed"))

    visible = false

func open() -> void:
    visible = true
    _rerolls_done = 0
    _collapsed = false
    _apply_collapsed()
    if get_tree():
        _prev_tree_paused = get_tree().paused
        get_tree().paused = true
    _roll_cards()

func close_menu() -> void:
    visible = false
    _collapsed = false
    if reroll_popup:
        reroll_popup.visible = false
    if get_tree():
        get_tree().paused = _prev_tree_paused

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
    if reroll_popup:
        reroll_popup.visible = false

func _get_pool_ids() -> Array[String]:
    var out: Array[String] = []
    for class_id in range(8):
        out.append("hp_%d" % class_id)
        out.append("dmg_%d" % class_id)
    return out

func _roll_cards() -> void:
    var pool := _get_pool_ids()
    pool.shuffle()

    for i in range(_cards.size()):
        var card = _cards[i]
        if card == null:
            continue

        var should_show := i < offered_count and i < pool.size()
        _current_ids[i] = pool[i] if should_show else ""
        card.visible = should_show
        if should_show and card.has_method("setup"):
            card.setup(_current_ids[i])

    if title_label:
        title_label.text = "Choose a troop bonus"

    _update_popups_text()
    _update_reroll_button_state()

func _update_popups_text() -> void:
    if reroll_popup_label:
        var cost := _get_reroll_cost()
        var economy_core: Node = _economy_core()
        var have := int(economy_core.call("get_gold")) if economy_core != null else 0
        reroll_popup_label.text = "%d / %d" % [have, cost]

func _on_card_selected(offer_id: String) -> void:
    var parts := offer_id.split("_", false)
    if parts.size() != 2:
        return

    var stat_key := String(parts[0])
    var class_id := int(parts[1])
    var stat_id := 0 if stat_key == "hp" else 1

    var troop_core: Object = _get_troop_bonus_core()
    if troop_core:
        troop_core.call("add_bonus_percent", class_id, stat_id, bonus_amount)

    close_menu()

func _on_reroll_pressed() -> void:
    if not _try_pay_reroll():
        return
    _rerolls_done += 1
    _roll_cards()

func _update_reroll_button_state() -> void:
    if reroll_button == null:
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

func _on_dim_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        close_menu()

func _get_troop_bonus_core() -> Object:
    var tree := get_tree()
    if tree == null:
        return null
    var root := tree.root
    if root == null:
        return null
    return root.get_node_or_null("TroopBonusCore")
