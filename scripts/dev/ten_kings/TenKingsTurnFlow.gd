## Phase-management FSM for the 10 Kings prototype.
## Drives the high-level game flow: castle placement → prep → year effects →
## battle → post-battle → offer → slot unlock → next year.
## This is a RefCounted (not a Node) — it uses signals but has no _process.
extends RefCounted


const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const YearEffects = preload("res://scripts/dev/ten_kings/TenKingsYearEffects.gd")
const AiController = preload("res://scripts/dev/ten_kings/TenKingsAiController.gd")


# ---------------------------------------------------------------------------
# Phase enum
# ---------------------------------------------------------------------------

enum Phase {
	CASTLE_PLACEMENT,  ## Both players must place their castle
	PREP,              ## Player places cards from hand, AI auto-plays
	YEAR_EFFECTS,      ## Farm / Blacksmith effects apply
	BATTLE,            ## Combat resolves (handled externally by BattleManager)
	POST_BATTLE,       ## Win/loss applied, damage dealt (transient)
	OFFER,             ## Both players pick a card from the offer
	SLOT_UNLOCK,       ## Every 3 years, unlock a board slot
	GAME_OVER,         ## One player is defeated — terminal state
}


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal phase_changed(new_phase: int)
signal year_started(year: int)
signal year_effects_applied(player_summary: Dictionary, ai_summary: Dictionary)
signal battle_requested
signal battle_result_received(winner_side: int)
signal offer_generated(player_offer: Array, ai_offer: Array)
signal slot_unlocked(side: int, pos: Vector2i)
signal game_over(winner_side: int)
signal ai_cards_played(actions: Array)
signal ai_castle_placed(pos: Vector2i)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _phase: int = Phase.CASTLE_PLACEMENT
var current_year: int = 1
var _player: RefCounted = null     ## TenKingsPlayerState
var _ai_player: RefCounted = null  ## TenKingsPlayerState
var _player_castle_placed: bool = false
var _ai_castle_placed: bool = false
var _player_pending_offer: Array[StringName] = []
var _ai_pending_offer: Array[StringName] = []  ## Stored from offer generation


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Store references to both players, draw initial hands, start in
## CASTLE_PLACEMENT phase, and let the AI place its castle immediately.
func setup(player: RefCounted, ai_player: RefCounted) -> void:
	_player = player
	_ai_player = ai_player

	_player.draw_initial_hand()
	_ai_player.draw_initial_hand()
	_ensure_opening_castle(_player)
	_ensure_opening_castle(_ai_player)
	_ensure_opening_troop(_player)
	_ensure_opening_troop(_ai_player)

	_set_phase(Phase.CASTLE_PLACEMENT)

	# AI places its castle right away
	var ai_pos: Vector2i = AiController.decide_castle_placement(_ai_player)
	if ai_pos != Vector2i(-1, -1):
		_ai_player.play_card(&"castle", ai_pos)
		_ai_castle_placed = true
		ai_castle_placed.emit(ai_pos)


# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------

func get_phase() -> int:
	return _phase


## Returns true if the player can end their turn.
## Requires: PREP phase, castle placed, at least one troop on board.
func can_end_turn() -> bool:
	if _phase != Phase.PREP:
		return false
	if not _player_castle_placed:
		return false
	return _player.board.has_troop_on_board()


# ---------------------------------------------------------------------------
# Player actions
# ---------------------------------------------------------------------------

## Place the player's castle during CASTLE_PLACEMENT phase.
## Returns true if placement succeeded.
func player_place_castle(pos: Vector2i) -> bool:
	if _phase != Phase.CASTLE_PLACEMENT:
		return false

	var ok: bool = _player.play_card(&"castle", pos)
	if not ok:
		return false

	_player_castle_placed = true

	# If both castles are placed, advance to PREP
	if _player_castle_placed and _ai_castle_placed:
		_set_phase(Phase.PREP)
		year_started.emit(current_year)

	return true


## Play a card from the player's hand during PREP phase.
## Returns true if placement succeeded.
func player_play_card(card_id: StringName, pos: Vector2i) -> bool:
	if _phase != Phase.PREP:
		return false
	return _player.play_card(card_id, pos)


## End the player's PREP turn. AI plays automatically, then advance to
## YEAR_EFFECTS.
func player_end_turn() -> void:
	print("[TenKingsTurnFlow] player_end_turn called, phase: ", _phase)
	if _phase != Phase.PREP:
		print("[TenKingsTurnFlow] ERROR: Not in PREP phase")
		return

	# AI plays its cards
	var actions: Array[Dictionary] = AiController.play_turn(_ai_player)
	print("[TenKingsTurnFlow] AI played ", actions.size(), " cards")
	ai_cards_played.emit(actions)

	_set_phase(Phase.YEAR_EFFECTS)
	print("[TenKingsTurnFlow] Calling advance_from_year_effects...")
	advance_from_year_effects()


## Called by the prototype to advance from YEAR_EFFECTS. Applies effects
## to both boards, emits summaries, then transitions to BATTLE.
func advance_from_year_effects() -> void:
	print("[TenKingsTurnFlow] advance_from_year_effects called, phase: ", _phase)
	if _phase != Phase.YEAR_EFFECTS:
		print("[TenKingsTurnFlow] ERROR: Not in YEAR_EFFECTS phase")
		return

	var player_summary: Dictionary = YearEffects.apply_year_effects(_player.board)
	var ai_summary: Dictionary = YearEffects.apply_year_effects(_ai_player.board)
	print("[TenKingsTurnFlow] Year effects applied - player: ", player_summary, " ai: ", ai_summary)
	year_effects_applied.emit(player_summary, ai_summary)

	_set_phase(Phase.BATTLE)
	print("[TenKingsTurnFlow] Emitting battle_requested signal...")
	battle_requested.emit()
	print("[TenKingsTurnFlow] battle_requested emitted")


## Called by the prototype after BattleManager reports the battle result.
## winner_side: 0 = player, 1 = AI.
func on_battle_ended(winner_side: int) -> void:
	if _phase != Phase.BATTLE:
		return

	# Transient POST_BATTLE phase — processed inline
	_set_phase(Phase.POST_BATTLE)

	# Determine winner / loser
	var winner: RefCounted
	var loser: RefCounted
	if winner_side == 0:
		winner = _player
		loser = _ai_player
	else:
		winner = _ai_player
		loser = _player

	# Apply results
	var damage: int = loser.get_loss_damage()
	loser.apply_loss(damage)
	winner.apply_win()

	battle_result_received.emit(winner_side)

	# Check for game over
	if loser.is_defeated():
		_set_phase(Phase.GAME_OVER)
		game_over.emit(winner_side)
		return

	# Advance to OFFER
	_set_phase(Phase.OFFER)

	# Generate offers for both sides and store AI's for later
	_player_pending_offer = _player.generate_offer()
	_ai_pending_offer = _ai_player.generate_offer()
	if _player_pending_offer.is_empty():
		_resolve_offer_phase(&"")
		return
	offer_generated.emit(_player_pending_offer, _ai_pending_offer)


## Player picks a card from the offer. AI picks automatically.
## Advances to SLOT_UNLOCK (if year % 3 == 0) or the next year.
func player_accept_offer(card_id: StringName) -> void:
	if _phase != Phase.OFFER:
		return
	_resolve_offer_phase(card_id)


func _resolve_offer_phase(card_id: StringName) -> void:
	if _phase != Phase.OFFER:
		return

	# Player accepts their chosen card when one is available.
	if card_id != &"" and _player_pending_offer.has(card_id):
		_player.accept_offer(card_id)
	_player_pending_offer = []

	# AI picks from the same offer that was generated earlier
	if not _ai_pending_offer.is_empty():
		var ai_pick: StringName = AiController.choose_offer(_ai_player, _ai_pending_offer)
		if ai_pick != &"":
			_ai_player.accept_offer(ai_pick)
	_ai_pending_offer = []

	# Slot unlock every 3 years, then advance to next year
	if current_year % 3 == 0:
		_set_phase(Phase.SLOT_UNLOCK)
		_unlock_slots()

	_advance_to_next_year()


# ---------------------------------------------------------------------------
# Internal transitions
# ---------------------------------------------------------------------------

## Increment the year, emit year_started, and transition to PREP.
func _advance_to_next_year() -> void:
	current_year += 1
	_set_phase(Phase.PREP)
	year_started.emit(current_year)


## Unlock one slot per player and emit signals.
func _unlock_slots() -> void:
	var player_pos: Vector2i = _player.board.unlock_next_slot()
	if player_pos != Vector2i(-1, -1):
		slot_unlocked.emit(0, player_pos)

	var ai_pos: Vector2i = _ai_player.board.unlock_next_slot()
	if ai_pos != Vector2i(-1, -1):
		slot_unlocked.emit(1, ai_pos)


## Update phase and emit the phase_changed signal.
func _set_phase(new_phase: int) -> void:
	_phase = new_phase
	phase_changed.emit(new_phase)


func _ensure_opening_castle(player: RefCounted) -> void:
	if player.has_card_in_hand(CardLib.CARD_CASTLE):
		return

	if not player.ensure_card_in_hand(CardLib.CARD_CASTLE):
		push_warning("TenKingsTurnFlow: failed to ensure opening castle for %s" % player.player_name)
		return

	if player.hand.size() <= 3:
		return

	for index: int in range(player.hand.size() - 1, -1, -1):
		var returned_card: StringName = player.hand[index]
		if returned_card == CardLib.CARD_CASTLE:
			continue
		player.hand.remove_at(index)
		player.deck.append(returned_card)
		return


## Ensure the player has at least one troop card in opening hand.
## If not present, pulls one from deck. Maintains 3-card hand size.
func _ensure_opening_troop(player: RefCounted) -> void:
	if player.has_troop_in_hand():
		return

	if not player.ensure_any_troop_in_hand():
		push_warning("TenKingsTurnFlow: failed to ensure opening troop for %s" % player.player_name)
		return

	# If hand now exceeds 3 cards, return a non-essential card to deck
	if player.hand.size() <= 3:
		return

	# Return a non-castle, non-troop card to deck (preference for support cards)
	for index: int in range(player.hand.size() - 1, -1, -1):
		var card_id: StringName = player.hand[index]
		if card_id == CardLib.CARD_CASTLE:
			continue
		if CardLib.is_troop(card_id):
			continue
		player.hand.remove_at(index)
		player.deck.append(card_id)
		return
