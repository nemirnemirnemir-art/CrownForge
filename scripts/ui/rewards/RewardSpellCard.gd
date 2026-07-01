extends Panel
class_name RewardSpellCard

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const CharacterCreationSpellCatalogScript := preload("res://scripts/ui/spells/CharacterCreationSpellCatalog.gd")

signal selected(spell_id: String)

@onready var icon_bg: ColorRect = get_node_or_null("IconBG")
@onready var icon_rect: TextureRect = get_node_or_null("Icon")
@onready var name_label: Label = get_node_or_null("NameLabel")
@onready var description_label: Label = get_node_or_null("DescriptionLabel")
@onready var choose_button: Button = get_node_or_null("ChooseButton")

var spell_id: String = ""

func _ready() -> void:
	if choose_button:
		choose_button.pressed.connect(_on_choose_pressed)

func setup(new_spell_id: String) -> void:
	spell_id = new_spell_id
	var normalized_id := String(spell_id).strip_edges().to_lower()
	var king_spell_def := CharacterCreationSpellCatalogScript.get_spell_def(normalized_id)
	var config := PathRegistryScript.load_spell_config(spell_id) as SpellConfig
	if name_label:
		if not king_spell_def.is_empty():
			name_label.text = String(king_spell_def.get("display_name", spell_id))
		else:
			name_label.text = config.spell_name if config and config.spell_name != "" else spell_id
	if description_label:
		if not king_spell_def.is_empty():
			var lines: Array[String] = []
			lines.append(String(king_spell_def.get("description", "")))
			var resource_id := CharacterCreationSpellCatalogScript.get_spell_cost_resource_id(normalized_id)
			var cost := CharacterCreationSpellCatalogScript.get_spell_cost(normalized_id, 0)
			var cooldown := int(round(CharacterCreationSpellCatalogScript.get_spell_effective_cooldown(normalized_id, 0)))
			if resource_id != "" and cost > 0:
				lines.append("Cost: %d %s" % [cost, resource_id.replace("_", " ")])
			if cooldown > 0:
				lines.append("⌛ %d sec" % cooldown)
			description_label.text = "\n".join(lines)
		else:
			description_label.text = config.description if config else ""
	if icon_rect:
		if not king_spell_def.is_empty():
			icon_rect.texture = king_spell_def.get("texture", null) as Texture2D
		elif config and config.has_method("get_icon_or_placeholder"):
			icon_rect.texture = config.get_icon_or_placeholder()
		elif config:
			icon_rect.texture = config.icon
	if icon_bg:
		icon_bg.color = Color(0.25, 0.85, 0.35, 1.0)

func _on_choose_pressed() -> void:
	if spell_id != "":
		selected.emit(spell_id)
