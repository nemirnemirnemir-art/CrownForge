extends RefCounted
class_name GameSceneSkills

## Управление навыками GameScene
## Автоклик, эффекты навыков

const SKILL1_EFFECT_DURATION: float = 0.45
const MAX_SKILL1_EFFECTS: int = 3
const SKILL1_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/Skill1Effect.tscn")

var _game_scene: Node2D
var _waves_manager
var skill1_autoclick_timer: float = 0.0
var active_skill1_effects: Array[Node2D] = []

func initialize(game_scene: Node2D, waves_manager) -> void:
	_game_scene = game_scene
	_waves_manager = waves_manager

func process_autoclicks(delta: float) -> void:
	if not SkillCore or not SkillCore.is_skill1_active():
		return
	
	if not BattleCore or not BattleCore.is_wave_active():
		return
	
	skill1_autoclick_timer -= delta
	if skill1_autoclick_timer <= 0.0:
		skill1_autoclick_timer = SkillCore.get_skill1_autoclick_interval()
		_perform_autoclick()

func _perform_autoclick() -> void:
	if not BattleCore:
		print("[GameSceneSkills] ⚠️ _perform_autoclick: BattleCore is null")
		return
	
	var targets = _waves_manager.get_alive_mobs()
	if targets.is_empty():
		print("[GameSceneSkills] ⚠️ _perform_autoclick: No alive targets")
		return
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var hit_count: int = 1
	if SkillCore:
		hit_count = SkillCore.get_skill1_autoclick_hits()
	
	for i in range(hit_count):
		var alive: Array = []
		for candidate in targets:
			if not is_instance_valid(candidate):
				continue
			if candidate is Mob:
				if not candidate.is_dead:
					alive.append(candidate)
			elif "is_dead" in candidate:
				if not bool(candidate.is_dead):
					alive.append(candidate)
		
		if alive.is_empty():
			break
		
		var target = alive[rng.randi_range(0, alive.size() - 1)]
		if not target or not is_instance_valid(target):
			continue
		
		var base = EconomyCore.get_base_damage()
		var mult = EconomyCore.get_upgrade_multiplier()
		var stars = EconomyCore.get_stars()
		var skills_mult: float = 1.0
		if SkillCore:
			skills_mult = SkillCore.get_damage_multiplier()
		var click_bonus: float = 0.0
		if TownCore:
			click_bonus = TownCore.get_click_damage_bonus()
		
		var damage = DamageCalculator.calculate_click_damage(base, mult, stars, skills_mult, click_bonus)

		var is_crit := false
		if SkillCore and SkillCore.has_method("roll_crit"):
			is_crit = bool(SkillCore.roll_crit())
			if is_crit and SkillCore.has_method("get_crit_damage_multiplier"):
				damage *= float(SkillCore.get_crit_damage_multiplier())

		if SkillCore and SkillCore.has_method("try_apply_gold_digger_on_click"):
			SkillCore.try_apply_gold_digger_on_click(target)

		print("[GameSceneSkills] 🎯 Auto-click hitting %s for %.1f damage" % [target.name, damage])
		target.take_damage(damage, is_crit)
		_spawn_skill1_effect(target)

func _spawn_skill1_effect(target: Node2D) -> void:
	if not SKILL1_EFFECT_SCENE:
		return
	
	var effect: Node2D = SKILL1_EFFECT_SCENE.instantiate()
	if not effect:
		return
	
	var head_offset: float = -80.0
	if target is Mob:
		head_offset = -80.0
	
	var head_position: Vector2 = target.global_position + Vector2(0, head_offset)
	
	var world_node = _game_scene.get_node_or_null("WorldYSort")
	if world_node:
		world_node.add_child(effect)
	else:
		_game_scene.add_child(effect)
	
	effect.global_position = head_position
	
	var skill_texture_path: String = "res://assets/gameplay/skills/clickskill.png"
	if ResourceLoader.exists(skill_texture_path):
		var texture: Texture2D = load(skill_texture_path)
		if texture:
			if effect.has_method("set_texture"):
				effect.set_texture(texture)
			else:
				var sprite = effect.get_node_or_null("Sprite2D")
				if sprite:
					sprite.texture = texture
					sprite.scale = Vector2(0.5, 0.5)
					sprite.z_index = 100
	
	if effect.has_method("play_and_remove"):
		effect.play_and_remove()
	else:
		var effect_sprite = effect.get_node_or_null("Sprite2D")
		if effect_sprite:
			var tween = _game_scene.create_tween()
			tween.tween_property(effect_sprite, "modulate:a", 0.0, 0.5)
			await tween.finished
		else:
			await _game_scene.get_tree().create_timer(0.5).timeout
		if is_instance_valid(effect):
			effect.queue_free()
	
	active_skill1_effects.append(effect)
	while active_skill1_effects.size() > MAX_SKILL1_EFFECTS:
		var oldest: Node2D = active_skill1_effects.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	
	if _game_scene.is_inside_tree():
		var tree = _game_scene.get_tree()
		if tree:
			var timer = tree.create_timer(SKILL1_EFFECT_DURATION)
			timer.timeout.connect(Callable(self, "_on_skill1_effect_timeout").bind(effect.get_instance_id()))

func process_skill_effects(_delta: float) -> void:
	for effect in active_skill1_effects.duplicate():
		if not is_instance_valid(effect):
			active_skill1_effects.erase(effect)

func _on_skill1_effect_timeout(effect_instance_id: int) -> void:
	var effect: Node2D = null
	for e in active_skill1_effects:
		if is_instance_valid(e) and e.get_instance_id() == effect_instance_id:
			effect = e
			break

	if effect != null and active_skill1_effects.has(effect):
		active_skill1_effects.erase(effect)
	if is_instance_valid(effect):
		effect.queue_free()

func _clear_skill1_effects() -> void:
	for effect in active_skill1_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	active_skill1_effects.clear()

func on_skill1_toggled(active: bool) -> void:
	if active:
		skill1_autoclick_timer = 0.0
	else:
		skill1_autoclick_timer = SkillCore.get_skill1_autoclick_interval()
		_clear_skill1_effects()

func on_skill2_activated() -> void:
	print("[GameSceneSkills] ✨ Double Damage skill activated")

func on_skill2_ended() -> void:
	print("[GameSceneSkills] ✨ Double Damage skill ended")
