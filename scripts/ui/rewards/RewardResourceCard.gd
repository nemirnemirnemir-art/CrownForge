extends Control
class_name RewardResourceCard

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

signal selected(resource_id: String)

const DIGIT_TEXTURES: Array[Texture2D] = [
	preload("res://assets/ui/resource_cards/custom_numbers/0.png"),
	preload("res://assets/ui/resource_cards/custom_numbers/1.png"),
	preload("res://assets/ui/resource_cards/custom_numbers/2.png"),
	preload("res://assets/ui/resource_cards/custom_numbers/3.png"),
	preload("res://assets/ui/resource_cards/custom_numbers/4.png"),
	preload("res://assets/ui/resource_cards/custom_numbers/5.png"),
	preload("res://assets/ui/resource_cards/custom_numbers/6.png"),
	preload("res://assets/ui/resource_cards/custom_numbers/7.png"),
	preload("res://assets/ui/resource_cards/custom_numbers/8.png"),
	preload("res://assets/ui/resource_cards/custom_numbers/9.png"),
]

@export var background_left: Texture2D
@export var background_center: Texture2D
@export var background_right: Texture2D

@export_enum("Left", "Center", "Right") var background_variant: int = 1:
	set = set_background_variant

@onready var background_rect: TextureRect = get_node_or_null("Background")
@onready var header_label: Label = get_node_or_null("HeaderBg/HeaderLabel")
@onready var choose_button_visual: BaseButton = get_node_or_null("ChooseButton")
@onready var resource_icon_rect: TextureRect = get_node_or_null("ChooseButton/ResourceIcon")
@onready var amount_digits: HBoxContainer = get_node_or_null("AmountDigits")
@onready var choose_button: Button = get_node_or_null("Choose")

var resource_id: String = ""
var amount: int = 0

func _ready() -> void:
	if choose_button:
		choose_button.pressed.connect(_on_choose_pressed)
	_apply_background_variant()

func setup(new_resource_id: String, new_amount: int) -> void:
	resource_id = new_resource_id
	amount = clampi(new_amount, 0, 999)
	_set_icon(resource_id)
	if header_label:
		header_label.text = _display_name(resource_id)
	_set_amount_digits(amount)

func _on_choose_pressed() -> void:
	if resource_id != "":
		selected.emit(resource_id)

func _display_name(id: String) -> String:
	var words := id.replace("_", " ").split(" ", false)
	for i in range(words.size()):
		var w := String(words[i])
		if w.length() == 0:
			continue
		words[i] = w[0].to_upper() + w.substr(1, w.length() - 1)
	return " ".join(words)

func _set_icon(id: String) -> void:
	if not resource_icon_rect:
		return

	var res_map = {
		"wood": "wood_1",
		"gold": "gold_4",
		"clay": "clay_3",
		"wheat": "wheat_7",
		"meat": "meat_9",
		"iron_ore": "iron_ore_5",
		"ore": "iron_ore_5",
		"flour": "flour_8",
		"stone": "stone_2",
		"water": "water_-1",
		"mana": "mana_8",
		"steel": "iron_ingot_6",
		"metal": "iron_ingot_6",
		"crystal": "crystal",
	}

	resource_icon_rect.texture = PathRegistryScript.load_resource_icon(id, res_map)

func set_background_variant(v: int) -> void:
	background_variant = v
	_apply_background_variant()

func _apply_background_variant() -> void:
	if not background_rect:
		return
	match background_variant:
		0:
			background_rect.texture = background_left
		1:
			background_rect.texture = background_center
		2:
			background_rect.texture = background_right
		_:
			background_rect.texture = background_center

func _set_amount_digits(value: int) -> void:
	if not amount_digits:
		return

	for c in amount_digits.get_children():
		c.queue_free()

	var s := str(clampi(value, 0, 999))
	for i in range(s.length()):
		var ch := s[i]
		var digit := int(ch)
		if digit < 0 or digit >= DIGIT_TEXTURES.size():
			continue
		var digit_rect := TextureRect.new()
		digit_rect.texture = DIGIT_TEXTURES[digit]
		digit_rect.custom_minimum_size = Vector2(36, 63)
		digit_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		digit_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		amount_digits.add_child(digit_rect)
