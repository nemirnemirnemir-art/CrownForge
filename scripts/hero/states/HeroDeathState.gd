extends "res://scripts/hero/states/HeroState.gd"

## Hero Death State
## Handles death animation and removal/cleanup

func enter() -> void:
	# print("[HeroDeathState] 💀 ENTER for %s" % (hero.name if hero else "null"))
	
	if not hero:
		return
	
	# Stop all movement immediately
	hero.velocity = Vector2.ZERO
	if hero.has_method("stop_navigation"):
		hero.stop_navigation()
	
	if hero.has_method("_update_animation"):
		hero._update_animation("death")
	
	# Disable components
	var aggro = hero.get_node_or_null("AggroArea")
	if aggro: 
		aggro.monitoring = false
		# print("[HeroDeathState] 💀 %s: Disabled AggroArea" % hero.name)
	
	var ac = hero.get_node_or_null("AttackComponent")
	if ac and ac.has_method("cancel_attack"):
		ac.cancel_attack()
		# print("[HeroDeathState] 💀 %s: Cancelled attack" % hero.name)
		
	var hurt = hero.get_node_or_null("Hurtbox")
	if hurt: 
		hurt.monitoring = false
		# print("[HeroDeathState] 💀 %s: Disabled Hurtbox" % hero.name)
	
	# Prefer removal after AnimDead finishes (if it exists)
	var dead_node := hero.get_node_or_null("AnimDead")
	if dead_node and dead_node is AnimatedSprite2D:
		var dead_sprite := dead_node as AnimatedSprite2D
		if not dead_sprite.animation_finished.is_connected(_on_cleanup_timeout):
			dead_sprite.animation_finished.connect(_on_cleanup_timeout, Object.CONNECT_ONE_SHOT)
			# print("[HeroDeathState] 💀 %s: cleanup on AnimDead.animation_finished" % hero.name)

	# Fallback timer to remove
	get_tree().create_timer(3.0).timeout.connect(_on_cleanup_timeout)
	# print("[HeroDeathState] 💀 %s death sequence started, cleanup in 3s" % hero.name)

func _on_cleanup_timeout() -> void:
	if is_instance_valid(hero):
		# print("[HeroDeathState] 💀 %s cleanup timeout fired -> queue_free()" % hero.name)
		hero.call_deferred("queue_free")

func update(_delta: float) -> void:
	# Do nothing while dead
	pass




