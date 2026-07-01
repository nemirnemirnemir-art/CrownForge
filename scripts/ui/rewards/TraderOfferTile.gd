extends Control
class_name TraderOfferTile

signal buy_pressed(tile: TraderOfferTile)
signal hovered(tile: TraderOfferTile)
signal unhovered

@export var coin_icon: Texture2D

@onready var icon_rect: TextureRect = get_node_or_null("VBox/Icon")
@onready var buy_button: Button = get_node_or_null("VBox/BuyButton")
@onready var price_label: Label = get_node_or_null("VBox/BuyButton/Row/Price")
@onready var coin_rect: TextureRect = get_node_or_null("VBox/BuyButton/Row/Coin")

var kind: String = ""
var payload: Variant = null
var price: int = 0
var purchased: bool = false
var _click_locked: bool = false
var icon_size_override: Vector2 = Vector2.ZERO

func _ready() -> void:
	if buy_button:
		buy_button.pressed.connect(_on_buy_pressed)
	if coin_rect and coin_icon:
		coin_rect.texture = coin_icon
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if kind != "":
		hovered.emit(self)

func _on_mouse_exited() -> void:
	unhovered.emit()

func setup(new_kind: String, new_payload: Variant, icon: Texture2D, new_price: int) -> void:
	kind = new_kind
	payload = new_payload
	price = max(0, int(new_price))
	purchased = false
	_click_locked = false
	if icon_rect:
		icon_rect.texture = icon
		icon_rect.visible = icon != null
		if icon_size_override != Vector2.ZERO:
			icon_rect.custom_minimum_size = icon_size_override
	if price_label:
		price_label.text = str(price)
	if buy_button:
		buy_button.visible = kind != ""
	mouse_filter = Control.MOUSE_FILTER_STOP if kind != "" else Control.MOUSE_FILTER_IGNORE
	_set_disabled(false)

func set_purchased(v: bool) -> void:
	purchased = v
	_click_locked = v
	if buy_button:
		buy_button.visible = not v and kind != ""
	if icon_rect and kind == "" and v:
		icon_rect.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE if v else Control.MOUSE_FILTER_STOP
	_set_disabled(v)

func set_affordable(can_afford: bool) -> void:
	if purchased:
		_set_disabled(true)
		return
	_click_locked = false
	if buy_button:
		buy_button.visible = kind != ""
	mouse_filter = Control.MOUSE_FILTER_STOP if kind != "" else Control.MOUSE_FILTER_IGNORE
	_set_disabled(not can_afford)

func _set_disabled(v: bool) -> void:
	if buy_button:
		buy_button.disabled = v
	modulate = Color(1, 1, 1, 1)

func _on_buy_pressed() -> void:
	if purchased or _click_locked:
		return
	_click_locked = true
	if buy_button:
		buy_button.disabled = true
	buy_pressed.emit(self)
