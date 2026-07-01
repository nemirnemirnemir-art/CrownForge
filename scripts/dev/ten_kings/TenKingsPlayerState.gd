## Manages one player's complete state: board, deck, hand, castle HP, loss streak.
## Used by the match controller to track each player during a 10 Kings game.
extends RefCounted


const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const BoardStateScript = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")


# ---------------------------------------------------------------------------
# Damage escalation table (indexed by loss_streak, clamped at 3+)
# ---------------------------------------------------------------------------
const _LOSS_DAMAGE: Array[int] = [10, 20, 40, 60]


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var board: RefCounted  # TenKingsBoardState instance
var deck: Array[StringName] = []
var hand: Array[StringName] = []
var castle_hp: int = 100
var max_castle_hp: int = 100
var loss_streak: int = 0
var is_ai: bool = false
var player_name: String = ""


# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------

func _init(p_name: String, p_is_ai: bool) -> void:
	player_name = p_name
	is_ai = p_is_ai
	board = BoardStateScript.new()
	deck = CardLib.build_deck()
	castle_hp = max_castle_hp


# ---------------------------------------------------------------------------
# Hand / Deck management
# ---------------------------------------------------------------------------

## Draw 3 random cards from deck into hand (used at game start).
func draw_initial_hand() -> void:
	for _i: int in range(3):
		var card: StringName = draw_card_from_deck()
		if card != &"":
			hand.append(card)


## Remove and return one random card from the deck. Returns &"" if empty.
func draw_card_from_deck() -> StringName:
	if deck.is_empty():
		return &""
	var idx: int = randi() % deck.size()
	var card: StringName = deck[idx]
	deck.remove_at(idx)
	return card


## Pick up to 3 cards with UNIQUE types from the remaining deck.
## Does NOT remove them — call accept_offer() to commit a choice.
func generate_offer() -> Array[StringName]:
	var offer: Array[StringName] = []
	var seen_types: Dictionary = {}  # StringName -> true

	# Walk through deck in shuffled order to pick unique types
	var indices: Array[int] = []
	for i: int in range(deck.size()):
		indices.append(i)
	indices.shuffle()

	for idx: int in indices:
		var card_id: StringName = deck[idx]
		if not seen_types.has(card_id):
			seen_types[card_id] = true
			offer.append(card_id)
			if offer.size() >= 3:
				break

	return offer


## Remove one copy of card_id from deck and add it to hand.
func accept_offer(card_id: StringName) -> void:
	var idx: int = deck.find(card_id)
	if idx < 0:
		push_warning("TenKingsPlayerState: card '%s' not found in deck for accept_offer" % str(card_id))
		return
	deck.remove_at(idx)
	hand.append(card_id)


## Remove card from hand and attempt to place on board.
## Returns true on success. If placement fails, the card is returned to hand.
func play_card(card_id: StringName, pos: Vector2i) -> bool:
	var hand_idx: int = hand.find(card_id)
	if hand_idx < 0:
		push_warning("TenKingsPlayerState: card '%s' not in hand" % str(card_id))
		return false

	hand.remove_at(hand_idx)

	var placed: bool = board.place_card(pos, card_id)
	if not placed:
		# Placement failed — return card to hand
		hand.append(card_id)
		return false

	return true


func ensure_card_in_hand(card_id: StringName) -> bool:
	if hand.has(card_id):
		return true

	var deck_idx: int = deck.find(card_id)
	if deck_idx < 0:
		return false

	deck.remove_at(deck_idx)
	hand.append(card_id)
	return true


# ---------------------------------------------------------------------------
# Castle HP / Win-Loss
# ---------------------------------------------------------------------------

## Return the damage this player would take on a loss, based on current streak.
func get_loss_damage() -> int:
	var index: int = mini(loss_streak, _LOSS_DAMAGE.size() - 1)
	return _LOSS_DAMAGE[index]


## Apply damage to castle and increment loss streak.
func apply_loss(damage: int) -> void:
	castle_hp -= damage
	loss_streak += 1


## Reset loss streak on a win.
func apply_win() -> void:
	loss_streak = 0


## Returns true if this player's castle HP has reached zero or below.
func is_defeated() -> bool:
	return castle_hp <= 0


# ---------------------------------------------------------------------------
# Hand queries
# ---------------------------------------------------------------------------

func get_hand_size() -> int:
	return hand.size()


func get_deck_size() -> int:
	return deck.size()


func has_card_in_hand(card_id: StringName) -> bool:
	return hand.has(card_id)


## Returns an array of unique card IDs present in hand (no duplicates).
func get_unique_hand_cards() -> Array[StringName]:
	var seen: Dictionary = {}
	var result: Array[StringName] = []
	for card_id: StringName in hand:
		if not seen.has(card_id):
			seen[card_id] = true
			result.append(card_id)
	return result


## Returns true if hand contains at least one troop card (soldier, archer, paladin).
func has_troop_in_hand() -> bool:
	for card_id: StringName in hand:
		if CardLib.is_troop(card_id):
			return true
	return false


## Ensures hand contains at least one troop card. Pulls from deck if needed.
## Returns true if hand now contains a troop, false if no troops available.
func ensure_any_troop_in_hand() -> bool:
	if has_troop_in_hand():
		return true

	# Find first troop in deck and move to hand
	for i: int in range(deck.size()):
		var card_id: StringName = deck[i]
		if CardLib.is_troop(card_id):
			deck.remove_at(i)
			hand.append(card_id)
			return true

	return false
