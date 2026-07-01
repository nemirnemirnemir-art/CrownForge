extends "res://scripts/hero/states/HeroState.gd"

## Hero Moving To Combat State (Refactored - Physics)
## Direct movement using CharacterBody2D physics
const ATTACK_TOLERANCE: float = 20.0  ## Unified buffer for attack range checks

func enter() -> void:
    if not hero:
        if state_machine: hero = state_machine._get_hero()
        if not hero: return
    
    if hero.has_method("_update_animation"):
        hero._update_animation("walk")

func update(delta: float) -> void:
    if not hero: return
    
    # CRITICAL: Stop if hero is dead
    if hero.is_dead: return

    if hero.has_method("is_passive_patroller") and hero.is_passive_patroller():
        hero.set_current_target(null)
        state_machine.change_state("HeroIdleState")
        return
    
    # Check if hero is orphaned (not in HeroCore anymore)
    if _is_hero_orphaned():
        print("[HeroMovingToCombatState] %s is orphaned - removing" % hero.hero_id)
        hero.queue_free()
        return
    
    var target = hero.get_current_target()
    
    # Validate target
    if target == null or not is_instance_valid(target) or (target.has_method("is_dead") and target.is_dead) or ("is_invincible" in target and bool(target.is_invincible)):
        _find_new_target_or_idle()
        return
        
    # Check range logic in update (decoupled from physics)
    var dist := hero.global_position.distance_to(target.global_position)
    var attack_range: float = 25.0
    if "attack_range" in hero:
        attack_range = float(hero.attack_range)
    var effective_range: float = attack_range + ATTACK_TOLERANCE
    
    # Ranged heroes attack from greater distance
    if not hero.is_melee:
        effective_range = 250.0
        if "max_range" in hero:
            effective_range = float(hero.max_range)
    
    if dist <= effective_range:
        hero.velocity = Vector2.ZERO # Stop moving
        # Check if this hero has a heal state (healer units)
        if state_machine.states.has("herohealstate"):
            state_machine.change_state("HeroHealState")
        else:
            state_machine.change_state("HeroAttackingState")

func physics_update(delta: float) -> void:
    if not hero or hero.is_dead: return
    if hero.has_method("is_passive_patroller") and hero.is_passive_patroller():
        hero.velocity = Vector2.ZERO
        return
    
    var target = hero.get_current_target()
    if target and is_instance_valid(target):
        var direction = (target.global_position - hero.global_position).normalized()
        var move_speed := float(hero.move_speed)
        if "speed_multiplier" in hero:
            move_speed *= maxf(0.0, float(hero.speed_multiplier))
        move_speed *= _get_artifact_move_speed_multiplier()
        hero.velocity = direction * move_speed
        hero.move_and_slide()
        
        if hero.has_method("enforce_battlefield_bounds"):
            var bounced_direction: Vector2 = hero.enforce_battlefield_bounds(direction)
            if bounced_direction != direction and bounced_direction != Vector2.ZERO:
                hero.velocity = bounced_direction * move_speed
        
        # Face target - use flip_h on sprite instead of scale to avoid flickering
        if abs(direction.x) > 0.3:
            var should_flip = direction.x < 0
            var walk_sprite = hero.get_node_or_null("AnimWalk")
            var attack_sprite = hero.get_node_or_null("AnimAttack")
            if walk_sprite:
                walk_sprite.flip_h = should_flip
            if attack_sprite:
                attack_sprite.flip_h = should_flip
            if hero.animation_sprite:
                hero.animation_sprite.flip_h = should_flip

func exit() -> void:
    if hero:
        hero.velocity = Vector2.ZERO

func _find_new_target_or_idle() -> void:
    var target = CombatTargetFinder.find_nearest(hero, "enemy", 1000.0)
    if target and is_instance_valid(target):
        hero.set_current_target(target)
    else:
        hero.set_current_target(null)
        state_machine.change_state("HeroIdleState")

func _get_artifact_move_speed_multiplier() -> float:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return 1.0
    var artifact_core := tree.root.get_node_or_null("ArtifactCore")
    if artifact_core == null or not artifact_core.has_method("get_unit_move_speed_multiplier"):
        return 1.0
    var unit_id := _resolve_base_unit_id(String(hero.hero_id))
    if unit_id == "":
        return 1.0
    return maxf(0.01, float(artifact_core.call("get_unit_move_speed_multiplier", unit_id)))

func _resolve_base_unit_id(hero_id: String) -> String:
    var id := hero_id.to_lower()
    if id.contains("_"):
        var parts := id.rsplit("_", true, 1)
        if parts.size() == 2 and String(parts[1]).is_valid_int():
            return String(parts[0])
    return id
