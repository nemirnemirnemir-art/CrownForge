extends Node

const MAIN_MENU_SCENE := "res://scenes/ui/MainMenu.tscn"
const CHARACTER_CREATION_SCENE := "res://scenes/dev/CharacterCreationScratchEditable.tscn"
const GAME_SCENE := "res://scenes/game/GameScene.tscn"

var _cached_game_scene_bypass_enabled: Variant = null

var start_via_character_creation: bool = true

func set_start_via_character_creation(enabled: bool) -> void:
    start_via_character_creation = enabled
    _cached_game_scene_bypass_enabled = null


func is_game_scene_character_creation_bypass_enabled() -> bool:
    if _cached_game_scene_bypass_enabled != null:
        return bool(_cached_game_scene_bypass_enabled)

    var packed_scene := load(GAME_SCENE) as PackedScene
    if packed_scene == null:
        _cached_game_scene_bypass_enabled = false
        return false

    var game_scene := packed_scene.instantiate()
    if game_scene == null:
        _cached_game_scene_bypass_enabled = false
        return false

    var enabled := bool(game_scene.get("skip_character_creation_setup"))
    game_scene.free()
    _cached_game_scene_bypass_enabled = enabled
    return enabled

func get_next_play_scene_path() -> String:
    if is_game_scene_character_creation_bypass_enabled():
        return GAME_SCENE
    return CHARACTER_CREATION_SCENE if start_via_character_creation else GAME_SCENE

func start_game(tree: SceneTree) -> void:
    if tree == null:
        return
    tree.change_scene_to_file(get_next_play_scene_path())

func go_to_main_menu(tree: SceneTree) -> void:
    if tree == null:
        return
    tree.change_scene_to_file(MAIN_MENU_SCENE)

func go_to_game_scene(tree: SceneTree) -> void:
    if tree == null:
        return
    tree.change_scene_to_file(GAME_SCENE)
