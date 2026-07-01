extends Node
class_name HeroFieldAnimations

var _hero: Node2D
var _hero_id: String = ""
var _animation_sprite: AnimatedSprite2D
var _state_machine: Node
var _is_attack_animation_playing: bool = false
var _is_death_animation_playing: bool = false

func play_walk() -> void:
    _switch_to_sprite("AnimWalk")
    update_animation("walk")

func play_attack() -> void:
    _switch_to_sprite("AnimAttack")
    update_animation("attack")

func play_death() -> void:
    if not _hero:
        return

    _is_attack_animation_playing = false
    _is_death_animation_playing = true

    var walk_node := _hero.get_node_or_null("AnimWalk")
    var attack_node := _hero.get_node_or_null("AnimAttack")
    var dead_node := _hero.get_node_or_null("AnimDead") as AnimatedSprite2D

    if walk_node:
        walk_node.visible = false
    if attack_node:
        attack_node.visible = false

    if dead_node:
        dead_node.visible = true
        if dead_node.sprite_frames:
            var anim_to_play := ""
            if dead_node.sprite_frames.has_animation("dead"):
                anim_to_play = "dead"
            elif dead_node.sprite_frames.has_animation("death"):
                anim_to_play = "death"
            elif dead_node.sprite_frames.has_animation("default"):
                anim_to_play = "default"

            if anim_to_play != "":
                if dead_node.sprite_frames.has_method("set_animation_loop"):
                    dead_node.sprite_frames.set_animation_loop(anim_to_play, false)
                dead_node.play(anim_to_play)

func _switch_to_sprite(node_name: String) -> void:
    if not _hero: return
    var walk_node = _hero.get_node_or_null("AnimWalk")
    var attack_node = _hero.get_node_or_null("AnimAttack")
    
    if walk_node and attack_node:
        walk_node.visible = (node_name == "AnimWalk")
        attack_node.visible = (node_name == "AnimAttack")
        _animation_sprite = _hero.get_node(node_name)
        
        # Ensure signal is connected for the new active sprite
        if not _animation_sprite.animation_finished.is_connected(_on_animation_finished):
            _animation_sprite.animation_finished.connect(_on_animation_finished)

func setup(hero: Node2D, animation_sprite: AnimatedSprite2D, hero_id: String, state_machine: Node) -> void:
    _hero = hero
    _animation_sprite = animation_sprite
    _state_machine = state_machine
    
    # Initial nodes check
    var walk_node = _hero.get_node_or_null("AnimWalk")
    var attack_node = _hero.get_node_or_null("AnimAttack")
    
    if walk_node and attack_node:
        walk_node.visible = true
        attack_node.visible = false
        _animation_sprite = walk_node
    
    if _animation_sprite:
        if not _animation_sprite.animation_finished.is_connected(_on_animation_finished):
            _animation_sprite.animation_finished.connect(_on_animation_finished)

    set_hero_id(hero_id)

func set_hero_id(hero_id: String) -> void:
    _hero_id = hero_id.to_lower() if hero_id != null else ""
    if _hero_id == "": return

    var base_id := _get_base_id(_hero_id)
    var force_dynamic_frames := (
        base_id == "slinger"
        or base_id == "hunter"
        or base_id == "madman"
        or base_id == "clown"
        or base_id == "black_sheep"
        or base_id == "paladin"
        or base_id == "paladin_mage"
        or base_id == "barbarian"
        or base_id == "black_unicorn"
        or base_id == "bumblebee"
        or base_id == "catapult"
        or base_id == "fire_mage"
        or base_id == "giant"
        or base_id == "goose_rider"
        or base_id == "griffin"
        or base_id == "healer_mage"
        or base_id == "horseman"
        or base_id == "lightning_mage"
        or base_id == "longbowman"
        or base_id == "paladin_mage"
        or base_id == "pangolin"
        or base_id == "pumpkin_warrior"
        or base_id == "ram"
        or base_id == "rider"
        or base_id == "white_unicorn"
        or base_id == "hydra"
    )
    
    var walk_node = _hero.get_node_or_null("AnimWalk") as AnimatedSprite2D
    var attack_node = _hero.get_node_or_null("AnimAttack") as AnimatedSprite2D
    
    # Check if we ALREADY have valid frames in the scene (manually edited by user)
    var has_valid_frames := false
    if walk_node and walk_node.sprite_frames:
        var sf = walk_node.sprite_frames
        # print("[HeroFieldAnimations] DEBUG %s: walk_node.sprite_frames exists" % _hero_id)
        # print("[HeroFieldAnimations] DEBUG %s: animation_names = %s" % [_hero_id, sf.get_animation_names()])
        # If it has 'walk' or 'attack' and they aren't empty, it's a manual config
        var walk_count = sf.get_frame_count("walk") if sf.has_animation("walk") else 0
        var attack_count = sf.get_frame_count("attack") if sf.has_animation("attack") else 0
        # print("[HeroFieldAnimations] DEBUG %s: walk_count=%d, attack_count=%d" % [_hero_id, walk_count, attack_count])
        if walk_count > 0 or attack_count > 0:
            has_valid_frames = true
            # print("[HeroFieldAnimations] %s: Keeping manually configured frames" % _hero_id)
    else:
        # print("[HeroFieldAnimations] DEBUG %s: No walk_node or sprite_frames found" % _hero_id)
        pass
    
    if force_dynamic_frames:
        has_valid_frames = false

    if not has_valid_frames:
        # print("[HeroFieldAnimations] %s: Loading dynamic frames via HeroAssetLoader" % _hero_id)
        var frames = HeroAssetLoader.load_hero_sprite_frames(_hero_id)
        if frames and frames.get_animation_names().size() > 0:
            if walk_node: walk_node.sprite_frames = frames
            if attack_node: attack_node.sprite_frames = frames
            
            if not walk_node and not attack_node and _animation_sprite:
                _animation_sprite.sprite_frames = frames
        else:
            push_warning("HeroFieldAnimations: No dynamic frames found for " + _hero_id)

func _get_base_id(hero_id: String) -> String:
    if hero_id == "":
        return hero_id

    var parts := hero_id.rsplit("_", true, 1)
    if parts.size() == 2 and String(parts[1]).is_valid_int():
        return String(parts[0])
    return hero_id

func start_initial_animation() -> void:
    if _animation_sprite == null or _animation_sprite.sprite_frames == null:
        return
    _animation_sprite.visible = true
    if not _animation_sprite.is_playing():
        if _animation_sprite.sprite_frames.has_animation("idle"):
            _animation_sprite.play("idle")
        elif _animation_sprite.sprite_frames.has_animation("walk"):
            _animation_sprite.play("walk")

func update_animation(animation_name: String) -> void:
    if not _hero: return

    if animation_name == "death" or animation_name == "dead":
        play_death()
        return

    if _is_death_animation_playing:
        return
    
    # Guard: don't let walk/idle animations override a locked attack animation
    if animation_name != "attack" and _is_attack_animation_playing:
        # if Engine.get_physics_frames() % 60 == 0:
        #	 print("[AnimDebug] %s blocked '%s' because attack is locked" % [_hero_id, animation_name])
        return
    
    # Auto-switch sprite node based on animation type if dual sprites are used
    var walk_node = _hero.get_node_or_null("AnimWalk")
    var attack_node = _hero.get_node_or_null("AnimAttack")
    
    if walk_node and attack_node:
        var target_node_name = "AnimAttack" if animation_name == "attack" else "AnimWalk"
        if _animation_sprite == null or _animation_sprite.name != target_node_name:
            # print("[AnimDebug] %s Switching sprite: %s -> %s" % [_hero_id, _animation_sprite.name if _animation_sprite else "null", target_node_name])
            _switch_to_sprite(target_node_name)
    
    if _animation_sprite == null or _animation_sprite.sprite_frames == null:
        return
        
    # Avoid redundant play calls
    if _animation_sprite.animation == animation_name and _animation_sprite.is_playing():
        # print("[AnimDebug] %s skipping redundant play('%s')" % [_hero_id, animation_name])
        return
        
    if _animation_sprite.sprite_frames.has_animation(animation_name):
        # print("[AnimDebug] %s PLAYING '%s' (Frame: %d)" % [_hero_id, animation_name, Engine.get_physics_frames()])
        _animation_sprite.play(animation_name)
    else:
        # Fallback for missing idle
        if animation_name == "idle" and _animation_sprite.sprite_frames.has_animation("walk"):
            if _animation_sprite.animation != "walk":
                # print("[AnimDebug] %s Fallback to 'walk' for idle" % _hero_id)
                _animation_sprite.play("walk")

func is_attack_animation_playing() -> bool:
    return _is_attack_animation_playing

func set_attack_animation_playing(value: bool) -> void:
    _is_attack_animation_playing = value
    # If we are stopping attack, ensure we aren't stuck in AnimAttack
    if not _is_attack_animation_playing:
        if _animation_sprite and _animation_sprite.name == "AnimAttack":
            # We don't force switch here, update_animation("walk") will handle it
            pass

func _on_animation_finished() -> void:
    if _is_attack_animation_playing and String(_animation_sprite.animation).begins_with("attack"):
        _is_attack_animation_playing = false
    if _state_machine and "current_state" in _state_machine and _state_machine.current_state:
        if _state_machine.current_state.has_method("on_animation_finished"):
            _state_machine.current_state.on_animation_finished()
