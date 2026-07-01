extends Control

@onready var play_button: Button = $Center/VBox/PlayButton
@onready var start_with_character_creation_checkbox: CheckBox = $Center/VBox/StartWithCharacterCreation
@onready var quit_button: Button = $Center/VBox/QuitButton

func _ready() -> void:
	if start_with_character_creation_checkbox:
		var bypass_enabled := GameStartSettings != null and GameStartSettings.has_method("is_game_scene_character_creation_bypass_enabled") and bool(GameStartSettings.is_game_scene_character_creation_bypass_enabled())
		start_with_character_creation_checkbox.button_pressed = false if bypass_enabled else (GameStartSettings == null or bool(GameStartSettings.start_via_character_creation))
		start_with_character_creation_checkbox.disabled = bypass_enabled
		if not start_with_character_creation_checkbox.toggled.is_connected(_on_start_mode_toggled):
			start_with_character_creation_checkbox.toggled.connect(_on_start_mode_toggled)
	if play_button and not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
	if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_mode_toggled(enabled: bool) -> void:
	if GameStartSettings:
		GameStartSettings.set_start_via_character_creation(enabled)

func _on_play_pressed() -> void:
	var bypass_enabled := GameStartSettings != null and GameStartSettings.has_method("is_game_scene_character_creation_bypass_enabled") and bool(GameStartSettings.is_game_scene_character_creation_bypass_enabled())
	if KingSpellState:
		KingSpellState.reset_runtime_state()
	if CharacterCreationState and (bypass_enabled or GameStartSettings == null or not GameStartSettings.start_via_character_creation):
		CharacterCreationState.clear()
	if KingSpellState and (bypass_enabled or GameStartSettings == null or not GameStartSettings.start_via_character_creation):
		KingSpellState.clear_selected_spells()
	if GameStartSettings:
		GameStartSettings.start_game(get_tree())

func _on_quit_pressed() -> void:
	get_tree().quit()
