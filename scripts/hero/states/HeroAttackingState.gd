extends "res://scripts/hero/states/HeroState.gd"

## Hero Attacking State (Refactored)
## Simple loop: FREEZE → Attack → Check nearest → Repeat/Exit
const CLOWN_HIT_DAMAGE: float = 3.0
const CLOWN_DOT_DAMAGE_PER_TICK: float = 2.0
const CLOWN_DOT_TICKS: int = 4
const CLOWN_DOT_TICK_INTERVAL: float = 1.0

const FIRE_DOT_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/FireDotEffect.tscn")

var _attack_timer: float = 0.0
var _hit_applied: bool = false
var _attack_cooldown: float = 1.0
var _hit_delay: float = 0.75  ## Damage applied at 0.75s into 1.0s attack (near end of animation)
var _next_dot_attack_id: int = 1
var _attack_count: int = 0

func enter() -> void:
    if not hero:
        if state_machine: hero = state_machine._get_hero()
        if not hero: return

    if _is_passive_patroller():
        hero.set_current_target(null)
        state_machine.change_state("HeroIdleState")
        return
    
    # FREEZE: Stop all movement immediately
    _freeze_position()

    # Get attack params
    var base_cooldown: float = 1.0
    if "attack_cooldown" in hero:
        base_cooldown = float(hero.attack_cooldown)
    var attack_speed_mult: float = 1.0
    if "attack_speed_multiplier" in hero:
        attack_speed_mult = maxf(0.05, float(hero.attack_speed_multiplier))
    var hero_unit_id: String = ""
    if "hero_id" in hero:
        hero_unit_id = String(hero.hero_id)
    attack_speed_mult *= _get_troop_attack_speed_multiplier(hero_unit_id)
    attack_speed_mult = maxf(0.05, attack_speed_mult)
    _attack_cooldown = base_cooldown / attack_speed_mult
    _hit_delay = 0.4
    
    # Validate target
    var target = hero.get_current_target()
    if not _is_valid_target(target):
        _find_next_target_or_exit()
        return
    
    # Start attack cycle
    _start_attack(target)

func update(delta: float) -> void:
    if not hero:
        return
    
    # CRITICAL: Stop if hero is dead
    if hero.is_dead:
        return
    
    # Check if hero is orphaned (not in HeroCore anymore)
    if _is_hero_orphaned():
        print("[HeroAttackingState] %s is orphaned - removing" % hero.hero_id)
        hero.queue_free()
        return

    if _is_passive_patroller():
        hero.set_current_target(null)
        state_machine.change_state("HeroIdleState")
        return
    
    # IMMEDIATE CHECK: if target is dead/invalid, look for new one NOW
    var target = hero.get_current_target()
    if not _is_valid_target(target):
        _on_attack_finished()
        return
    
    # Keep frozen
    _freeze_position()
    
    # Attack timer
    _attack_timer -= delta
    
    # Apply damage at hit_delay point
    if not _hit_applied and _attack_timer <= (_attack_cooldown - _hit_delay):
        _hit_applied = true
        var hit_landed := _apply_damage()

        if _is_hit_and_run_unit() and hit_landed:
            state_machine.change_state("HeroHitAndRunRetreatState")
            return
        
        # IMMEDIATE CHECK: if target died from our hit, don't wait for cooldown
        target = hero.get_current_target()
        if not _is_valid_target(target):
            _on_attack_finished()
            return
    
    # Attack cycle finished
    if _attack_timer <= 0:
        _on_attack_finished()

func physics_update(_delta: float) -> void:
    if not hero or hero.is_dead: return
    # NEVER move while attacking
    _freeze_position()

func exit() -> void:
    if hero and hero.has_method("set_attack_animation_playing"):
        hero.set_attack_animation_playing(false)

# ============ PRIVATE METHODS ============

func _freeze_position() -> void:
    hero.velocity = Vector2.ZERO

func _start_attack(target: Node2D) -> void:
    # CRITICAL: Don't start attack if hero is dead
    if hero.is_dead:
        print("[HeroAttack] %s is DEAD, cannot start attack" % hero.name)
        return
    
    if not target or not is_instance_valid(target):
        if _is_ballista_debug():
            print("[BALLISTA ATTACK][start_abort] hero_id=%s reason=invalid_target" % _debug_hero_id())
        return

    if _is_ballista_debug():
        print("[BALLISTA ATTACK][start] hero_id=%s target=%s target_pos=%s hero_pos=%s" % [
            _debug_hero_id(),
            _debug_target_name(target),
            str(target.global_position),
            str(hero.global_position)
        ])
    
    _attack_timer = _attack_cooldown
    _hit_applied = false
    
    # Face target - use flip_h on sprite instead of scale to avoid flickering
    var direction_x = target.global_position.x - hero.global_position.x
    if abs(direction_x) > 0.3:
        var should_flip = direction_x < 0
        var walk_sprite = hero.get_node_or_null("AnimWalk")
        var attack_sprite = hero.get_node_or_null("AnimAttack")
        if walk_sprite:
            walk_sprite.flip_h = should_flip
        if attack_sprite:
            attack_sprite.flip_h = should_flip
        if hero.animation_sprite:
            hero.animation_sprite.flip_h = should_flip
    
    # Play attack animation
    if hero.has_method("_update_animation"):
        hero._update_animation("attack")
    if hero.has_method("set_attack_animation_playing"):
        hero.set_attack_animation_playing(true)

func _apply_damage() -> bool:
    # CRITICAL: Don't apply damage if hero is dead
    if hero.is_dead:
        print("[HeroAttack] ⚠️ %s is DEAD, skipping damage application" % hero.name)
        if _is_ballista_debug():
            print("[BALLISTA ATTACK][apply_abort] hero_id=%s reason=hero_dead" % _debug_hero_id())
        return false
    
    var target = hero.get_current_target()
    if not _is_valid_target(target):
        # print("[HeroAttack] %s: No valid target for damage" % hero.name)
        if _is_ballista_debug():
            print("[BALLISTA ATTACK][apply_abort] hero_id=%s reason=invalid_target target=%s" % [_debug_hero_id(), _debug_target_name(target)])
        return false
    
    # Distance check
    var dist := hero.global_position.distance_to(target.global_position)
    const ATTACK_TOLERANCE: float = 20.0
    var effective_range: float = hero.attack_range + ATTACK_TOLERANCE  # 25 + 20 = 45
    
    # For ranged heroes, use larger effective range
    if not hero.is_melee:
        effective_range = 250.0
        if "max_range" in hero:
            effective_range = float(hero.max_range)
    
    if dist > effective_range:
        print("[HeroAttack] %s: Target %s out of range (dist=%.1f, range=%.1f)" % [hero.name, target.name, dist, effective_range])
        if _is_ballista_debug():
            print("[BALLISTA ATTACK][apply_abort] hero_id=%s reason=out_of_range target=%s dist=%.2f range=%.2f" % [_debug_hero_id(), _debug_target_name(target), dist, effective_range])
        return false
    
    # Deal damage
    var is_hit_and_run := _is_hit_and_run_unit()
    var damage: float = 10.0
    if hero.has_method("get_attack_damage"):
        damage = hero.get_attack_damage()
    if is_hit_and_run:
        damage = CLOWN_HIT_DAMAGE
    var hero_unit_id: String = ""
    if "hero_id" in hero:
        hero_unit_id = _resolve_base_unit_id(String(hero.hero_id))
    var troop_core: Object = _get_troop_bonus_core()
    
    # Debug: check ranged hero conditions
    var has_fire_method = hero.has_method("fire_projectile")
    var has_proj_scene = hero.projectile_scene != null
    if _is_ballista_debug():
        print("[BALLISTA ATTACK][apply_damage] hero_id=%s target=%s dist=%.2f range=%.2f is_melee=%s has_fire=%s has_scene=%s scene=%s" % [
            _debug_hero_id(),
            _debug_target_name(target),
            dist,
            effective_range,
            str(hero.is_melee),
            str(has_fire_method),
            str(has_proj_scene),
            str(hero.projectile_scene)
        ])
    
    # For ranged heroes, fire projectile instead of direct damage
    if not hero.is_melee and has_fire_method and has_proj_scene:
        # Pre-fire: compute Long Shot distance bonus for ranged units
        var on_hit_effects_ranged := _get_combat_on_hit_effects()
        var projectile_mult := 1.0
        for effect_r: Dictionary in on_hit_effects_ranged:
            var etype_r: String = String(effect_r.get("type", ""))
            if etype_r == "long_shot":
                var max_bonus: float = float(effect_r.get("max_bonus_percent", 1.0))
                var max_range_val: float = 250.0
                if "max_range" in hero:
                    max_range_val = float(hero.max_range)
                var distance_ratio: float = clampf(dist / max_range_val, 0.0, 1.0)
                projectile_mult *= (1.0 + max_bonus * distance_ratio)
        # Set pending multiplier on hero for projectile system to pick up
        hero.set("_pending_projectile_multiplier", projectile_mult)
        if _is_ballista_debug():
            print("[BALLISTA ATTACK][fire_branch] hero_id=%s target=%s projectile_mult=%.3f scene=%s" % [
                _debug_hero_id(),
                _debug_target_name(target),
                projectile_mult,
                str(hero.projectile_scene)
            ])
        hero.fire_projectile(target)
        _try_fire_bonus_projectile(target, projectile_mult)
        # Post-fire: handle jumping lightning chain for ranged units
        for effect_r2: Dictionary in on_hit_effects_ranged:
            var etype_r2: String = String(effect_r2.get("type", ""))
            if etype_r2 == "jumping_lightning":
                _apply_jumping_lightning(target, damage * projectile_mult, effect_r2)
        # print("[HeroAttack] %s fired projectile at %s (damage=%.1f, dist=%.1f)" % [hero.name, target.name, damage, dist])
        _attack_count += 1
        return true
    else:
        # Melee: direct damage to SINGLE target only
        if target.has_method("take_damage"):
            _attack_count += 1

            # --- Combat hook: pre-damage effects (crit, slow bonus) ---
            var final_damage := damage
            var crit_applied := false
            var on_hit_effects := _get_combat_on_hit_effects()

            # Capture target state before damage for condition checks
            var target_was_full_hp := false
            if "current_health" in target and "max_health" in target:
                var cur_hp: float = float(target.current_health)
                var max_hp: float = float(target.max_health)
                target_was_full_hp = max_hp > 0.0 and cur_hp >= max_hp

            for effect: Dictionary in on_hit_effects:
                var etype: String = String(effect.get("type", ""))
                if etype == "crit":
                    if _check_crit_trigger(effect):
                        final_damage *= float(effect.get("multiplier", 2.0))
                        crit_applied = true
                elif etype == "slow":
                    var bonus_pct: float = float(effect.get("bonus_damage_percent", 0.0))
                    if bonus_pct > 0.0:
                        final_damage *= (1.0 + bonus_pct)
                elif etype == "long_shot":
                    var max_bonus: float = float(effect.get("max_bonus_percent", 1.0))
                    var max_range_val: float = hero.attack_range + ATTACK_TOLERANCE
                    if "max_range" in hero:
                        max_range_val = float(hero.max_range)
                    var distance_ratio: float = clampf(dist / max_range_val, 0.0, 1.0)
                    final_damage *= (1.0 + max_bonus * distance_ratio)

            target.take_damage(int(final_damage), crit_applied)
            # print("[HeroAttack] %s dealt %d melee damage to %s (dist=%.1f)" % [hero.name, int(final_damage), target.name, dist])

            var artifact_core := _get_artifact_core()
            if artifact_core != null and artifact_core.has_method("try_apply_post_hit_stun"):
                artifact_core.call("try_apply_post_hit_stun", target, hero_unit_id, _attack_count, troop_core)

            # --- Combat hook: post-damage effects (DoT, stun, lifesteal, slow, war_of_attrition, jumping_lightning) ---
            for effect2: Dictionary in on_hit_effects:
                var etype2: String = String(effect2.get("type", ""))
                if etype2 == "dot":
                    _apply_upgrade_dot(target, effect2)
                elif etype2 == "stun":
                    _apply_upgrade_stun(target, effect2, target_was_full_hp)
                elif etype2 == "lifesteal":
                    _apply_upgrade_lifesteal(int(final_damage), effect2)
                elif etype2 == "slow":
                    _apply_upgrade_slow(target, effect2)
                elif etype2 == "war_of_attrition":
                    _apply_war_of_attrition(target, effect2)
                elif etype2 == "jumping_lightning":
                    _apply_jumping_lightning(target, final_damage, effect2)
                elif etype2 == "long_shot":
                    # Long Shot for melee: already applied in pre-damage via final_damage calc
                    pass

            if is_hit_and_run:
                _apply_clown_dot(target)

            return true

    return false


func _is_ballista_debug() -> bool:
    return hero != null and "hero_id" in hero and String(hero.hero_id).begins_with("ballista")


func _debug_hero_id() -> String:
    if hero == null or not ("hero_id" in hero):
        return "unknown"
    return String(hero.hero_id)


func _debug_target_name(target) -> String:
    if target == null or not is_instance_valid(target):
        return "null"
    if target is Node:
        return String((target as Node).name)
    return str(target)

func _on_attack_finished() -> void:
    # IMMEDIATE target check after attack (no delay)
    _find_next_target_or_exit()

func _find_next_target_or_exit() -> void:
    if _is_passive_patroller():
        hero.set_current_target(null)
        state_machine.change_state("HeroIdleState")
        return

    # Find nearest enemy using unified finder - wide range to catch all nearby enemies
    var search_range: float = 1000.0 # Very wide search to find any enemy on field
    var next_target = CombatTargetFinder.find_nearest(hero, "enemy", search_range)
    
    if next_target and is_instance_valid(next_target):
        hero.set_current_target(next_target)
        
        # Check if in attack range
        var dist := hero.global_position.distance_to(next_target.global_position)
        var attack_range: float = 25.0
        if "attack_range" in hero:
            attack_range = float(hero.attack_range)
        const ATTACK_TOLERANCE: float = 20.0
        var effective_range: float = attack_range + ATTACK_TOLERANCE
        
        # Ranged heroes have larger attack range
        if not hero.is_melee:
            effective_range = 250.0
            if "max_range" in hero:
                effective_range = float(hero.max_range)
        
        if dist <= effective_range:
            # Stay and attack
            _start_attack(next_target)
        else:
            # Move to target
            state_machine.change_state("HeroMovingToCombatState")
    else:
        # No enemies - go idle
        hero.set_current_target(null)
        state_machine.change_state("HeroIdleState")

func _is_valid_target(target) -> bool:
    if target == null or not is_instance_valid(target):
        return false
    if "is_dead" in target and bool(target.is_dead):
        return false
    if "is_invincible" in target and bool(target.is_invincible):
        return false
    return true

func _is_passive_patroller() -> bool:
    return hero and hero.has_method("is_passive_patroller") and hero.is_passive_patroller()

func _is_hit_and_run_unit() -> bool:
    return hero and hero.has_method("is_hit_and_run_unit") and hero.is_hit_and_run_unit()

func _apply_clown_dot(target: Node2D) -> void:
    if target == null or not is_instance_valid(target):
        return

    var dot_attack_base_id := _next_dot_attack_id
    _next_dot_attack_id += 1
    _run_clown_dot(target, dot_attack_base_id)

func _run_clown_dot(target: Node2D, dot_attack_base_id: int) -> void:
    var tree := get_tree()
    if tree == null:
        return

    for tick in range(CLOWN_DOT_TICKS):
        await tree.create_timer(CLOWN_DOT_TICK_INTERVAL).timeout

        if target == null or not is_instance_valid(target):
            return

        _apply_dot_tick_damage(target, dot_attack_base_id, tick)

func _apply_dot_tick_damage(target: Node2D, dot_attack_base_id: int, tick_index: int) -> void:
    var attack_id := dot_attack_base_id * 100 + tick_index
    var source: Node = self
    if hero and is_instance_valid(hero):
        source = hero

    var hurtbox = target.get_node_or_null("Hurtbox")
    if hurtbox and hurtbox.has_method("apply_hit"):
        hurtbox.apply_hit(CLOWN_DOT_DAMAGE_PER_TICK, source, attack_id)
        return

    if target.has_method("take_damage"):
        target.take_damage(int(round(CLOWN_DOT_DAMAGE_PER_TICK)))

func _get_troop_attack_speed_multiplier(hero_id: String) -> float:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return 1.0
    var troop_core := tree.root.get_node_or_null("TroopBonusCore")
    if troop_core == null or not troop_core.has_method("get_unit_multiplier"):
        return 1.0
    var unit_id := _resolve_base_unit_id(hero_id)
    if unit_id == "":
        return 1.0
    return maxf(0.01, float(troop_core.call("get_unit_multiplier", unit_id, 2)))

func _resolve_base_unit_id(hero_id: String) -> String:
    var id := hero_id.to_lower()
    if id.contains("_"):
        var parts := id.rsplit("_", true, 1)
        if parts.size() == 2 and String(parts[1]).is_valid_int():
            return String(parts[0])
    return id

# ============ COMBAT HOOK HELPERS ============

func _get_combat_on_hit_effects() -> Array[Dictionary]:
    ## Resolve on-hit effects for the current hero's unit type.
    var hero_unit_id: String = ""
    if "hero_id" in hero:
        hero_unit_id = _resolve_base_unit_id(String(hero.hero_id))
    if hero_unit_id == "":
        return []
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return []
    var upgrade_core := tree.root.get_node_or_null("BuildingUpgradeCore")
    if upgrade_core == null or not upgrade_core.has_method("get_on_hit_effects"):
        return []
    var raw_result: Variant = upgrade_core.call("get_on_hit_effects", hero_unit_id)
    if raw_result is Array:
        var typed_result: Array[Dictionary] = []
        for item: Variant in raw_result:
            if item is Dictionary:
                typed_result.append(item as Dictionary)
        return typed_result
    return []

func _check_crit_trigger(effect: Dictionary) -> bool:
    ## Returns true if a crit effect should trigger this attack.
    var mode: String = String(effect.get("mode", "every_nth"))
    if mode == "every_nth":
        var n: int = int(effect.get("n", 5))
        if n <= 0:
            return false
        return (_attack_count % n) == 0
    elif mode == "chance":
        var chance: float = float(effect.get("chance", 0.0))
        return randf() < chance
    return false

func _apply_upgrade_dot(target: Node2D, effect: Dictionary) -> void:
    ## Applies a DoT from a building upgrade effect.
    if target == null or not is_instance_valid(target):
        return
    var ticks: int = int(effect.get("ticks", 1))
    var tick_damage: float = float(effect.get("tick_damage", 1.0))
    var tick_interval: float = float(effect.get("tick_interval", 1.0))
    var element: String = String(effect.get("element", ""))
    var dot_id := _next_dot_attack_id
    _next_dot_attack_id += 1

    # Spawn fire visual effect for fire element DoTs
    if element == "fire" and FIRE_DOT_EFFECT_SCENE:
        _spawn_fire_dot_effect(target, ticks, tick_interval)

    _run_upgrade_dot(target, dot_id, ticks, tick_damage, tick_interval)

func _spawn_fire_dot_effect(target: Node2D, ticks: int, tick_interval: float) -> void:
    if target == null or not is_instance_valid(target):
        return
    var effect_instance := FIRE_DOT_EFFECT_SCENE.instantiate()
    if effect_instance == null:
        return
    # Set effect duration based on DoT params
    if "tick_count" in effect_instance:
        effect_instance.tick_count = ticks
    if "tick_interval" in effect_instance:
        effect_instance.tick_interval = tick_interval
    # Add to scene tree
    var tree := get_tree()
    if tree and tree.current_scene:
        tree.current_scene.add_child(effect_instance)
    else:
        target.add_child(effect_instance)
    # Attach to target
    if effect_instance.has_method("attach_to_target"):
        effect_instance.attach_to_target(target)
    else:
        effect_instance.global_position = target.global_position

func _run_upgrade_dot(target: Node2D, dot_id: int, ticks: int, tick_damage: float, tick_interval: float) -> void:
    var tree := get_tree()
    if tree == null:
        return
    for tick: int in range(ticks):
        await tree.create_timer(tick_interval).timeout
        if target == null or not is_instance_valid(target):
            return
        var attack_id := dot_id * 100 + tick
        var source: Node = self
        if hero and is_instance_valid(hero):
            source = hero
        var hurtbox: Node = target.get_node_or_null("Hurtbox")
        if hurtbox and hurtbox.has_method("apply_hit"):
            hurtbox.apply_hit(tick_damage, source, attack_id)
        elif target.has_method("take_damage"):
            target.take_damage(int(round(tick_damage)))

func _apply_upgrade_stun(target: Node2D, effect: Dictionary, was_full_hp: bool) -> void:
    ## Applies a stun from a building upgrade effect.
    if target == null or not is_instance_valid(target):
        return
    var condition: String = String(effect.get("condition", "none"))
    var chance: float = float(effect.get("chance", 1.0))
    var duration: float = float(effect.get("duration", 1.0))

    # Condition checks
    if condition == "full_hp":
        if not was_full_hp:
            return
    elif condition == "every_nth":
        var n: int = int(effect.get("n", 5))
        if n <= 0 or (_attack_count % n) != 0:
            return

    # Chance roll
    if chance < 1.0 and randf() >= chance:
        return

    if target.has_method("apply_stun"):
        target.apply_stun(duration)

func _apply_upgrade_lifesteal(damage_dealt: int, effect: Dictionary) -> void:
    ## Heals the hero for a percent of damage dealt.
    var percent: float = float(effect.get("percent", 0.0))
    if percent <= 0.0 or damage_dealt <= 0:
        return
    var heal_amount: int = int(round(float(damage_dealt) * percent))
    if heal_amount <= 0:
        return
    var hero_id: String = ""
    if "hero_id" in hero:
        hero_id = String(hero.hero_id)
    if hero_id == "":
        return
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return
    var hero_core := tree.root.get_node_or_null("HeroCore")
    if hero_core and hero_core.has_method("heal_hero"):
        hero_core.heal_hero(hero_id, heal_amount)

func _apply_upgrade_slow(target: Node2D, effect: Dictionary) -> void:
    ## Applies a temporary speed reduction to the target.
    if target == null or not is_instance_valid(target):
        return
    var duration: float = float(effect.get("duration", 2.0))
    var factor: float = float(effect.get("factor", 0.5))
    # Apply slow via the mob's stats speed_multiplier if available
    if "stats" in target and target.stats != null:
        var stats: Variant = target.stats
        if "speed_multiplier" in stats:
            stats.speed_multiplier = factor
            _restore_speed_after(target, duration)

func _restore_speed_after(target: Node2D, duration: float) -> void:
    var tree := get_tree()
    if tree == null:
        return
    await tree.create_timer(duration).timeout
    if target == null or not is_instance_valid(target):
        return
    if "stats" in target and target.stats != null:
        var stats: Variant = target.stats
        if "speed_multiplier" in stats:
            stats.speed_multiplier = 1.0

func _apply_war_of_attrition(target: Node2D, effect: Dictionary) -> void:
    ## Applies -30% movement speed AND -30% attack speed for 3 seconds.
    if target == null or not is_instance_valid(target):
        return
    var duration: float = float(effect.get("duration", 3.0))
    var speed_factor: float = float(effect.get("speed_factor", 0.70))
    var attack_speed_factor: float = float(effect.get("attack_speed_factor", 0.70))
    # Apply movement speed reduction
    if "stats" in target and target.stats != null:
        var stats: Variant = target.stats
        if "speed_multiplier" in stats:
            stats.speed_multiplier = speed_factor
        # Apply attack speed reduction
        if "attack_speed_multiplier" in stats:
            stats.attack_speed_multiplier = attack_speed_factor
        _restore_war_of_attrition_after(target, duration)

func _restore_war_of_attrition_after(target: Node2D, duration: float) -> void:
    var tree := get_tree()
    if tree == null:
        return
    await tree.create_timer(duration).timeout
    if target == null or not is_instance_valid(target):
        return
    if "stats" in target and target.stats != null:
        var stats: Variant = target.stats
        if "speed_multiplier" in stats:
            stats.speed_multiplier = 1.0
        if "attack_speed_multiplier" in stats:
            stats.attack_speed_multiplier = 1.0

func _apply_jumping_lightning(primary_target: Node2D, base_damage: float, effect: Dictionary) -> void:
    ## Chain lightning from the primary target to nearby enemies.
    ## Each chain deals 50% of the previous damage.
    if primary_target == null or not is_instance_valid(primary_target):
        return
    var max_chains: int = int(effect.get("max_chains", 2))
    var damage_decay: float = float(effect.get("damage_decay", 0.50))
    var chain_range: float = float(effect.get("chain_range", 150.0))
    if max_chains <= 0:
        return
    var chain_range_sq: float = chain_range * chain_range
    var hit_targets: Array[Node2D] = [primary_target]
    var current_pos: Vector2 = primary_target.global_position
    var current_damage: float = base_damage
    for _chain_i: int in range(max_chains):
        current_damage *= damage_decay
        if current_damage < 1.0:
            break
        var next_target: Node2D = _find_chain_target(current_pos, hit_targets, chain_range_sq)
        if next_target == null:
            break
        hit_targets.append(next_target)
        # Deal chain damage
        if next_target.has_method("take_damage"):
            next_target.take_damage(int(current_damage))
        current_pos = next_target.global_position

func _find_chain_target(from_pos: Vector2, exclude: Array[Node2D], max_dist_sq: float) -> Node2D:
    ## Find the nearest valid enemy within range, excluding already-hit targets.
    var tree := get_tree()
    if tree == null:
        return null
    var best: Node2D = null
    var best_d2: float = max_dist_sq
    for group_name: String in ["enemy", "mobs", "enemies"]:
        for node: Node in tree.get_nodes_in_group(group_name):
            if not (node is Node2D) or not is_instance_valid(node):
                continue
            var candidate := node as Node2D
            if "is_dead" in candidate and bool(candidate.is_dead):
                continue
            if exclude.has(candidate):
                continue
            var d2: float = from_pos.distance_squared_to(candidate.global_position)
            if d2 < best_d2:
                best_d2 = d2
                best = candidate
    return best

func _get_artifact_core() -> Object:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("ArtifactCore")

func _get_troop_bonus_core() -> Object:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("TroopBonusCore")

func _try_fire_bonus_projectile(target: Node2D, projectile_mult: float) -> void:
    if target == null or not is_instance_valid(target):
        return
    var artifact_core := _get_artifact_core()
    if artifact_core == null or not artifact_core.has_method("get_bonus_projectile_chance"):
        return
    var chance := clampf(float(artifact_core.call("get_bonus_projectile_chance")), 0.0, 1.0)
    if chance <= 0.0:
        return
    if randf() >= chance:
        return
    hero.set("_pending_projectile_multiplier", projectile_mult)
    hero.fire_projectile(target)
