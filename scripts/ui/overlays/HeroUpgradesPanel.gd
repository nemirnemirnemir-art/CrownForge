extends Control

## Panel for displaying and purchasing hero upgrades

@onready var left_arrow: Button = $MainContainer/UpgradesContainer/LeftArrow
@onready var right_arrow: Button = $MainContainer/UpgradesContainer/RightArrow
@onready var upgrades_grid: GridContainer = $MainContainer/UpgradesContainer/UpgradesGrid
@onready var popup_menu: Panel = $PopupMenu
@onready var hero_name_label: Label = $PopupMenu/VBoxContainer/HeroNameLabel
@onready var upgrade_index_label: Label = $PopupMenu/VBoxContainer/UpgradeIndexLabel
@onready var description_label: Label = $PopupMenu/VBoxContainer/DescriptionLabel
@onready var price_label: Label = $PopupMenu/VBoxContainer/PriceLabel
@onready var purchase_button: Button = $PopupMenu/VBoxContainer/PurchaseButton

func _ready() -> void:
	if left_arrow != null:
		left_arrow.pressed.connect(_on_left_arrow_pressed)
	if right_arrow != null:
		right_arrow.pressed.connect(_on_right_arrow_pressed)
	if purchase_button != null:
		purchase_button.pressed.connect(_on_purchase_button_pressed)
	
	if popup_menu != null:
		popup_menu.visible = false

func _on_left_arrow_pressed() -> void:
	pass

func _on_right_arrow_pressed() -> void:
	pass

func _on_purchase_button_pressed() -> void:
	pass
