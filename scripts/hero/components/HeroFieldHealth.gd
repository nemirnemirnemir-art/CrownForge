extends Node
class_name HeroFieldHealth

var _hero: Node2D
var _hero_id: String = ""
var _health_bar: ProgressBar
var _state_machine: Node

func initialize(hero: Node2D, hero_id: String, health_bar: ProgressBar) -> void:
	setup(hero, hero_id, health_bar, hero.get_node_or_null("StateMachine") if hero else null)

func setup(hero: Node2D, hero_id: String, health_bar: ProgressBar, state_machine: Node) -> void:
	_hero = hero
	_state_machine = state_machine
	_health_bar = health_bar
	set_hero_id(hero_id)
	if HeroCore and HeroCore.has_signal("hero_healed"):
		if not HeroCore.hero_healed.is_connected(_on_hero_healed):
			HeroCore.hero_healed.connect(_on_hero_healed)

func set_hero_id(hero_id: String) -> void:
	_hero_id = hero_id.to_lower() if hero_id != null else ""

func get_current_hp() -> float:
	if not HeroCore or _hero_id == "":
		return 0.0
	var live_data = HeroCore.heroes.get(_hero_id)
	if live_data:
		return float(live_data.get("hp", 0.0))
	return 0.0

func update(_delta: float) -> void:
	check_auto_potion_use()
	update_health_bar()
	if get_current_hp() <= 0.0:
		die()

func update_health_bar() -> void:
	if not _health_bar or not HeroCore or _hero_id == "":
		return
	var live_data = HeroCore.heroes.get(_hero_id)
	if not live_data:
		return
	var total_stats = HeroCore.get_hero_total_stats(_hero_id)
	var max_hp = float(total_stats.get("maxHp", 10.0))
	var hp = float(live_data.get("hp", 0.0))
	_health_bar.max_value = max_hp
	_health_bar.value = hp

func check_auto_potion_use() -> void:
	if not HeroCore or _hero_id == "":
		return
	var live_data = HeroCore.heroes.get(_hero_id)
	if not live_data:
		return
	var total_stats = HeroCore.get_hero_total_stats(_hero_id)
	var hp = float(live_data.get("hp", 0.0))
	var max_hp = float(total_stats.get("maxHp", 10.0))
	var potions = int(live_data.get("potions_carried", 0))
	if hp < max_hp * 0.5 and potions > 0:
		if HeroCore.use_potion(_hero_id):
			pass

func take_damage(amount: int) -> void:
	if _hero_id == "" or not HeroCore:
		return
	if HeroCore.has_method("take_damage"):
		HeroCore.take_damage(_hero_id, float(amount))
	elif HeroCore.has_method("modify_hero_hp"):
		HeroCore.modify_hero_hp(_hero_id, -float(amount))
	if DamagePopupPool != null and is_instance_valid(DamagePopupPool) and _hero:
		DamagePopupPool.show_damage(_hero.global_position, amount, false)
	UnitDamageFlash.flash_from_node(_hero)

func die() -> void:
	if _hero and "is_dead" in _hero and bool(_hero.is_dead):
		return
	if _hero and "is_dead" in _hero:
		_hero.is_dead = true
	if _state_machine and _state_machine.has_method("change_state"):
		_state_machine.change_state("HeroDeathState")

func _on_hero_healed(healed_hero_id: String, amount: int) -> void:
	if healed_hero_id != _hero_id:
		return
	var live_data = HeroCore.heroes.get(_hero_id) if HeroCore else null
	if live_data and bool(live_data.get("isActive", false)) and _hero and _hero.get_parent():
		var popup_scene = load("res://scenes/ui/overlays/HealingPopup.tscn")
		if popup_scene:
			var popup = popup_scene.instantiate()
			_hero.get_parent().add_child(popup)
			popup.global_position = _hero.global_position + Vector2(0, -20)
			if popup.has_method("setup"):
				popup.setup(amount)
