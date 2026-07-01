extends PanelContainer
class_name UpgradeItemPanel

## Panel displaying a single upgrade for a unit

const BuildingUpgradeVisualsScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeVisuals.gd")

@onready var _icon_placeholder: ColorRect = $Margin/HBox/IconPlaceholder
@onready var _icon_texture: TextureRect = $Margin/HBox/IconPlaceholder/IconTexture
@onready var _upgrade_name: Label = $Margin/HBox/VBox/UpgradeName
@onready var _upgrade_description: Label = $Margin/HBox/VBox/UpgradeDescription

func setup(upgrade_name: String, description: String, icon: Texture2D = null, status_color: Color = BuildingUpgradeVisualsScript.SLOT_COLOR_LOCKED) -> void:
	if _upgrade_name:
		_upgrade_name.text = upgrade_name

	if _upgrade_description:
		_upgrade_description.text = description

	if _icon_placeholder:
		_icon_placeholder.color = status_color

	if _icon_texture:
		_icon_texture.texture = icon
