extends TextureRect
class_name HeroPortrait

const UnitFaceLibraryScript := preload("res://scripts/utils/UnitFaceLibrary.gd")

@export_group("Hero Portraits")
@export var crossbowman_face: Texture2D
@export var slinger_face: Texture2D
@export var light_spearman_face: Texture2D
@export var gnome_face: Texture2D
@export var light_legionary_face: Texture2D
@export var peasant_face: Texture2D
@export var small_bones_face: Texture2D
@export var healer_mage_face: Texture2D
@export var assassin_face: Texture2D

func _ready() -> void:
	custom_minimum_size = Vector2(50, 50)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func set_unit_portrait(unit_id: String) -> void:
	var id := unit_id.strip_edges().to_lower()
	id = id.replace(" ", "_")
	match id:
		"crossbowman":
			texture = crossbowman_face
		"slinger":
			texture = slinger_face
		"light_spearman", "spearman", "light_spear":
			texture = light_spearman_face
		"gnome", "gnome_mercenary", "gnome_merc":
			texture = gnome_face
		"light_legionary", "legionary", "swordsman", "swordman":
			texture = light_legionary_face
		"peasant":
			texture = peasant_face
		"small_bones", "smallbones":
			texture = small_bones_face
		"healer_mage", "healer":
			texture = healer_mage_face
		"assassin", "assasin":
			texture = assassin_face
		_:
			texture = UnitFaceLibraryScript.get_face_texture(id, unit_id)
