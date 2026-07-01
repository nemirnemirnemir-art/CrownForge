extends Node2D

const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const PlayerStateScript = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const TurnFlowScript = preload("res://scripts/dev/ten_kings/TenKingsTurnFlow.gd")
const BattleManagerScript = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const BoardSlotUIScript = preload("res://scripts/dev/ten_kings/TenKingsBoardSlotUI.gd")
const HandCardUIScript = preload("res://scripts/dev/ten_kings/TenKingsHandCardUI.gd")
const ArenaGeometryService = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")
const PLAYER_BOARD_SLOT_SIZE: float = 104.0
const AI_POPUP_SLOT_SIZE: float = 56.0

@onready var battle_layer: Node2D = $BattleLayer
@onready var camera: Camera2D = $Camera2D
@onready var phase_label: Label = $UI/Root/MainVBox/TopPanel/Margin/Row/PhaseLabel
@onready var year_label: Label = $UI/Root/MainVBox/TopPanel/Margin/Row/YearLabel
@onready var player_castle_label: Label = $UI/Root/MainVBox/TopPanel/Margin/Row/PlayerCastleLabel
@onready var ai_castle_label: Label = $UI/Root/MainVBox/TopPanel/Margin/Row/AiCastleLabel
@onready var castle_fire_mode_button: Button = $UI/Root/MainVBox/TopPanel/Margin/Row/CastleFireModeButton
@onready var end_turn_button: Button = $UI/Root/MainVBox/TopPanel/Margin/Row/EndTurnButton
@onready var player_grid: GridContainer = $UI/Root/MainVBox/MiddleHBox/PlayerBoardPanel/Margin/VBox/Slots
@onready var ai_grid: GridContainer = $UI/Root/AiBoardPopup/Margin/VBox/Slots
@onready var hand_cards: HBoxContainer = $UI/Root/MainVBox/BottomPanel/Margin/VBox/HandScroll/HandCards
@onready var offer_panel: PanelContainer = $UI/Root/OfferPanel
@onready var offer_buttons: HBoxContainer = $UI/Root/OfferPanel/Margin/VBox/Buttons
@onready var offer_title: Label = $UI/Root/OfferPanel/Margin/VBox/Title
@onready var status_label: Label = $UI/Root/MainVBox/BottomPanel/Margin/VBox/StatusLabel
@onready var help_label: Label = $UI/Root/MainVBox/BottomPanel/Margin/VBox/HelpLabel
@onready var board_tooltip: PanelContainer = $UI/Root/BoardTooltip
@onready var ui_background: ColorRect = $UI/Root/Background
@onready var arena_panel: PanelContainer = $UI/Root/MainVBox/MiddleHBox/ArenaPanel
@onready var player_board_panel: PanelContainer = $UI/Root/MainVBox/MiddleHBox/PlayerBoardPanel
@onready var ai_board_button: Button = $UI/Root/AiBoardButton
@onready var restart_button: Button = $UI/Root/RestartButton
@onready var ai_board_popup: PanelContainer = $UI/Root/AiBoardPopup
@onready var ai_board_popup_close_button: Button = $UI/Root/AiBoardPopup/Margin/VBox/Header/CloseButton

var _player: RefCounted = null
var _ai_player: RefCounted = null
var _turn_flow: RefCounted = null
var _battle_manager: Node2D = null
var _arena_geometry: RefCounted = null
var _player_slots: Dictionary = {}
var _ai_slots: Dictionary = {}
var _player_offer: Array[StringName] = []
var _hovered_slot_pos: Variant = null
var _hovered_slot_side: int = -1  # 0 = player, 1 = AI
var _arena_panel_original_stylebox: StyleBox = null
var _player_board_panel_mouse_filter: int = Control.MOUSE_FILTER_STOP


func _ready() -> void:
    add_to_group("game_scene")
    camera.position = Vector2.ZERO
    camera.zoom = Vector2.ONE
    end_turn_button.pressed.connect(_on_end_turn_pressed)
    ai_board_button.pressed.connect(_on_ai_board_button_pressed)
    if restart_button != null:
        restart_button.pressed.connect(_on_restart_button_pressed)
    ai_board_popup_close_button.pressed.connect(_on_ai_board_popup_close_pressed)
    castle_fire_mode_button.toggled.connect(_on_castle_fire_mode_toggled)
    offer_panel.visible = false
    ai_board_popup.visible = false
    if player_board_panel != null:
        _player_board_panel_mouse_filter = player_board_panel.mouse_filter
    _build_board_slots()
    _setup_runtime()
    _refresh_all()
    _set_status("Place your Castle onto any unlocked slot.")


func _setup_runtime() -> void:
    _player = PlayerStateScript.new("Player", false)
    _ai_player = PlayerStateScript.new("AI", true)
    _turn_flow = TurnFlowScript.new()
    _battle_manager = BattleManagerScript.new()
    _arena_geometry = ArenaGeometryService.new()
    battle_layer.add_child(_battle_manager)

    _turn_flow.phase_changed.connect(_on_phase_changed)
    _turn_flow.year_started.connect(_on_year_started)
    _turn_flow.year_effects_applied.connect(_on_year_effects_applied)
    _turn_flow.battle_requested.connect(_on_battle_requested)
    _turn_flow.battle_result_received.connect(_on_battle_result_received)
    _turn_flow.offer_generated.connect(_on_offer_generated)
    _turn_flow.slot_unlocked.connect(_on_slot_unlocked)
    _turn_flow.game_over.connect(_on_game_over)
    _turn_flow.ai_cards_played.connect(_on_ai_cards_played)
    _turn_flow.ai_castle_placed.connect(_on_ai_castle_placed)

    _battle_manager.battle_started.connect(_on_battle_started)
    _battle_manager.battle_ended.connect(_on_battle_ended)

    _turn_flow.setup(_player, _ai_player)


func _process(_delta: float) -> void:
    # Handle manual castle fire during battle
    _process_manual_castle_fire()


func _process_manual_castle_fire() -> void:
    # Only process during active battle with manual mode
    if _battle_manager == null:
        return
    if _battle_manager.player_castle_fire_mode != "manual":
        return
    if _turn_flow == null or _turn_flow.get_phase() != TurnFlowScript.Phase.BATTLE:
        return
    
    # Check if mouse button is held down
    if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        return
    
    # Get mouse position and check if it's inside the arena panel area
    var mouse_pos: Vector2 = get_viewport().get_mouse_position()
    if arena_panel == null:
        return
    
    var arena_rect: Rect2 = arena_panel.get_global_rect()
    if not arena_rect.has_point(mouse_pos):
        return
    
    # Convert screen position to battle world position
    var battle_world_pos: Vector2 = _screen_to_battle_world(mouse_pos)
    var battle_local_pos: Vector2 = battle_layer.to_local(battle_world_pos)
    
    # Request manual fire (respects cooldown internally)
    var fired: bool = _battle_manager.request_manual_castle_fire(battle_local_pos)
    if fired:
        print("[TenKingsPrototype] Manual castle fire at: ", battle_local_pos)


func _build_board_slots() -> void:
    _clear_children(player_grid)
    _clear_children(ai_grid)
    _player_slots.clear()
    _ai_slots.clear()

    for y: int in range(5):
        for x: int in range(5):
            var pos := Vector2i(x, y)

            var player_slot = BoardSlotUIScript.new()
            player_slot.setup(pos, PLAYER_BOARD_SLOT_SIZE)
            player_slot.connect("card_dropped", Callable(self, "_on_player_slot_card_dropped"))
            player_slot.connect("slot_hover_started", Callable(self, "_on_player_slot_hover_started"))
            player_slot.connect("slot_hover_ended", Callable(self, "_on_slot_hover_ended"))
            player_grid.add_child(player_slot)
            _player_slots[pos] = player_slot

            var ai_slot = BoardSlotUIScript.new()
            ai_slot.setup(pos, AI_POPUP_SLOT_SIZE)
            ai_slot.connect("slot_hover_started", Callable(self, "_on_ai_slot_hover_started"))
            ai_slot.connect("slot_hover_ended", Callable(self, "_on_slot_hover_ended"))
            ai_grid.add_child(ai_slot)
            _ai_slots[pos] = ai_slot


func _refresh_all() -> void:
    _refresh_labels()
    _refresh_board_ui(_player, _player_slots)
    _refresh_board_ui(_ai_player, _ai_slots)
    _refresh_hand_ui()


func _refresh_labels() -> void:
    if _turn_flow == null:
        return

    phase_label.text = "Phase: %s" % _get_phase_name(_turn_flow.get_phase())
    year_label.text = "Year: %d" % _turn_flow.current_year

    if _player != null:
        player_castle_label.text = "Player Castle: %d HP" % _get_player_castle_hp(_player)
    if _ai_player != null:
        ai_castle_label.text = "AI Castle: %d HP" % _get_player_castle_hp(_ai_player)

    end_turn_button.disabled = not _turn_flow.can_end_turn()
    offer_title.text = "Choose one card"
    help_label.text = _get_phase_help(_turn_flow.get_phase())


func _refresh_board_ui(player_state: RefCounted, slot_map: Dictionary) -> void:
    if player_state == null:
        return
    var board: RefCounted = _get_player_board(player_state)
    if board == null:
        return

    # Determine which side this is (0=player, 1=ai)
    var side: int = 1 if player_state == _ai_player else 0

    for pos: Vector2i in slot_map.keys():
        var slot_ui = slot_map[pos]
        var state: int = int(board.call("get_slot_state", pos))
        if state == 2:
            var slot_data: RefCounted = board.call("get_slot_data", pos)
            var damage_total := 0
            if _battle_manager != null:
                damage_total = _battle_manager.get_slot_damage_total(side, pos)
            slot_ui.callv("update_display", [
                state,
                _get_slot_icon_texture(_get_slot_card_id(slot_data)),
                _get_slot_level(slot_data),
                _build_slot_info(slot_data, player_state),
                _get_slot_pack_icon_count(slot_data)
            ])
            slot_ui.call("set_preview_data", _build_slot_preview_data(slot_data, side, damage_total))
        else:
            slot_ui.callv("update_display", [state, null, 0, "", 0])
            slot_ui.call("set_preview_data", {})

        # Update damage display for this slot
        if _battle_manager != null:
            var damage_total = _battle_manager.get_slot_damage_total(side, pos)
            slot_ui.call("set_slot_damage_total", damage_total)



func _refresh_hand_ui() -> void:
    _clear_children(hand_cards)
    if _player == null:
        return

    for card_id: StringName in _get_player_hand_cards(_player):
        var card_node: PanelContainer = HandCardUIScript.new()
        card_node.setup(card_id)
        hand_cards.add_child(card_node)


func _show_offer(player_offer: Array) -> void:
    _player_offer.clear()
    _clear_children(offer_buttons)

    for item: Variant in player_offer:
        _player_offer.append(StringName(item))

    offer_panel.visible = true
    for card_id: StringName in _player_offer:
        var card_def: Dictionary = CardLib.get_card_def(card_id)
        var button := Button.new()
        button.custom_minimum_size = Vector2(120.0, 44.0)
        button.text = String(card_def.get("display_name", str(card_id)))
        button.pressed.connect(_on_offer_button_pressed.bind(card_id))
        offer_buttons.add_child(button)


func _on_player_slot_card_dropped(slot_pos: Vector2i, card_id: StringName) -> void:
    if _turn_flow == null:
        return

    var phase: int = _turn_flow.get_phase()
    var success: bool = false

    if phase == TurnFlowScript.Phase.CASTLE_PLACEMENT:
        if card_id != CardLib.CARD_CASTLE:
            _set_status("Castle must be placed first.")
            return
        success = _turn_flow.player_place_castle(slot_pos)
    elif phase == TurnFlowScript.Phase.PREP:
        success = _turn_flow.player_play_card(card_id, slot_pos)
    else:
        _set_status("Cards cannot be played during %s." % _get_phase_name(phase))
        return

    if not success:
        _set_status("Cannot place %s on that slot." % _get_card_name(card_id))
        return

    _refresh_all()
    _set_status("Placed %s." % _get_card_name(card_id))


func _on_end_turn_pressed() -> void:
    print("[TenKingsPrototype] _on_end_turn_pressed called")
    if _turn_flow == null:
        print("[TenKingsPrototype] ERROR: _turn_flow is null")
        return
    if _turn_flow.get_phase() != TurnFlowScript.Phase.PREP:
        print("[TenKingsPrototype] Not in PREP phase, ignoring")
        return

    # Check if player has at least one troop on board
    if not _player.board.has_troop_on_board():
        print("[TenKingsPrototype] No troop on board, blocking end turn")
        _set_status("Place at least one troop before ending turn.")
        return

    print("[TenKingsPrototype] Calling player_end_turn...")
    _set_status("AI is taking its turn...")
    _turn_flow.player_end_turn()
    _refresh_all()
    print("[TenKingsPrototype] _on_end_turn_pressed complete")



func _on_phase_changed(_new_phase: int) -> void:
    _refresh_labels()
    if _turn_flow.get_phase() != TurnFlowScript.Phase.OFFER:
        offer_panel.visible = false


func _on_year_started(year: int) -> void:
    _refresh_labels()
    _refresh_hand_ui()
    _set_status("Year %d begins." % year)


func _on_year_effects_applied(player_summary: Dictionary, ai_summary: Dictionary) -> void:
    var player_units: int = int(player_summary.get("units_added", 0))
    var ai_units: int = int(ai_summary.get("units_added", 0))
    var player_bonus: int = int(round(float(player_summary.get("dmg_bonus_added", 0.0)) * 100.0))
    var ai_bonus: int = int(round(float(ai_summary.get("dmg_bonus_added", 0.0)) * 100.0))
    _refresh_board_ui(_player, _player_slots)
    _refresh_board_ui(_ai_player, _ai_slots)
    _set_status("Year effects: Player +%d units / +%d%% dmg, AI +%d units / +%d%% dmg." % [player_units, player_bonus, ai_units, ai_bonus])


func _on_battle_requested() -> void:
    print("[TenKingsPrototype] _on_battle_requested called")
    offer_panel.visible = false
    _set_status("Battle started.")
    
    # Setup arena geometry based on viewport
    _update_arena_geometry()
    
    var anchors = get_arena_anchors()
    print("[TenKingsPrototype] Arena anchors: ", anchors)
    _battle_manager.set_arena_anchors(anchors)
    _battle_manager.set_arena_geometry(_arena_geometry)
    
    var player_origins = _build_battle_slot_origin_map(_player, _player_slots)
    var ai_origins = _build_battle_slot_origin_map(_ai_player, _ai_slots)
    print("[TenKingsPrototype] Player origins: ", player_origins)
    print("[TenKingsPrototype] AI origins: ", ai_origins)
    var battle_manager_parent_name: String = "NO PARENT"
    if _battle_manager.get_parent() != null:
        battle_manager_parent_name = str(_battle_manager.get_parent().name)
    print("[TenKingsPrototype] BattleManager parent: ", battle_manager_parent_name)
    print("[TenKingsPrototype] BattleLayer visible: ", battle_layer.visible)
    print("[TenKingsPrototype] BattleLayer position: ", battle_layer.position)
    print("[TenKingsPrototype] BattleLayer z_index: ", battle_layer.z_index)
    
    _battle_manager.start_battle(_player, _ai_player, player_origins, ai_origins)
    print("[TenKingsPrototype] start_battle called")


func _on_battle_started() -> void:
    print("[TenKingsPrototype] _on_battle_started signal received")
    if _battle_manager != null:
        print("[TenKingsPrototype] BattleManager child count: ", _battle_manager.get_child_count())
        for child in _battle_manager.get_children():
            print("[TenKingsPrototype]   Child: ", child.name, " visible: ", child.visible if child is CanvasItem else "N/A")
            if child.name == "BattleUnits":
                print("[TenKingsPrototype]   BattleUnits has ", child.get_child_count(), " children")
                for unit in child.get_children():
                    var unit_pos: Variant = "N/A"
                    if unit is Node2D:
                        unit_pos = unit.position
                    print("[TenKingsPrototype]	 Unit: ", unit.name, " pos: ", unit_pos, " visible: ", unit.visible if unit is CanvasItem else "N/A")

    if ui_background != null:
        ui_background.visible = false
        print("[TenKingsPrototype] UI background hidden to show battle")
    if ai_board_popup != null:
        ai_board_popup.visible = false
    _set_player_board_battle_mode(true)
    _set_arena_panel_battle_mode(true)
    _set_status("Units are fighting in the arena...")


func _on_battle_ended(winner_side: int) -> void:
    print("[TenKingsPrototype] _on_battle_ended signal received, winner_side: ", winner_side)
    if ui_background != null:
        ui_background.visible = true
        print("[TenKingsPrototype] UI background restored after battle")
    _set_player_board_battle_mode(false)
    _set_arena_panel_battle_mode(false)
    _battle_manager.cleanup()
    _turn_flow.on_battle_ended(winner_side)
    _refresh_all()


func _on_restart_button_pressed() -> void:
    _reload_current_scene()


func _reload_current_scene() -> void:
    get_tree().reload_current_scene()


func _on_battle_result_received(winner_side: int) -> void:
    if winner_side == 0:
        _set_status("Player wins the battle.")
    else:
        _set_status("AI wins the battle.")
    _refresh_labels()


func _on_offer_generated(player_offer: Array, _ai_offer: Array) -> void:
    _show_offer(player_offer)


func _on_offer_button_pressed(card_id: StringName) -> void:
    offer_panel.visible = false
    _turn_flow.player_accept_offer(card_id)
    _refresh_all()
    _set_status("Picked %s from the offer." % _get_card_name(card_id))


func _on_slot_unlocked(side: int, pos: Vector2i) -> void:
    _refresh_board_ui(_player, _player_slots)
    _refresh_board_ui(_ai_player, _ai_slots)
    if side == 0:
        _set_status("Player unlocked slot (%d, %d)." % [pos.x, pos.y])
    else:
        _set_status("AI unlocked slot (%d, %d)." % [pos.x, pos.y])


func _on_game_over(winner_side: int) -> void:
    offer_panel.visible = false
    end_turn_button.disabled = true
    if winner_side == 0:
        _set_status("Game over: Player wins the match.")
    else:
        _set_status("Game over: AI wins the match.")
    _refresh_labels()


func _on_ai_cards_played(actions: Array) -> void:
    _refresh_board_ui(_ai_player, _ai_slots)
    if actions.is_empty():
        _set_status("AI ends its turn without playing a card.")
        return
    _set_status("AI played %d card(s)." % actions.size())


func _on_ai_castle_placed(pos: Vector2i) -> void:
    _refresh_board_ui(_ai_player, _ai_slots)
    _set_status("AI placed its Castle at (%d, %d)." % [pos.x, pos.y])


func _on_castle_fire_mode_toggled(is_auto: bool) -> void:
    if _battle_manager == null:
        return
    if is_auto:
        _battle_manager.player_castle_fire_mode = "auto"
        castle_fire_mode_button.text = "[Auto]"
    else:
        _battle_manager.player_castle_fire_mode = "manual"
        castle_fire_mode_button.text = "[Manual]"
    print("[TenKingsPrototype] Castle fire mode changed to: ", _battle_manager.player_castle_fire_mode)


func _build_slot_info(slot_data: RefCounted, player_state: RefCounted) -> String:
    var lines: Array[String] = []
    var card_id: StringName = _get_slot_card_id(slot_data)
    var level: int = _get_slot_level(slot_data)
    var stats: Dictionary = CardLib.get_stats_for_level(card_id, level)

    if card_id == CardLib.CARD_CASTLE:
        lines.append("HP %d" % _get_player_castle_hp(player_state))
    elif CardLib.is_troop(card_id):
        var total_units: int = int(stats.get("units", 0)) + _get_slot_extra_units(slot_data)
        lines.append("x%d" % total_units)
    elif card_id == CardLib.CARD_FARM:
        lines.append("+%d/year" % int(stats.get("farm_bonus", 0)))
    elif card_id == CardLib.CARD_BLACKSMITH:
        lines.append("+%d%%/year" % int(round(float(stats.get("smith_bonus", 0.0)) * 100.0)))

    var smith_bonus: float = _get_slot_smith_dmg_bonus(slot_data)
    if smith_bonus > 0.0:
        lines.append("+%d%% dmg" % int(round(smith_bonus * 100.0)))
    var steel_coat_stacks: int = _get_slot_steel_coat_stacks(slot_data)
    if steel_coat_stacks > 0:
        lines.append("Block %d" % steel_coat_stacks)

    return "\n".join(lines)


func _get_slot_total_units(slot_data: RefCounted) -> int:
    var card_id: StringName = _get_slot_card_id(slot_data)
    if not CardLib.is_troop(card_id):
        return 0
    var stats: Dictionary = CardLib.get_stats_for_level(card_id, _get_slot_level(slot_data))
    return int(stats.get("units", 0)) + _get_slot_extra_units(slot_data)


func _get_slot_pack_icon_count(slot_data: RefCounted) -> int:
    var total_units: int = _get_slot_total_units(slot_data)
    if total_units <= 0:
        return 0
    if total_units <= 9:
        return 3
    if total_units <= 18:
        return 6
    return 9


func _build_slot_preview_data(slot_data: RefCounted, side: int, damage_total: int) -> Dictionary:
    var card_id: StringName = _get_slot_card_id(slot_data)
    return {
        "card_id": card_id,
        "side": side,
        "stack_count": _get_slot_total_units(slot_data),
        "level": _get_slot_level(slot_data),
        "kind": "troop" if CardLib.is_troop(card_id) else "building",
        "damage_total": damage_total,
    }


func _get_slot_icon_texture(card_id: StringName) -> Texture2D:
    var card_def: Dictionary = CardLib.get_card_def(card_id)
    if card_def.is_empty() or not card_def.has("icon_path"):
        return null
    var icon_path: String = String(card_def["icon_path"])
    if not ResourceLoader.exists(icon_path):
        return null
    return load(icon_path) as Texture2D


func _get_player_board(player_state: RefCounted) -> RefCounted:
    var board_value: Variant = player_state.get("board")
    if board_value is RefCounted:
        return board_value
    return null


func _get_player_castle_hp(player_state: RefCounted) -> int:
    return int(player_state.get("castle_hp"))



func _get_player_hand_cards(player_state: RefCounted) -> Array[StringName]:
    var raw_hand: Variant = player_state.get("hand")
    var result: Array[StringName] = []
    if not (raw_hand is Array):
        return result
    for card_value: Variant in raw_hand:
        result.append(StringName(card_value))
    return result


func _get_slot_card_id(slot_data: RefCounted) -> StringName:
    return StringName(slot_data.get("card_id"))


func _get_slot_level(slot_data: RefCounted) -> int:
    return int(slot_data.get("level"))


func _get_slot_extra_units(slot_data: RefCounted) -> int:
    return int(slot_data.get("extra_units"))


func _get_slot_smith_dmg_bonus(slot_data: RefCounted) -> float:
    return float(slot_data.get("smith_dmg_bonus"))


func _get_slot_steel_coat_stacks(slot_data: RefCounted) -> int:
    return int(slot_data.get("steel_coat_stacks"))


func _get_phase_name(phase: int) -> String:
    match phase:
        TurnFlowScript.Phase.CASTLE_PLACEMENT:
            return "Castle Placement"
        TurnFlowScript.Phase.PREP:
            return "Preparation"
        TurnFlowScript.Phase.YEAR_EFFECTS:
            return "Year Effects"
        TurnFlowScript.Phase.BATTLE:
            return "Battle"
        TurnFlowScript.Phase.POST_BATTLE:
            return "Post Battle"
        TurnFlowScript.Phase.OFFER:
            return "Offer"
        TurnFlowScript.Phase.SLOT_UNLOCK:
            return "Slot Unlock"
        TurnFlowScript.Phase.GAME_OVER:
            return "Game Over"
        _:
            return "Unknown"


func _get_phase_help(phase: int) -> String:
    match phase:
        TurnFlowScript.Phase.CASTLE_PLACEMENT:
            return "Drag Castle from your hand onto the left board."
        TurnFlowScript.Phase.PREP:
            return "Drag cards onto your board, then press End Turn."
        TurnFlowScript.Phase.BATTLE:
            return "Battle resolves automatically in the center arena."
        TurnFlowScript.Phase.OFFER:
            return "Choose one offered card to add to your hand."
        TurnFlowScript.Phase.GAME_OVER:
            return "Match finished."
        _:
            return "Prototype flow is running automatically."


func _get_card_name(card_id: StringName) -> String:
    var card_def: Dictionary = CardLib.get_card_def(card_id)
    if card_def.is_empty():
        return str(card_id)
    return String(card_def.get("display_name", str(card_id)))


func _set_status(text: String) -> void:
    status_label.text = text


func _build_battle_slot_origin_map(player_state, slot_map) -> Dictionary:
    var result = {}
    if player_state == null:
        return result
    var board = _get_player_board(player_state)
    if board == null:
        return result

    for pos in board.get_occupied_slots():
        if not slot_map.has(pos):
            continue
        var slot_ui = slot_map[pos]
        result[pos] = _get_slot_center_in_battle_layer(slot_ui)
    return result


func _get_slot_center_in_battle_layer(slot_ui) -> Vector2:
    if slot_ui == null:
        return Vector2.ZERO
    var screen_center = slot_ui.get_global_rect().get_center()
    var world_center = _screen_to_battle_world(screen_center)
    return battle_layer.to_local(world_center)


func _screen_to_battle_world(screen_position: Vector2) -> Vector2:
    var viewport_size = get_viewport_rect().size
    var viewport_center = viewport_size * 0.5
    var zoom = Vector2.ONE
    if camera != null:
        zoom = camera.zoom
        return camera.global_position + (screen_position - viewport_center) * zoom
    return screen_position - viewport_center


func _clear_children(node: Node) -> void:
    for child: Node in node.get_children():
        node.remove_child(child)
        child.queue_free()


# ---------------------------------------------------------------------------
# Hover tooltip handlers
# ---------------------------------------------------------------------------

func _on_player_slot_hover_started(slot_pos: Vector2i) -> void:
    _show_tooltip_for_slot(slot_pos, 0)


func _on_ai_slot_hover_started(slot_pos: Vector2i) -> void:
    _show_tooltip_for_slot(slot_pos, 1)


func _on_slot_hover_ended(_slot_pos: Vector2i) -> void:
    _hovered_slot_pos = null
    _hovered_slot_side = -1
    if board_tooltip != null:
        board_tooltip.call("hide_tooltip")


func _show_tooltip_for_slot(slot_pos: Vector2i, side: int) -> void:
    _hovered_slot_pos = slot_pos
    _hovered_slot_side = side

    var player_state: RefCounted = _player if side == 0 else _ai_player
    if player_state == null:
        return

    var board: RefCounted = _get_player_board(player_state)
    if board == null:
        return

    var state: int = int(board.call("get_slot_state", slot_pos))
    if state != BoardSlotUIScript.STATE_OCCUPIED:
        if board_tooltip != null:
            board_tooltip.call("hide_tooltip")
        return

    var slot_data: RefCounted = board.call("get_slot_data", slot_pos)
    if slot_data == null:
        return

    var details: Dictionary = _build_tooltip_details(slot_data, player_state)
    var mouse_pos: Vector2 = get_viewport().get_mouse_position()

    if board_tooltip != null:
        board_tooltip.call("show_for_slot", details, mouse_pos)


func _on_ai_board_button_pressed() -> void:
    if ai_board_popup == null:
        return
    ai_board_popup.visible = not ai_board_popup.visible


func _on_ai_board_popup_close_pressed() -> void:
    if ai_board_popup == null:
        return
    ai_board_popup.visible = false



func _build_tooltip_details(slot_data: RefCounted, player_state: RefCounted) -> Dictionary:
    var card_id: StringName = _get_slot_card_id(slot_data)
    var level: int = _get_slot_level(slot_data)
    var card_def: Dictionary = CardLib.get_card_def(card_id)
    var stats: Dictionary = CardLib.get_stats_for_level(card_id, level)

    var details: Dictionary = {
        "display_name": String(card_def.get("display_name", str(card_id))),
        "level": level
    }

    # Troop units
    if CardLib.is_troop(card_id):
        var total_units: int = int(stats.get("units", 0)) + _get_slot_extra_units(slot_data)
        details["units"] = total_units

    # Smith bonus
    var smith_bonus: float = _get_slot_smith_dmg_bonus(slot_data)
    if smith_bonus > 0.0:
        details["smith_bonus"] = smith_bonus

    # Steel coat stacks
    var steel_coat_stacks: int = _get_slot_steel_coat_stacks(slot_data)
    if steel_coat_stacks > 0:
        details["steel_coat_stacks"] = steel_coat_stacks

    # Castle HP
    if card_id == CardLib.CARD_CASTLE:
        details["is_castle"] = true
        details["castle_hp"] = _get_player_castle_hp(player_state)

    # Building flag
    if not CardLib.is_troop(card_id) and card_id != CardLib.CARD_CASTLE:
        details["is_building"] = true

    return details


# ---------------------------------------------------------------------------
# Arena panel battle mode (keep layout, hide content)
# ---------------------------------------------------------------------------

## Sets arena panel to battle mode: makes it transparent and hides children
## so the battle is visible, but the panel still occupies space in the layout.
func _set_arena_panel_battle_mode(battle_mode: bool) -> void:
    if arena_panel == null:
        return
    
    if battle_mode:
        # Save original stylebox and replace with empty to hide panel background
        if _arena_panel_original_stylebox == null:
            _arena_panel_original_stylebox = arena_panel.get_theme_stylebox("panel")
        arena_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
        # Also set self_modulate for any residual drawing
        arena_panel.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
        # Hide all children (the content inside the panel)
        for child in arena_panel.get_children():
            if child is CanvasItem:
                child.visible = false
        print("[TenKingsPrototype] Arena panel set to battle mode (stylebox cleared, children hidden)")
    else:
        # Restore original stylebox
        if _arena_panel_original_stylebox != null:
            arena_panel.add_theme_stylebox_override("panel", _arena_panel_original_stylebox)
        else:
            arena_panel.remove_theme_stylebox_override("panel")
        # Restore panel visibility
        arena_panel.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
        # Show all children
        for child in arena_panel.get_children():
            if child is CanvasItem:
                child.visible = true
        print("[TenKingsPrototype] Arena panel restored from battle mode")


func _set_player_board_battle_mode(battle_mode: bool) -> void:
    if player_board_panel == null:
        return
    player_board_panel.visible = not battle_mode
    player_board_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE if battle_mode else _player_board_panel_mouse_filter


## Updates arena geometry based on current viewport/camera settings.
func _update_arena_geometry() -> void:
    if _arena_geometry == null:
        return
    
    var arena_rect: Rect2 = get_viewport_rect()
    if arena_panel != null:
        arena_rect = arena_panel.get_global_rect()
    var zoom: Vector2 = camera.zoom if camera != null else Vector2.ONE
    
    _arena_geometry.setup_from_viewport_rect(arena_rect, zoom)
    print("[TenKingsPrototype] Arena geometry updated: ", _arena_geometry.get_arena_rect())


# ---------------------------------------------------------------------------
# Arena anchors API
# ---------------------------------------------------------------------------

func get_arena_anchors() -> Dictionary:
    var battle_node: Node2D = get_node_or_null("BattleLayer")
    if battle_node == null:
        return {}

    var anchors: Node2D = battle_node.get_node_or_null("ArenaAnchors")
    if anchors == null:
        return {}

    var result: Dictionary = {}

    var player_front: Node2D = anchors.get_node_or_null("PlayerFrontAnchor")
    var player_ranged: Node2D = anchors.get_node_or_null("PlayerRangedAnchor")
    var player_back: Node2D = anchors.get_node_or_null("PlayerBackAnchor")
    var ai_front: Node2D = anchors.get_node_or_null("AiFrontAnchor")
    var ai_ranged: Node2D = anchors.get_node_or_null("AiRangedAnchor")
    var ai_back: Node2D = anchors.get_node_or_null("AiBackAnchor")
    var player_castle_contact: Node2D = anchors.get_node_or_null("PlayerCastleContactAnchor")
    var ai_castle_contact: Node2D = anchors.get_node_or_null("AiCastleContactAnchor")

    if player_front:
        result["player_front"] = player_front.position
    if player_ranged:
        result["player_ranged"] = player_ranged.position
    if player_back:
        result["player_back"] = player_back.position
    if ai_front:
        result["ai_front"] = ai_front.position
    if ai_ranged:
        result["ai_ranged"] = ai_ranged.position
    if ai_back:
        result["ai_back"] = ai_back.position
    if player_castle_contact:
        result["player_castle_contact"] = player_castle_contact.position
    if ai_castle_contact:
        result["ai_castle_contact"] = ai_castle_contact.position

    return result


## Returns the board slot center in battle space for a fixed structure (castle/tower).
## Used for fixed structure fire support — projectiles originate from this position.
## side: 0 = player, 1 = AI
## card_id: The card type (e.g., &"castle", &"tower")
func get_fixed_shooter_origin(side: int, card_id: StringName) -> Vector2:
    var player_state: RefCounted = _player if side == 0 else _ai_player
    var slot_map: Dictionary = _player_slots if side == 0 else _ai_slots

    if player_state == null:
        return Vector2.ZERO

    # For AI structures, return offscreen right, vertically centered
    if side == 1:
        var arena_rect = arena_panel.get_global_rect() if arena_panel != null else get_viewport_rect()
        var offscreen_right_x = arena_rect.position.x + arena_rect.size.x + 100.0
        var center_y = arena_rect.get_center().y
        return Vector2(offscreen_right_x, center_y)

    var board: RefCounted = _get_player_board(player_state)
    if board == null:
        return Vector2.ZERO

    # Find the slot containing the requested card
    for pos: Vector2i in board.get_occupied_slots():
        var slot_data: RefCounted = board.call("get_slot_data", pos)
        if slot_data == null:
            continue
        var slot_card_id: StringName = _get_slot_card_id(slot_data)
        if slot_card_id == card_id:
            if not slot_map.has(pos):
                continue
            var slot_ui = slot_map[pos]
            return _get_slot_center_in_battle_layer(slot_ui)

    return Vector2.ZERO
