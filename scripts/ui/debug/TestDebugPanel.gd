extends PanelContainer

signal spawn_peasant_pressed
signal spawn_goblin_bandit_pressed
signal clear_scene_pressed

@onready var _spawn_peasant: Button = get_node_or_null("VBox/SpawnPeasant") as Button
@onready var _spawn_goblin_bandit: Button = get_node_or_null("VBox/SpawnGoblinBandit") as Button
@onready var _clear_scene: Button = get_node_or_null("VBox/ClearScene") as Button

func _ready() -> void:
	if _spawn_peasant:
		_spawn_peasant.pressed.connect(func(): spawn_peasant_pressed.emit())
	if _spawn_goblin_bandit:
		_spawn_goblin_bandit.pressed.connect(func(): spawn_goblin_bandit_pressed.emit())
	if _clear_scene:
		_clear_scene.pressed.connect(func(): clear_scene_pressed.emit())
