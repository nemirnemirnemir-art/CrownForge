extends Control
class_name RewardMenuBuildingUpgrades

@export var offered_count: int = 3

const DEBUG_PREFIX := "[RewardMenuBuildingUpgrades]"
const BuildingUpgradeDataScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeData.gd")

@onready var title_label: Label = get_node_or_null("TitleLabel")
@onready var collapse_button: Button = get_node_or_null("CollapseButton")
@onready var reroll_button: Button = get_node_or_null("RerollButton")
@onready var dim: CanvasItem = get_node_or_null("Dim")

@onready var reroll_popup: Control = get_node_or_null("RerollPopup")
@onready var reroll_popup_label: Label = get_node_or_null("RerollPopup/CostRow/CostLabel")

var _cards: Array = []
var _prev_tree_paused: bool = false
var _rerolls_done: int = 0
var _collapsed: bool = false

func _get_autoload(name: String) -> Node:
    return get_node_or_null("/root/%s" % name)

func _event_bus() -> Node:
    return _get_autoload("EventBus")

func _economy_core() -> Node:
    return _get_autoload("EconomyCore")

func _building_registry() -> Node:
    return _get_autoload("BuildingRegistry")

func _building_upgrade_core() -> Node:
    return _get_autoload("BuildingUpgradeCore")

func _reroll_cost() -> Node:
    return _get_autoload("RerollCost")

func _artifact_core() -> Node:
    return _get_autoload("ArtifactCore")

func _debug(message: String) -> void:
    print("%s %s" % [DEBUG_PREFIX, message])

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _cards = [
        get_node_or_null("Card1"),
        get_node_or_null("Card2"),
        get_node_or_null("Card3"),
    ]
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

    if reroll_popup:
        reroll_popup.visible = false

    if dim and dim.has_signal("gui_input"):
        dim.gui_input.connect(_on_dim_gui_input)

    var event_bus := _event_bus()
    if event_bus and event_bus.has_signal("gold_changed"):
        event_bus.gold_changed.connect(_on_gold_changed)

    visible = false

func open() -> void:
    _debug("open() called")
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
            c.visible = not _collapsed
    if reroll_button:
        reroll_button.visible = not _collapsed
    if reroll_popup:
        reroll_popup.visible = false

func _get_game_scene() -> Node:
    var gs = get_tree().get_first_node_in_group("game_scene")
    if gs == null:
        _debug("GameScene not found via group 'game_scene'")
    return gs

func _get_occupied_slots() -> Array:
    var out: Array = []
    var seen_buildings := {}
    var gs := _get_game_scene()
    if gs == null:
        _debug("_get_occupied_slots(): no game scene")
        return out
    var map_layout: Variant = gs.get("map_layout_node")
    if map_layout == null:
        _debug("_get_occupied_slots(): map_layout_node missing on GameScene")
        return out
    var slots: Variant = map_layout.get("slots")
    if not (slots is Array):
        _debug("_get_occupied_slots(): map_layout.slots missing or not Array")
        return out
    for s in slots:
        if s == null:
            continue
        var building_id: Variant = s.get("current_building_id")
        var slot_index: Variant = s.get("slot_index")
        if typeof(building_id) == TYPE_STRING and String(building_id) != "" and typeof(slot_index) == TYPE_INT:
            var building_id_str := String(building_id)
            if seen_buildings.has(building_id_str):
                continue
            if _is_building_allowed(building_id_str):
                out.append({"slot_index": int(slot_index), "building_id": building_id_str})
                seen_buildings[building_id_str] = true
            else:
                _debug("_get_occupied_slots(): filtered out %s (not eligible)" % building_id_str)
    if out.is_empty():
        _debug("_get_occupied_slots(): no occupied slots detected")
    else:
        _debug("_get_occupied_slots(): found %d entries" % out.size())
    return out

func _is_building_allowed(building_id: String) -> bool:
    var building_registry := _building_registry()
    if building_registry == null:
        return false
    var config: BuildingConfig = building_registry.get_building(building_id)
    if config == null:
        return false
    return BuildingUpgradeDataScript.has_upgrades(building_id)

func _get_upgrade_defs_for_building(building_id: String) -> Array:
    var out: Array = []
    var arr: Array = BuildingUpgradeDataScript.get_upgrades(building_id)
    for v in arr:
        out.append(v)
    return out

func _roll_cards() -> void:
    var raw_pool := _get_occupied_slots()
    var pool: Array = []
    var upgrade_core := _building_upgrade_core()
    for entry_value in raw_pool:
        if not (entry_value is Dictionary):
            continue
        var entry := entry_value as Dictionary
        var slot_index := int(entry.get("slot_index", -1))
        var building_id := String(entry.get("building_id", ""))
        var defs := _get_upgrade_defs_for_building(building_id)
        if defs.is_empty():
            continue
        var available: Array[int] = []
        for idx in range(defs.size()):
            var upgrade_id := "%s:%d" % [building_id, idx]
            var applied := bool(upgrade_core.call("has_building_upgrade", building_id, upgrade_id)) if upgrade_core else false
            if not applied:
                available.append(idx)
        if available.is_empty():
            continue
        pool.append({
            "slot_index": slot_index,
            "building_id": building_id,
            "defs": defs,
            "available": available,
        })

    pool.shuffle()
    _debug("_roll_cards(): pool size after filtering = %d" % pool.size())

    for i in range(_cards.size()):
        var card = _cards[i]
        if card == null:
            _debug("Card index %d missing node" % i)
            continue
        var should_show := i < offered_count and i < pool.size()
        card.visible = should_show
        if not should_show:
            _debug("Card %d hidden (should_show=%s, pool_size=%d)" % [i, str(should_show), pool.size()])
            continue

        var entry: Dictionary = pool[i]
        var slot_index := int(entry.get("slot_index", -1))
        var building_id := String(entry.get("building_id", ""))
        var defs: Array = entry.get("defs", [])
        var available: Array = entry.get("available", [])

        var offer_idx := -1
        if not available.is_empty():
            offer_idx = available.pick_random()
        else:
            _debug("Card %d building %s has no available upgrades (all applied?)" % [i, building_id])

        if card.has_method("setup"):
            card.setup(slot_index, building_id, offer_idx, defs)
            _debug("Card %d setup with slot %d building %s offer_idx %d" % [i, slot_index, building_id, offer_idx])

    _update_popups_text()
    _update_reroll_button_state()

func _update_popups_text() -> void:
    if reroll_popup_label:
        var economy_core := _economy_core()
        var cost := _get_reroll_cost()
        var have := int(economy_core.call("get_gold")) if economy_core else 0
        reroll_popup_label.text = "%d / %d" % [have, cost]

func _update_reroll_button_state() -> void:
    if reroll_button == null:
        return
    var economy_core := _economy_core()
    if economy_core == null:
        reroll_button.disabled = true
        return
    reroll_button.disabled = not _can_afford_reroll()

func _on_gold_changed(_new_amount: float, _delta: float) -> void:
    _update_popups_text()
    _update_reroll_button_state()

func _on_reroll_pressed() -> void:
    var economy_core := _economy_core()
    if economy_core == null:
        return
    if not _try_pay_reroll():
        _update_reroll_button_state()
        return
    _rerolls_done += 1
    _roll_cards()

func _get_reroll_cost() -> int:
    var artifact_core := _artifact_core()
    if artifact_core != null and artifact_core.has_method("get_reward_reroll_cost"):
        return int(artifact_core.call("get_reward_reroll_cost", _rerolls_done))
    var reroll_cost := _reroll_cost()
    return int(reroll_cost.call("get_next_reroll_cost", _rerolls_done)) if reroll_cost else 0

func _try_pay_reroll() -> bool:
    var artifact_core := _artifact_core()
    if artifact_core != null and artifact_core.has_method("try_pay_reward_reroll"):
        return bool(artifact_core.call("try_pay_reward_reroll", _rerolls_done))
    var economy_core := _economy_core()
    return economy_core != null and bool(economy_core.call("spend_gold", float(_get_reroll_cost())))

func _can_afford_reroll() -> bool:
    var artifact_core := _artifact_core()
    if artifact_core != null and artifact_core.has_method("can_afford_reward_reroll"):
        return bool(artifact_core.call("can_afford_reward_reroll", _rerolls_done))
    var economy_core := _economy_core()
    return economy_core != null and bool(economy_core.call("can_afford", float(_get_reroll_cost())))

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

func _on_card_selected(slot_index: int, upgrade_id: String) -> void:
    var upgrade_core := _building_upgrade_core()
    if upgrade_core and upgrade_id != "" and slot_index >= 0:
        upgrade_core.call("apply_upgrade", slot_index, upgrade_id)
    close_menu()
