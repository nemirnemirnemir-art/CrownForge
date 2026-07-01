extends Control
class_name UpgradeSlot

@onready var icon_rect: TextureRect = $Icon
@onready var level_label: Label = $LevelLabel
@onready var lock_overlay: ColorRect = $LockOverlay
@onready var background: ColorRect = $Background

var perk_id: String = ""

func setup(perk_data: Resource, required_level: int, unlocked: bool) -> void:
	if not is_inside_tree():
		return
	
	if perk_data and perk_data is PerkData:
		var data = perk_data as PerkData
		perk_id = data.id
		if icon_rect:
			icon_rect.texture = data.icon
		if level_label:
			level_label.text = "Lvl %d" % required_level
		tooltip_text = "%s\n%s" % [data.display_name, data.description]
	else:
		if icon_rect:
			icon_rect.texture = null
		if level_label:
			level_label.text = "Lvl %d" % required_level
		tooltip_text = "Level %d" % required_level

	if lock_overlay:
		lock_overlay.visible = not unlocked
	if background:
		if unlocked:
			background.modulate = Color(0.25, 0.5, 0.25)
		else:
			background.modulate = Color(0.2, 0.2, 0.2)
