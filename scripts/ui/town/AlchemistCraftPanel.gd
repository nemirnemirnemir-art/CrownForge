extends Control
class_name AlchemistCraftPanel

const TownAlchemyCraftScript := preload("res://core/town/TownAlchemyCraft.gd")
const FactorUiTexture: Texture2D = preload("res://assets/ui/craft_panel/factor_ui.png")
const ThaleahFont := preload("res://assets/ui/fonts/ThaleahFat.ttf")

@onready var close_button: SliderButton = $Canvas/CloseButton
@onready var heal_button: TextureButton = $Canvas/PotionHeal
@onready var block_button: TextureButton = $Canvas/PotionBlock

@onready var plus_button: SliderButton = $Canvas/Plus
@onready var minus_button: SliderButton = $Canvas/Minus

@onready var title_label: Label = $Canvas/CraftCard/Header/Title
@onready var description_label: Label = $Canvas/CraftCard/Description
@onready var ingredients_rows: VBoxContainer = $Canvas/CraftCard/IngredientsRows
@onready var timer_label: Label = $Canvas/TimerBlock/Timer
@onready var queue_container: Control = $Canvas/QueueSlots

var _selected_potion_id: String = "minor_heal"
var _tick_timer: Timer

var _ingredient_row_nodes: Array[Control] = []

const _QUEUE_STACK_DX: float = -10.0
const _QUEUE_STACK_DY: float = 0.0

const _REQ_ICON_SIZE: float = 32.0

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	if title_label:
		title_label.add_theme_font_override("font", ThaleahFont)
		title_label.add_theme_font_size_override("font_size", int(title_label.get_theme_font_size("font_size") * 2))
	if description_label:
		description_label.add_theme_font_override("font", ThaleahFont)
		description_label.add_theme_font_size_override("font_size", int(description_label.get_theme_font_size("font_size") * 2))
	if timer_label:
		timer_label.add_theme_font_override("font", ThaleahFont)
		timer_label.add_theme_font_size_override("font_size", int(timer_label.get_theme_font_size("font_size") * 2))

	if heal_button:
		heal_button.pressed.connect(Callable(self, "_select").bind("minor_heal"))
	if block_button:
		block_button.pressed.connect(Callable(self, "_select").bind("minor_block"))

	if plus_button:
		plus_button.pressed.connect(_on_plus_pressed)
	if minus_button:
		minus_button.pressed.connect(_on_minus_pressed)

	_tick_timer = Timer.new()
	_tick_timer.one_shot = false
	_tick_timer.wait_time = 1.0
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)

	_layout_queue_stack()

	_select(_selected_potion_id)
	hide()

func open() -> void:
	show()
	_select(_selected_potion_id)
	_tick_timer.start()
	_refresh()

func _on_close_pressed() -> void:
	_tick_timer.stop()
	hide()

func _on_tick() -> void:
	if not visible:
		_tick_timer.stop()
		return
	_refresh()

func _select(potion_id: String) -> void:
	_selected_potion_id = potion_id

	if heal_button:
		heal_button.button_pressed = potion_id == "minor_heal"
	if block_button:
		block_button.button_pressed = potion_id == "minor_block"

	_refresh()

func _on_plus_pressed() -> void:
	if not TownCore:
		return

	if TownCore.try_enqueue_alchemy(_selected_potion_id):
		_refresh()

func _on_minus_pressed() -> void:
	if not TownCore:
		return

	var queue := TownCore.get_alchemy_queue()
	if queue.is_empty():
		return

	var cancel_index := -1
	for i in range(queue.size()):
		if str(queue[i].get("potion_id", "")) == _selected_potion_id:
			cancel_index = i
			break

	if cancel_index < 0:
		return

	if TownCore.try_cancel_alchemy(cancel_index):
		_refresh()

func _refresh() -> void:
	if not TownCore:
		return

	var defs: Dictionary = TownCore.get_alchemy_potion_defs()
	if defs.is_empty():
		return

	if not defs.has(_selected_potion_id):
		_selected_potion_id = "minor_heal"

	var def: Dictionary = defs[_selected_potion_id]
	title_label.text = str(def.get("display_name", _selected_potion_id))

	if description_label:
		description_label.text = str(def.get("description", "no Description"))

	var inv: TownInventory = TownCore.get_town_inventory()

	var ingredients: Array = def.get("ingredients", [])
	var can_craft := true

	_refresh_ingredient_rows(ingredients)
	for ing in ingredients:
		var id: String = str(ing.get("id", ""))
		var need: int = int(ing.get("qty", 0))
		var have: int = 0
		if inv:
			have = inv.get_quantity(id)
		if have < need:
			can_craft = false

	var queue := TownCore.get_alchemy_queue()
	var remaining: int = TownCore.get_alchemy_active_remaining_sec()

	if queue.is_empty():
		timer_label.text = "--:--"
	else:
		var m: int = int(floor(float(remaining) / 60.0))
		var s: int = remaining % 60
		timer_label.text = "%02d:%02d" % [m, s]

	if plus_button:
		plus_button.disabled = (queue.size() >= 10) or (not can_craft)
	if minus_button:
		minus_button.disabled = queue.is_empty()

	_refresh_queue_slots(queue, defs)

func _refresh_queue_slots(queue: Array, defs: Dictionary) -> void:
	if not queue_container:
		return

	var children := queue_container.get_children()
	for i in range(children.size()):
		var slot := children[i]
		if slot is Control:
			var icon_node: TextureRect = slot.get_node_or_null("Icon")
			if not icon_node:
				continue

			var tex: Texture2D = null
			if i < queue.size():
				var potion_id: String = str(queue[i].get("potion_id", ""))
				var def: Dictionary = defs.get(potion_id, {})
				var icon_path: String = str(def.get("icon_inventory", ""))
				if icon_path != "" and ResourceLoader.exists(icon_path):
					tex = load(icon_path)
			icon_node.texture = tex

	_layout_queue_stack()

func _refresh_ingredient_rows(ingredients: Array) -> void:
	if not ingredients_rows:
		return

	for n in _ingredient_row_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_ingredient_row_nodes.clear()

	var row: HBoxContainer = null
	var in_row: int = 0

	for ing in ingredients:
		if row == null or in_row >= 2:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 24)
			ingredients_rows.add_child(row)
			_ingredient_row_nodes.append(row)
			in_row = 0

		var id: String = str(ing.get("id", ""))
		var need: int = int(ing.get("qty", 0))

		var block := HBoxContainer.new()
		block.add_theme_constant_override("separation", 4)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(_REQ_ICON_SIZE, _REQ_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path: String = str(TownAlchemyCraftScript.INGREDIENT_ICONS.get(id, ""))
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		block.add_child(icon)

		var mul := TextureRect.new()
		mul.custom_minimum_size = Vector2(_REQ_ICON_SIZE, _REQ_ICON_SIZE)
		mul.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mul.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mul.texture = FactorUiTexture
		block.add_child(mul)

		var qty := Label.new()
		qty.text = str(need)
		qty.add_theme_font_override("font", ThaleahFont)
		qty.add_theme_font_size_override("font_size", int(qty.get_theme_font_size("font_size") * 2))
		block.add_child(qty)

		row.add_child(block)
		_ingredient_row_nodes.append(block)
		in_row += 1

func _layout_queue_stack() -> void:
	if not queue_container:
		return

	var children := queue_container.get_children()
	var count := children.size()
	for i in range(count):
		var slot := children[i]
		if slot is Control:
			slot.set_anchors_preset(Control.PRESET_TOP_LEFT)
			slot.position = Vector2(float(i) * _QUEUE_STACK_DX, float(i) * _QUEUE_STACK_DY)
			slot.z_index = count - i
