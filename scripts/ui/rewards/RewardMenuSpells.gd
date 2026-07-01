extends Control
class_name RewardMenuSpells

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

@export var offered_count: int = 2
@export var legendary_only: bool = false

@onready var title_label: Label = get_node_or_null("TitleLabel")
@onready var dim: CanvasItem = get_node_or_null("Dim")

var _cards: Array = []
var _current_ids: Array[String] = []
var _prev_tree_paused: bool = false
var _open_offered_count: int = 0
var _open_legendary_only: bool = false

func _get_autoload(name: String) -> Node:
	return get_node_or_null("/root/%s" % name)

func _spell_core() -> Node:
	return _get_autoload("SpellCore")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cards = [
		get_node_or_null("Card1"),
		get_node_or_null("Card2"),
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

	visible = false

func open() -> void:
	_open_offered_count = max(1, offered_count)
	_open_legendary_only = legendary_only
	open_with_options(_open_offered_count, _open_legendary_only)

func open_with_options(next_offered_count: int, next_legendary_only: bool) -> void:
	_open_offered_count = max(1, next_offered_count)
	_open_legendary_only = next_legendary_only
	visible = true
	if get_tree():
		_prev_tree_paused = get_tree().paused
		get_tree().paused = true
	_roll_cards()

func close_menu() -> void:
	visible = false
	if get_tree():
		get_tree().paused = _prev_tree_paused

func _get_pool_ids() -> Array[String]:
	return PathRegistryScript.list_spell_config_ids(_open_legendary_only)

func _roll_cards() -> void:
	var pool := _get_pool_ids()
	pool.shuffle()

	for i in range(_cards.size()):
		var card = _cards[i]
		if card == null:
			continue
		var should_show := i < _open_offered_count and i < pool.size()
		_current_ids[i] = pool[i] if should_show else ""
		card.visible = should_show
		if should_show and card.has_method("setup"):
			card.setup(_current_ids[i])

	if title_label:
		title_label.text = "Choose a legendary spell" if _open_legendary_only else "Choose a spell"
	if dim:
		dim.visible = true

func _on_card_selected(spell_id: String) -> void:
	var spell_panel: Node = get_tree().get_first_node_in_group("spell_panel")
	if spell_panel and spell_panel.has_method("add_spell"):
		var config := PathRegistryScript.load_spell_config(spell_id) as SpellConfig
		if config:
			spell_panel.add_spell(config)
	else:
		var spell_core: Node = _spell_core()
		if spell_core != null and spell_core.has_method("add_spell"):
			spell_core.call("add_spell", spell_id, 1)
	close_menu()
