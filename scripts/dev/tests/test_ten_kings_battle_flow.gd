## Test: Battle flow diagnostics - trace the full battle chain to identify visibility issues.
extends SceneTree


const PlayerState = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const BoardState = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const TurnFlow = preload("res://scripts/dev/ten_kings/TenKingsTurnFlow.gd")
const BattleManager = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")


var _battle_started_received: bool = false
var _battle_ended_received: bool = false
var _battle_winner: int = -1


func _init() -> void:
	print("")
	print("=== TenKings Battle Flow Diagnostic Test ===")
	print("")
	
	_test_battle_flow_with_troops()
	
	print("")
	print("=== Diagnostic Test Complete ===")
	quit()


func _test_battle_flow_with_troops() -> void:
	print("[TEST] Setting up player and AI via TurnFlow (proper setup)...")
	
	var player = PlayerState.new("Player", false)
	var ai_player = PlayerState.new("AI", true)
	
	# Use TurnFlow.setup() which guarantees castle and troop in hand
	var turn_flow = TurnFlow.new()
	turn_flow.setup(player, ai_player)
	
	print("[TEST] Player hand after setup: ", player.hand)
	print("[TEST] AI hand after setup: ", ai_player.hand)
	print("[TEST] Player has troop in hand: ", player.has_troop_in_hand())
	print("[TEST] AI has troop in hand: ", ai_player.has_troop_in_hand())
	
	# Place player castle (AI castle already placed by setup)
	var castle_placed = turn_flow.player_place_castle(Vector2i(2, 2))
	print("[TEST] Player castle placed: ", castle_placed)
	print("[TEST] Current phase: ", turn_flow.get_phase())
	
	# Now we're in PREP phase - place a troop from player hand
	var player_troop = _find_troop_in_hand(player.hand)
	print("[TEST] Player troop to place: ", player_troop)
	
	if player_troop != &"":
		var troop_placed = turn_flow.player_play_card(player_troop, Vector2i(1, 2))
		print("[TEST] Player troop placed at (1,2): ", troop_placed)
	
	# AI should also have troops from setup - place one manually for test
	var ai_troop = _find_troop_in_hand(ai_player.hand)
	print("[TEST] AI troop to place: ", ai_troop)
	if ai_troop != &"":
		ai_player.play_card(ai_troop, Vector2i(3, 2))
		print("[TEST] AI placed troop at (3,2)")
	
	print("[TEST] Player board occupied slots: ", player.board.get_occupied_slots())
	print("[TEST] AI board occupied slots: ", ai_player.board.get_occupied_slots())
	print("[TEST] Player has_troop_on_board: ", player.board.has_troop_on_board())
	print("[TEST] AI has_troop_on_board: ", ai_player.board.has_troop_on_board())
	
	# List what's on each board
	print("[TEST] Player board contents:")
	for pos in player.board.get_occupied_slots():
		var slot_data = player.board.get_slot_data(pos)
		print("[TEST]   ", pos, " -> ", slot_data.card_id if slot_data else "null")
	
	print("[TEST] AI board contents:")
	for pos in ai_player.board.get_occupied_slots():
		var slot_data = ai_player.board.get_slot_data(pos)
		print("[TEST]   ", pos, " -> ", slot_data.card_id if slot_data else "null")
	
	# Create battle manager (standalone Node2D for testing)
	print("[TEST] Creating BattleManager...")
	var battle_manager = BattleManager.new()
	battle_manager.name = "TestBattleManager"
	
	# Connect signals
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended)
	
	# We need to add battle_manager to a tree for _process to work
	# Since we're in SceneTree context, we can add to root
	get_root().add_child(battle_manager)
	print("[TEST] BattleManager added to tree")
	
	# Simulate arena anchors (from actual scene)
	var anchors = {
		"player_front": Vector2(-60, 0),
		"player_ranged": Vector2(-120, 0),
		"player_back": Vector2(-180, 0),
		"ai_front": Vector2(60, 0),
		"ai_ranged": Vector2(120, 0),
		"ai_back": Vector2(180, 0),
		"player_castle_contact": Vector2(-250, 0),
		"ai_castle_contact": Vector2(250, 0),
	}
	print("[TEST] Setting arena anchors: ", anchors)
	battle_manager.set_arena_anchors(anchors)
	
	# Simulate slot origin positions (where cards are on the UI)
	var player_origins = {}
	for pos in player.board.get_occupied_slots():
		player_origins[pos] = Vector2(-350 + pos.x * 50, pos.y * 50 - 100)
	
	var ai_origins = {}
	for pos in ai_player.board.get_occupied_slots():
		ai_origins[pos] = Vector2(350 + pos.x * 50, pos.y * 50 - 100)
	
	print("[TEST] Starting battle...")
	print("[TEST] Player origins: ", player_origins)
	print("[TEST] AI origins: ", ai_origins)
	
	battle_manager.start_battle(player, ai_player, player_origins, ai_origins)
	
	# Check immediate state after start_battle
	print("[TEST] Battle started signal received: ", _battle_started_received)
	print("[TEST] BattleManager children: ", battle_manager.get_child_count())
	
	for child in battle_manager.get_children():
		print("[TEST]   Child: ", child.name)
		if child.name == "BattleUnits":
			print("[TEST]     BattleUnits has ", child.get_child_count(), " children")
			for unit in child.get_children():
				if unit.name == "BattleEffects":
					continue
				print("[TEST]       Unit: ", unit.name, " visible: ", unit.visible if unit is CanvasItem else "N/A", " pos: ", unit.position if unit is Node2D else "N/A")
				if unit.has_method("get_state"):
					print("[TEST]         state: ", unit.call("get_state"))
				if unit.get("card_id"):
					print("[TEST]         card_id: ", unit.get("card_id"))
	
	# The battle_started signal should have been emitted after deploy finishes
	# In real game, _process would run the battle
	print("[TEST] Battle started received: ", _battle_started_received)
	print("[TEST] Battle ended received: ", _battle_ended_received)
	
	# Cleanup
	battle_manager.cleanup()
	battle_manager.queue_free()


func _find_troop_in_hand(hand: Array) -> StringName:
	for card_id in hand:
		if CardLib.is_troop(card_id):
			return card_id
	return &""


func _on_battle_started() -> void:
	print("[TEST] >>> SIGNAL: battle_started received")
	_battle_started_received = true


func _on_battle_ended(winner_side: int) -> void:
	print("[TEST] >>> SIGNAL: battle_ended received, winner: ", winner_side)
	_battle_ended_received = true
	_battle_winner = winner_side
