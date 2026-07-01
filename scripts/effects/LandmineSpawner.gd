extends SpellEffect

## Landmine spawner - creates 3 landmines randomly scattered in target area

const LandmineScene = preload("res://scenes/spells/effects/LandmineEffect.tscn")

const MINE_COUNT: int = 3

func execute_effect() -> void:
    if not config:
        push_error("[LandmineSpawner] No config provided")
        queue_free()
        return
    
    var radius: float = 80.0
    if config.target_radius > 0:
        radius = float(config.target_radius)
    var spawn_radius: float = radius * 2.0
    
    # Spawn 3 landmines at random positions within radius
    for i in range(MINE_COUNT):
        var mine: Node2D = LandmineScene.instantiate()
        
        # Random position within circular area
        var angle: float = randf() * TAU
        # sqrt(rand) gives uniform distribution over the disk area
        var distance: float = sqrt(randf()) * spawn_radius
        var offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance
        
        # Add to parent (world container)
        if get_parent():
            get_parent().add_child(mine)
        else:
            get_tree().current_scene.add_child(mine)
        
        mine.global_position = target_position + offset
        
        # Initialize mine with config
        if mine.has_method("initialize"):
            mine.initialize(config, mine.global_position)
    
    # Self-destruct after spawning
    queue_free()
