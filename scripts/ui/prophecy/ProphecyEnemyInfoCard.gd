extends PanelContainer
class_name ProphecyEnemyInfoCard

const ThaleahFont := preload("res://assets/ui/fonts/ThaleahFat.ttf")

@onready var portrait: EnemyPortrait = get_node_or_null("Margin/HBox/Portrait")
@onready var name_label: Label = get_node_or_null("Margin/HBox/VBox/Name")
@onready var base_label: Label = get_node_or_null("Margin/HBox/VBox/Base")
@onready var hp_label: Control = get_node_or_null("Margin/HBox/VBox/HP")
@onready var dps_label: Control = get_node_or_null("Margin/HBox/VBox/DPS")

func setup(enemy_id: String, display_name: String, hp: Variant, dps: Variant) -> void:
	if portrait:
		portrait.set_enemy_portrait(enemy_id)
	if name_label:
		name_label.text = display_name
		name_label.add_theme_font_override("font", ThaleahFont)
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
	if base_label:
		base_label.text = "Base characteristics:"
		base_label.add_theme_font_override("font", ThaleahFont)
		base_label.add_theme_font_size_override("font_size", 16)
		base_label.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
	
	_update_split_label(hp_label, "HP: ", "?" if hp == null else str(hp))
	_update_split_label(dps_label, "Damage per second: ", "?" if dps == null else str(dps))

func _update_split_label(node: Control, prefix: String, value: String) -> void:
	if node == null:
		return
	
	# If node is the original Label, replace it with HBoxContainer
	if node is Label:
		var parent = node.get_parent()
		var idx = node.get_index()
		var hbox = HBoxContainer.new()
		hbox.name = node.name + "Split"
		hbox.add_theme_constant_override("separation", 4)
		
		parent.add_child(hbox)
		parent.move_child(hbox, idx)
		
		var l_prefix = Label.new()
		l_prefix.text = prefix
		l_prefix.add_theme_font_override("font", ThaleahFont)
		l_prefix.add_theme_font_size_override("font_size", 18)
		l_prefix.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
		hbox.add_child(l_prefix)
		
		var l_val = Label.new()
		l_val.text = value
		l_val.add_theme_font_override("font", ThaleahFont)
		l_val.add_theme_font_size_override("font_size", 18)
		l_val.add_theme_color_override("font_color", Color.BLACK)
		hbox.add_child(l_val)
		
		node.queue_free()
		
		# Update our reference to the new HBox so subsequent calls work
		if node == hp_label:
			hp_label = hbox
		elif node == dps_label:
			dps_label = hbox
			
	elif node is HBoxContainer:
		var children = node.get_children()
		if children.size() >= 2:
			(children[0] as Label).text = prefix
			(children[1] as Label).text = value
