extends Control
class_name RewardMenuResources

@export var offered_count: int = 3

const UI_RESOURCES: Array[String] = [
	"water",
	"gold",
	"wood",
	"clay",
	"iron_ore",
	"steel",
	"wheat",
	"flour",
	"grapes",
	"wine",
	"crystal",
]

@onready var title_label: Label = get_node_or_null("TitleLabel")
@onready var dim: CanvasItem = get_node_or_null("Dim")
@onready var collapse_button: Button = get_node_or_null("CollapseButton")
@onready var reroll_button: Button = get_node_or_null("RerollButton")

var _cards: Array = []
var _current_ids: Array[String] = []
var _prev_tree_paused: bool = false
var _amount: int = 0
var _collapsed: bool = false

func _get_autoload(name: String) -> Node:
	return get_node_or_null("/root/%s" % name)

func _resource_core() -> Node:
	return _get_autoload("ResourceCore")

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

	if collapse_button:
		collapse_button.pressed.connect(_on_collapse_pressed)
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)

	visible = false

func open(amount: int) -> void:
	_amount = max(0, amount)
	_collapsed = false
	visible = true
	if get_tree():
		_prev_tree_paused = get_tree().paused
		get_tree().paused = true
	_roll_cards()

func close_menu() -> void:
	visible = false
	if get_tree():
		get_tree().paused = _prev_tree_paused

func _roll_cards() -> void:
	var pool := UI_RESOURCES.duplicate()
	pool.shuffle()

	for i in range(_cards.size()):
		var card = _cards[i]
		if card == null:
			continue
		if card.has_method("set_background_variant"):
			card.set_background_variant(i)
		var should_show := i < offered_count and i < pool.size()
		_current_ids[i] = pool[i] if should_show else ""
		card.visible = should_show and not _collapsed
		if should_show and card.has_method("setup"):
			card.setup(_current_ids[i], _amount)

	if title_label:
		title_label.text = "Choose a resource"
	if dim:
		dim.visible = not _collapsed
	if collapse_button:
		collapse_button.text = "▲" if _collapsed else "▼"
	if reroll_button:
		reroll_button.visible = not _collapsed

func _on_card_selected(resource_id: String) -> void:
	var resource_core: Node = _resource_core()
	if resource_core != null and resource_id != "" and _amount > 0:
		resource_core.call("add_resource", resource_id, _amount)
	close_menu()

func _on_collapse_pressed() -> void:
	_collapsed = not _collapsed
	for i in range(_cards.size()):
		var card = _cards[i]
		if card:
			card.visible = (_current_ids[i] != "") and not _collapsed
	if dim:
		dim.visible = not _collapsed
	if collapse_button:
		collapse_button.text = "▲" if _collapsed else "▼"
	if reroll_button:
		reroll_button.visible = not _collapsed

func _on_reroll_pressed() -> void:
	if _collapsed:
		return
	_roll_cards()
