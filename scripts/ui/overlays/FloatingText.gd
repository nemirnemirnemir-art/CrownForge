extends Node2D
class_name FloatingText

## Floating text popup that rises and fades (for Evade, damage numbers, etc.)

@onready var label: Label = $Label

var _velocity: Vector2 = Vector2(0, -80)  # Rise upward
var _fade_duration: float = 1.0
var _elapsed: float = 0.0

func _ready() -> void:
    if not label:
        label = Label.new()
        label.name = "Label"
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        add_child(label)
    
    # Start animation
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "position", position + Vector2(0, -50), _fade_duration)
    tween.tween_property(self, "modulate:a", 0.0, _fade_duration)
    tween.chain().tween_callback(queue_free)

func setup(text: String, color: Color = Color.WHITE, font_size: int = 18) -> void:
    if label:
        label.text = text
        label.add_theme_color_override("font_color", color)
        label.add_theme_font_size_override("font_size", font_size)
        label.add_theme_color_override("font_outline_color", Color.BLACK)
        label.add_theme_constant_override("outline_size", 2)

## Static helper to spawn floating text at a position
static func spawn_at(parent: Node, global_pos: Vector2, text: String, color: Color = Color.WHITE) -> FloatingText:
    var scene := preload("res://scenes/ui/overlays/FloatingText.tscn")
    var instance: FloatingText = scene.instantiate()
    parent.add_child(instance)
    instance.global_position = global_pos
    instance.setup(text, color)
    return instance

## Quick spawn for common cases
static func spawn_evade(parent: Node, global_pos: Vector2) -> void:
    spawn_at(parent, global_pos, "EVADE", Color.RED)

static func spawn_damage(parent: Node, global_pos: Vector2, amount: int) -> void:
    spawn_at(parent, global_pos, str(amount), Color.YELLOW)

static func spawn_heal(parent: Node, global_pos: Vector2, amount: int) -> void:
    spawn_at(parent, global_pos, "+" + str(amount), Color.GREEN)

static func spawn_stun(parent: Node, global_pos: Vector2) -> void:
    spawn_at(parent, global_pos, "STUNNED", Color.PURPLE)
