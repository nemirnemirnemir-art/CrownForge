extends TextureRect
class_name EnemyPortrait

## Component for displaying enemy portraits (50x50)
## All 15 enemy faces should be assigned as @export variables

@export_group("Enemy Portraits")
@export var goblin_bandit_face: Texture2D
@export var blue_slime_face: Texture2D
@export var goblin_crossbowman_face: Texture2D
@export var goblin_swordsman_face: Texture2D
@export var goblin_shaman_face: Texture2D
@export var goblin_fire_mage_face: Texture2D
@export var goblin_lightning_mage_face: Texture2D
@export var goblin_lizard_face: Texture2D
@export var goblin_giant_face: Texture2D
@export var wall_buster_face: Texture2D
@export var goblin_bat_rider_face: Texture2D
@export var goblin_pig_face: Texture2D
@export var crab_rider_face: Texture2D
@export var stone_golem_face: Texture2D
@export var sunfaced_face: Texture2D

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(50, 50)
	expand_mode = TextureRect.EXPAND_FIT_WIDTH
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func set_enemy_portrait(enemy_id: String) -> void:
	match enemy_id.to_lower():
		"goblin_bandit", "goblinbandit":
			texture = goblin_bandit_face
		"blue_slime", "blueslime":
			texture = blue_slime_face
		"goblin_crossbowman", "goblincrossbowman":
			texture = goblin_crossbowman_face
		"goblin_swordsman", "goblinswordsman":
			texture = goblin_swordsman_face
		"goblin_shaman", "goblinshaman":
			texture = goblin_shaman_face
		"goblin_fire_mage", "goblinfiremage":
			texture = goblin_fire_mage_face
		"goblin_lightning_mage", "goblinlightningmage":
			texture = goblin_lightning_mage_face
		"goblin_lizard", "goblinlizard":
			texture = goblin_lizard_face
		"goblin_giant", "goblingiant":
			texture = goblin_giant_face
		"wall_buster", "wallbuster":
			texture = wall_buster_face
		"goblin_bat_rider", "goblinbatrider":
			texture = goblin_bat_rider_face
		"goblin_pig", "goblinpig":
			texture = goblin_pig_face
		"crab_rider", "crabrider":
			texture = crab_rider_face
		"stone_golem", "stonegolem":
			texture = stone_golem_face
		"sunfaced":
			texture = sunfaced_face
		_:
			texture = goblin_bandit_face
