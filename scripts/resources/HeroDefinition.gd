extends Resource
class_name HeroDefinition

@export var id: String = ""
@export var display_name: String = ""
@export var cost: float = 100.0
@export var base_hp: float = 10.0
@export var base_damage: float = 5.0
@export var is_ranged: bool = false
@export var attack_range: float = 35.0
@export var max_range: float = 200.0

@export_group("Assets")
@export var icon: Texture2D
@export var card_image: Texture2D
@export var sprite_frames: SpriteFrames
