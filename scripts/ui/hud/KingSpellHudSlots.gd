extends RefCounted
class_name KingSpellHudSlots

const KingSpellSlotScene := preload("res://scenes/ui/hud/KingSpellSlot.tscn")
const CharacterCreationSpellCatalogScript := preload("res://scripts/ui/spells/CharacterCreationSpellCatalog.gd")

func build_slots(container: Control, out_slots: Array[Control], count: int, slot_size: Vector2, icon_scale: float, empty_texture: Texture2D, passive_shape: bool, hud: Control) -> void:
	out_slots.clear()
	for child in container.get_children():
		child.queue_free()
	for i in range(count):
		var slot := KingSpellSlotScene.instantiate() as Control
		if slot == null:
			continue
		if slot.has_method("configure"):
			slot.call("configure", i, slot_size, icon_scale, empty_texture, passive_shape)
		if slot.has_signal("pressed"):
			slot.pressed.connect(hud._on_slot_pressed.bind(passive_shape))
		if slot.has_signal("hover_started"):
			slot.hover_started.connect(hud._on_slot_hover_started.bind(passive_shape))
		if slot.has_signal("hover_ended"):
			slot.hover_ended.connect(hud._on_slot_hover_ended.bind(passive_shape))
		container.add_child(slot)
		out_slots.append(slot)

func refresh_selected_spells(active_slots: Array[Control], passive_slots: Array[Control]) -> void:
	var active_spell_id := ""
	var passive_spell_id := ""
	
	var eng := Engine.get_main_loop() as SceneTree
	var king_state = eng.root.get_node_or_null("/root/KingSpellState") if eng else null
	var char_state = eng.root.get_node_or_null("/root/CharacterCreationState") if eng else null

	if king_state != null:
		active_spell_id = String(king_state.selected_active_spell_id)
		passive_spell_id = String(king_state.selected_passive_spell_id)
		
	if active_spell_id == "" and char_state != null:
		active_spell_id = String(char_state.selected_active_spell_id)
	if passive_spell_id == "" and char_state != null:
		passive_spell_id = String(char_state.selected_passive_spell_id)
		
	set_slot_spell(active_slots, 0, CharacterCreationSpellCatalogScript.create_spell_config(active_spell_id))
	set_slot_spell(passive_slots, 0, CharacterCreationSpellCatalogScript.create_spell_config(passive_spell_id))

func set_slot_spell(slots: Array[Control], slot_index: int, config: Resource) -> void:
	if slot_index < 0 or slot_index >= slots.size():
		return
	var slot := slots[slot_index]
	if slot == null:
		return
	if slot.has_method("set_spell"):
		slot.call("set_spell", config)

func update_runtime_state(active_slots: Array[Control], passive_slots: Array[Control]) -> void:
	var eng := Engine.get_main_loop() as SceneTree
	var king_state = eng.root.get_node_or_null("/root/KingSpellState") if eng else null

	for slot in active_slots:
		if slot == null or not slot.has_method("get_spell_id"):
			continue
		var spell_id := String(slot.call("get_spell_id"))
		var cooldown_left := 0.0
		var disabled_state := false
		if king_state and spell_id != "":
			cooldown_left = king_state.get_active_cooldown(spell_id)
			disabled_state = king_state.get_active_ability_unavailability_reason(spell_id) != ""
		if slot.has_method("set_cooldown_left"):
			slot.call("set_cooldown_left", cooldown_left)
		if slot.has_method("set_disabled_state"):
			slot.call("set_disabled_state", disabled_state)

	for slot in passive_slots:
		if slot == null or not slot.has_method("get_spell_id"):
			continue
		var spell_id := String(slot.call("get_spell_id"))
		var is_used := false
		var disabled_state := false
		if king_state and spell_id != "":
			is_used = king_state.is_passive_used(spell_id)
			disabled_state = is_used or king_state.get_passive_ability_unavailability_reason(spell_id) != ""
		if slot.has_method("set_cooldown_left"):
			slot.call("set_cooldown_left", 0.0)
		if slot.has_method("set_disabled_state"):
			slot.call("set_disabled_state", disabled_state)
