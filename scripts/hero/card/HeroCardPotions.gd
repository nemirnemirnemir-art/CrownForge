extends RefCounted
class_name HeroCardPotions

## Potion management
## Icon, counter, button update

var _button1: Button
var _potion_icon: TextureRect
var _potion_count_container: Node2D
var _mini_digit_textures: Array[Texture2D] = []

func initialize(button1: Button) -> void:
	_button1 = button1
	_load_mini_digit_textures()
	_setup_potion_button()

func _load_mini_digit_textures() -> void:
	# ✅ Load digit textures 0-9 from miniDigits
	_mini_digit_textures.clear()
	for i in range(10):
		var path = "res://assets/ui/digits/miniDigits/%d.png" % i
		if ResourceLoader.exists(path):
			_mini_digit_textures.append(load(path))
		else:
			print("[HeroCardPotions] Warning: miniDigit texture not found: %s" % path)
			_mini_digit_textures.append(null)

func _setup_potion_button() -> void:
	# ✅ Create potion icon and counter on the Give Potion button (Button1)
	if _button1 == null:
		return
	
	# Potion icon (50x50)
	_potion_icon = TextureRect.new()
	_potion_icon.name = "PotionIcon"
	_potion_icon.custom_minimum_size = Vector2(50, 50)
	_potion_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_potion_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_potion_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Do not block button clicks
	_button1.add_child(_potion_icon)
	
	# ✅ Container for potion digits (bottom-left, 1/4 of the image)
	_potion_count_container = Node2D.new()
	_potion_count_container.name = "PotionCountContainer"
	# Position: bottom-left, 1/4 of the image (12px from bottom, 5px from left)
	# Button is 50x50, so position: x=5 (left), y=50-12=38 (bottom)
	_potion_count_container.position = Vector2(5, 38)
	_button1.add_child(_potion_count_container)

func update_potion_button(hero_data: Dictionary) -> void:
	if _potion_icon == null or _potion_count_container == null or _button1 == null:
		return
	
	var potions_count = hero_data.get("potions_carried", 0)
	var global_potions = 0
	if TownCore:
		global_potions = TownCore.get_global_potions()
	
	# ✅ If hero has no potions AND global pool is empty - show disabled
	if potions_count == 0 and global_potions == 0:
		_potion_icon.texture = load("res://assets/items/res/potion_disable.png")
		_clear_digit_sprites(_potion_count_container)
		_button1.disabled = true
	else:
		# ✅ If there is at least one potion - show active
		_potion_icon.texture = load("res://assets/items/res/potion_active.png")
		_show_digit_number(_potion_count_container, potions_count, Vector2(0, 0), 2.0)  # Scale 2.0 (4x larger than 0.5)
		_button1.disabled = false

func clear_potion_display() -> void:
	# ✅ Clear potion icon on the button
	if _potion_icon != null:
		_potion_icon.texture = load("res://assets/items/res/potion_disable.png")
	if _potion_count_container != null:
		_clear_digit_sprites(_potion_count_container)
	if _button1 != null:
		_button1.disabled = true

func _show_digit_number(container: Node2D, number: int, position: Vector2, scale_factor: float = 1.0) -> void:
	# ✅ Clear old digits
	_clear_digit_sprites(container)
	
	if _mini_digit_textures.is_empty():
		return
	
	# Convert number to digit array
	var n: int = abs(number)
	var digits: Array[int] = []
	if n == 0:
		digits.append(0)
	else:
		while n > 0:
			digits.push_front(n % 10)
			n = int(n / 10.0)
	
	# Create sprites for each digit
	var spacing: float = 4.0 * scale_factor
	var current_x: float = 0.0
	
	for digit in digits:
		if digit >= 0 and digit < _mini_digit_textures.size() and _mini_digit_textures[digit] != null:
			var sprite = Sprite2D.new()
			sprite.texture = _mini_digit_textures[digit]
			sprite.scale = Vector2(scale_factor, scale_factor)
			sprite.position = position + Vector2(current_x, 0)
			container.add_child(sprite)
			
			# Digit width + spacing
			var tex_width = _mini_digit_textures[digit].get_width() * scale_factor
			current_x += tex_width + spacing

func _clear_digit_sprites(container: Node2D) -> void:
	# ✅ Remove all child sprites
	for child in container.get_children():
		child.queue_free()

