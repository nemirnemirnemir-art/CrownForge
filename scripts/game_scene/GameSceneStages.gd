extends RefCounted
class_name GameSceneStages

## GameScene stage & biome management
## Background loading, stage switching

var _game_scene: Node2D
var _biome_layer: Node2D
var _background: Sprite2D

func _get_singleton(node_name: String) -> Node:
    if _game_scene == null or not is_instance_valid(_game_scene):
        return null
    if not _game_scene.is_inside_tree():
        return null
    var tree := _game_scene.get_tree()
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null(node_name)

func initialize(game_scene: Node2D, biome_layer: Node2D, background: Sprite2D) -> void:
    _game_scene = game_scene
    _biome_layer = biome_layer
    _background = background

func load_background() -> void:
    if not _biome_layer:
        # print("[GameSceneStages] ⚠️ biome_layer node is null!")
        return
    
    # Clear old biome
    for child in _biome_layer.get_children():
        child.queue_free()
    
    # Get biome name from StageCore
    var stage_core := _get_singleton("StageCore")
    var current_stage: int = stage_core.get_current_stage() if stage_core != null and stage_core.has_method("get_current_stage") else 0
    var biome_name_full: String = stage_core.get_biome_name(current_stage) if stage_core != null and stage_core.has_method("get_biome_name") else ""
    var biome_name: String = biome_name_full
    if " " in biome_name_full:
        biome_name = biome_name_full.split(" ")[0]
    
    # Load biome scene
    var biome_scene_path: String = "res://biomes/Biome_" + biome_name + ".tscn"
    
    # print("[GameSceneStages] Loading biome: %s (from %s)" % [biome_scene_path, biome_name_full])
    
    if ResourceLoader.exists(biome_scene_path):
        var biome_scene: PackedScene = load(biome_scene_path)
        if biome_scene:
            var biome_instance: Node2D = biome_scene.instantiate()
            if biome_instance:
                _biome_layer.add_child(biome_instance)
                
                # Center biome on screen
                var viewport = _game_scene.get_viewport()
                if viewport:
                    var viewport_size: Vector2 = viewport.get_visible_rect().size
                    biome_instance.position = viewport_size / 2.0
                    # print("[GameSceneStages] ✅ Biome centered at: %s" % biome_instance.position)

                _update_portal_spawn(biome_instance)
                
                # Hide old Background
                if _background:
                    _background.visible = false
                
                # print("[GameSceneStages] ✅ Biome loaded successfully: %s" % biome_name)
                return
    
    # Fallback: use old Background if biome is not found
    if _background:
        var background_path: String = "res://assets/environment/backgrounds/forest.png"
        if ResourceLoader.exists(background_path):
            var texture: Texture2D = load(background_path)
            if texture:
                _background.texture = texture
                _background.visible = true
                _background.z_index = -100 # Lower z_index to be behind everything
        
        _background.scale = Vector2(1.0, 1.0)
        var viewport = _game_scene.get_viewport()
        if viewport:
            var viewport_size: Vector2 = viewport.get_visible_rect().size
            _background.position = viewport_size / 2.0

func get_biome_name(stage: int) -> String:
    var stage_core := _get_singleton("StageCore")
    if stage_core == null or not stage_core.has_method("get_biome_name"):
        return ""
    return stage_core.get_biome_name(stage)
func _update_portal_spawn(_biome_instance: Node) -> void:
    # MapMarkerService now automatically reads positions from markers in MapLayout
    # This method is kept for backward compatibility
    pass
