extends Control

## Panel for displaying and managing active skills.
## Orchestrates SkillsPanelIconCache (texture loading) and
## SkillsPanelBinding (state calculation); applies results to its own nodes.

@onready var _buttons: Array[Button] = [
	null,
	$GridContainer/Skill1Button,
	$GridContainer/Skill2Button,
	$GridContainer/Skill3Button,
	$GridContainer/Skill4Button,
	$GridContainer/Skill5Button,
	$GridContainer/Skill6Button,
	null,
	$GridContainer/Skill8Button,
	$GridContainer/Skill9Button,
	$GridContainer/Skill10Button,
]

@onready var _icons: Array[TextureRect] = [
	null,
	$GridContainer/Skill1Button/SkillIcon,
	$GridContainer/Skill2Button/SkillIcon,
	$GridContainer/Skill3Button/SkillIcon,
	$GridContainer/Skill4Button/SkillIcon,
	$GridContainer/Skill5Button/SkillIcon,
	$GridContainer/Skill6Button/SkillIcon,
	null,
	$GridContainer/Skill8Button/SkillIcon,
	$GridContainer/Skill9Button/SkillIcon,
	$GridContainer/Skill10Button/SkillIcon,
]

@onready var _cooldowns: Array[Control] = [
	null,
	$GridContainer/Skill1Button/CooldownProgress,
	$GridContainer/Skill2Button/CooldownProgress,
	$GridContainer/Skill3Button/CooldownProgress,
	$GridContainer/Skill4Button/CooldownProgress,
	$GridContainer/Skill5Button/CooldownProgress,
	$GridContainer/Skill6Button/CooldownProgress,
	null,
	$GridContainer/Skill8Button/CooldownProgress,
	$GridContainer/Skill9Button/CooldownProgress,
	$GridContainer/Skill10Button/CooldownProgress,
]

var _timer_labels: Array[Label] = []
var _icon_cache: SkillsPanelIconCache
var _binding: SkillsPanelBinding

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	_icon_cache = SkillsPanelIconCache.new()
	_binding    = SkillsPanelBinding.new(SkillCore, TownCore)

	_timer_labels.resize(_buttons.size())

	for i in range(1, _buttons.size()):
		var btn := _buttons[i]
		if btn == null:
			continue
		btn.pressed.connect(Callable(self, "_on_skill_pressed").bind(i))
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.clip_text    = true
		btn.alignment    = HORIZONTAL_ALIGNMENT_CENTER

		var timer_label := Label.new()
		timer_label.name                 = "TimerLabel"
		timer_label.mouse_filter         = Control.MOUSE_FILTER_IGNORE
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		timer_label.anchors_preset       = Control.PRESET_FULL_RECT
		timer_label.offset_left          = 0
		timer_label.offset_top           = 0
		timer_label.offset_right         = 0
		timer_label.offset_bottom        = 0
		timer_label.text                 = ""
		btn.add_child(timer_label)
		_timer_labels[i] = timer_label

	_apply_icons()
	TownCore.building_upgraded.connect(_on_building_upgraded)
	_update_skill_availability()

func _apply_icons() -> void:
	for i in range(1, _icons.size()):
		var icon := _icons[i]
		if icon == null:
			continue
		icon.texture            = _icon_cache.get_icon(i)
		icon.expand_mode        = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode       = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ZERO
		icon.mouse_filter       = Control.MOUSE_FILTER_IGNORE

func _on_skill_pressed(skill_index: int) -> void:
	match skill_index:
		1:
			SkillCore.activate_skill1()
		2:
			SkillCore.activate_skill2()
		3:
			SkillCore.activate_skill3()
		4:
			if SkillCore.has_method("activate_skill4"):
				SkillCore.activate_skill4()
		5:
			if SkillCore.has_method("activate_skill5"):
				SkillCore.activate_skill5()
		6:
			if SkillCore.has_method("activate_skill6"):
				SkillCore.activate_skill6()
		7:
			return
		8:
			if SkillCore.has_method("activate_skill8"):
				SkillCore.activate_skill8()
		9:
			if SkillCore.has_method("activate_skill9"):
				SkillCore.activate_skill9()
		10:
			if SkillCore.has_method("activate_skill10"):
				SkillCore.activate_skill10()

func _process(_delta: float) -> void:
	_apply_skill_states(_binding.build_states(_buttons.size()))

func _apply_skill_states(states: Array) -> void:
	for i in range(1, _buttons.size()):
		var btn := _buttons[i]
		if btn == null:
			continue
		var state: Dictionary = states[i]

		btn.disabled     = state["disabled"]
		btn.modulate     = state["modulate"]
		btn.tooltip_text = state["tooltip"]
		btn.text         = ""

		if i < _timer_labels.size() and _timer_labels[i]:
			_timer_labels[i].text = state["timer_text"]

		var cd_node := _cooldowns[i]
		if cd_node:
			cd_node.visible = state["cd_visible"]
			if state["cd_visible"] and cd_node.has_method("set_cooldown_progress"):
				cd_node.set_cooldown_progress(state["cd_remaining"], state["cd_total"])

func _on_building_upgraded(building_id: String, _level: int) -> void:
	if building_id == "mage_tower":
		_update_skill_availability()

func _update_skill_availability() -> void:
	# Availability is evaluated every _process tick via _binding.build_states().
	pass

func _is_skill1_unlocked() -> bool:
	return TownCore.get_building_level("mage_tower") >= 1
