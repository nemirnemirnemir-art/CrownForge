extends RefCounted
class_name GameScenePendingRewards

const REWARD_BOX_TEXTURE := preload("res://assets/ui/rewards/reward_box.png")
const BUTTON_SIZE := Vector2(88.0, 88.0)
const BUTTON_MARGIN_RIGHT := 28.0
const BUTTON_MARGIN_BOTTOM := 28.0
const BUTTON_EXTRA_LIFT := 220.0

var _game_scene: Node = null
var _ui_layer: CanvasLayer = null
var _queue: Array[Dictionary] = []
var _reward_button: TextureButton = null
var _count_label: Label = null

func initialize(game_scene: Node, ui_layer: CanvasLayer) -> void:
    _game_scene = game_scene
    _ui_layer = ui_layer
    _ensure_button()
    _refresh_button()

func enqueue_reward(reward: Dictionary) -> void:
    if reward.is_empty():
        return
    _queue.append(reward.duplicate(true))
    _refresh_button()

func enqueue_rewards(rewards: Array) -> void:
    for reward_value in rewards:
        if reward_value is Dictionary:
            enqueue_reward(reward_value as Dictionary)

func has_pending_rewards() -> bool:
    return not _queue.is_empty()

func get_pending_count() -> int:
    return _queue.size()

func claim_next_reward() -> bool:
    if _queue.is_empty():
        return false
    if _game_scene == null:
        return false
    if _game_scene.has_method("can_open_pending_reward") and not bool(_game_scene.call("can_open_pending_reward")):
        return false
    if not _game_scene.has_method("open_pending_reward"):
        return false

    var reward := _queue[0]
    var opened := bool(_game_scene.call("open_pending_reward", reward))
    if not opened:
        return false

    _queue.remove_at(0)
    _refresh_button()
    return true

func _ensure_button() -> void:
    if _ui_layer == null:
        return
    if _reward_button != null and is_instance_valid(_reward_button):
        return

    _reward_button = TextureButton.new()
    _reward_button.name = "PendingRewardButton"
    _reward_button.visible = false
    _reward_button.mouse_filter = Control.MOUSE_FILTER_STOP
    _reward_button.texture_normal = REWARD_BOX_TEXTURE
    _reward_button.texture_hover = REWARD_BOX_TEXTURE
    _reward_button.texture_pressed = REWARD_BOX_TEXTURE
    _reward_button.custom_minimum_size = BUTTON_SIZE
    _reward_button.size = BUTTON_SIZE
    _reward_button.anchor_left = 1.0
    _reward_button.anchor_top = 1.0
    _reward_button.anchor_right = 1.0
    _reward_button.anchor_bottom = 1.0
    _reward_button.offset_left = -BUTTON_MARGIN_RIGHT - BUTTON_SIZE.x
    _reward_button.offset_top = -BUTTON_MARGIN_BOTTOM - BUTTON_SIZE.y - BUTTON_EXTRA_LIFT
    _reward_button.offset_right = -BUTTON_MARGIN_RIGHT
    _reward_button.offset_bottom = -BUTTON_MARGIN_BOTTOM - BUTTON_EXTRA_LIFT
    _reward_button.tooltip_text = "Pending rewards"
    _reward_button.pressed.connect(_on_reward_button_pressed)
    _ui_layer.add_child(_reward_button)

    _count_label = Label.new()
    _count_label.name = "CountLabel"
    _count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _count_label.anchors_preset = Control.PRESET_FULL_RECT
    _count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _count_label.add_theme_font_size_override("font_size", 28)
    _count_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
    _count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
    _count_label.add_theme_constant_override("outline_size", 8)
    _reward_button.add_child(_count_label)

func _refresh_button() -> void:
    if _reward_button == null:
        return
    var pending := _queue.size()
    _reward_button.visible = pending > 0
    if _count_label:
        _count_label.text = str(pending)

func _on_reward_button_pressed() -> void:
    claim_next_reward()
