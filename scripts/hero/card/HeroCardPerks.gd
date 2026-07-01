extends RefCounted
class_name HeroCardPerks

## Perk management
## Create and update perk icons

var _hero_card: Control

func initialize(hero_card: Control) -> void:
	_hero_card = hero_card

func update_perks(hero_data: Dictionary) -> void:
	# We need a container for perks. If not exists, create one?
	# Ideally it should be in the scene. Let's try to find it or create it.
	var right_panel = _hero_card.get_node_or_null("MainContainer/RightPanel")
	if not right_panel:
		return
	
	var perks_container = right_panel.get_node_or_null("PerksContainer")
	if not perks_container:
		# Create if missing (fallback)
		perks_container = GridContainer.new()
		perks_container.name = "PerksContainer"
		perks_container.columns = 7  # Max 7 perks per row
		right_panel.add_child(perks_container)
	
	for child in perks_container.get_children():
		child.queue_free()
		
	var perks = hero_data.get("perks", [])
	for perk_id in perks:
		# We need perk data. HeroCore has registry but it's private.
		# We need a way to get perk icon.
		# Let's add HeroCore.get_perk_data(id).
		var perk_data = HeroCore.get_perk_def(perk_id) # Assuming we add this
		if perk_data:
			# ✅ Create a Panel with colored background
			var panel = Panel.new()
			panel.custom_minimum_size = Vector2(32, 32)
			
			# ✅ Green background for all perks (can later add is_positive)
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.8, 0.2, 1.0)  # Green
			panel.add_theme_stylebox_override("panel", style)
			
			var icon = TextureRect.new()
			icon.texture = perk_data.icon
			icon.custom_minimum_size = Vector2(25, 25)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.tooltip_text = "%s\n%s" % [perk_data.display_name, perk_data.description]
			
			# ✅ Center the icon in the panel
			icon.anchor_left = 0.5
			icon.anchor_top = 0.5
			icon.anchor_right = 0.5
			icon.anchor_bottom = 0.5
			icon.offset_left = -12
			icon.offset_top = -12
			icon.offset_right = 12
			icon.offset_bottom = 12
			
			panel.add_child(icon)
			perks_container.add_child(panel)

