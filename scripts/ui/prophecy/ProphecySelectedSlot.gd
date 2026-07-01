extends Panel
class_name ProphecySelectedSlot

signal cleared(index: int)
signal dropped(index: int, option_patterns: Array)
signal focused(index: int)

const WaveCardScene: PackedScene = preload("res://scenes/ui/prophecy/ProphecyWaveCard.tscn")

@export var slot_index: int = 0

@onready var placeholder: Label = get_node_or_null("Placeholder")
@onready var content: Control = get_node_or_null("Content")
@onready var tier_summary: Control = get_node_or_null("TierSummary")
@onready var hard_chip: Label = get_node_or_null("TierSummary/HardChip")
@onready var mid_chip: Label = get_node_or_null("TierSummary/MidChip")
@onready var easy_chip: Label = get_node_or_null("TierSummary/EasyChip")

var option_patterns: Array = []
var _locked: bool = false

const DEBUG_PROPHECY_DND := true

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    mouse_entered.connect(_on_mouse_entered)
    _update_visual()

func set_option(patterns: Array) -> void:
    option_patterns = patterns
    _update_visual()

func set_locked(locked: bool) -> void:
    _locked = locked
    _update_visual()

func clear_option() -> void:
    option_patterns = []
    _update_visual()

func has_option() -> bool:
    return option_patterns != null and option_patterns.size() > 0

func _gui_input(event: InputEvent) -> void:
    if _locked:
        return
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
            focused.emit(slot_index)
        elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
            if has_option():
                cleared.emit(slot_index)

func _on_mouse_entered() -> void:
    if _locked:
        return
    focused.emit(slot_index)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    if _locked:
        return false
    if typeof(data) != TYPE_DICTIONARY:
        return false
    if not data.has("type"):
        return false
    if DEBUG_PROPHECY_DND:
        print("[ProphecySelectedSlot][DND] can_drop slot=", slot_index, " type=", data.get("type", null))
    return str(data.get("type", "")) == "prophecy_wave_option"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
    if _locked:
        return
    if typeof(data) != TYPE_DICTIONARY:
        return
    if not data.has("patterns"):
        return
    if DEBUG_PROPHECY_DND:
        var patterns: Array = data.get("patterns", [])
        print("[ProphecySelectedSlot][DND] drop slot=", slot_index, " patterns=", (patterns.size() if patterns != null else -1))
    dropped.emit(slot_index, data.get("patterns", []))

func _update_visual() -> void:
    if placeholder:
        placeholder.visible = not has_option() or _locked
        placeholder.text = "Consumed by placeholder wave" if _locked else _get_empty_slot_text()
        placeholder.modulate = Color(0.8, 0.65, 0.6, 1.0) if _locked else Color(1.0, 1.0, 1.0, 1.0)
    if content:
        for ch in content.get_children():
            ch.queue_free()
        if has_option() and not _locked:
            var card := WaveCardScene.instantiate()
            content.add_child(card)
            card.setup(option_patterns)
            card.set_interactive(false)
    _update_tier_summary()
    modulate = Color(0.65, 0.65, 0.65, 1.0) if _locked else Color(1.0, 1.0, 1.0, 1.0)


func _update_tier_summary() -> void:
    if tier_summary == null:
        return

    tier_summary.visible = not _locked
    var counts := _count_tiers(option_patterns)
    var hard_count := int(counts.get("hard", 0))
    var mid_count := int(counts.get("mid", 0))
    var easy_count := int(counts.get("easy", 0))

    if hard_chip:
        hard_chip.text = "HARD x%d" % hard_count
        hard_chip.modulate = Color(1.0, 0.5, 0.35, 1.0) if hard_count > 0 else Color(0.62, 0.62, 0.62, 1.0)
    if mid_chip:
        mid_chip.text = "MID x%d" % mid_count
        mid_chip.modulate = Color(0.98, 0.86, 0.42, 1.0) if mid_count > 0 else Color(0.62, 0.62, 0.62, 1.0)
    if easy_chip:
        easy_chip.text = "EASY x%d" % easy_count
        easy_chip.modulate = Color(0.55, 0.86, 0.62, 1.0) if easy_count > 0 else Color(0.62, 0.62, 0.62, 1.0)


func _count_tiers(patterns: Array) -> Dictionary:
    var hard_count := 0
    var mid_count := 0
    var easy_count := 0

    if patterns != null:
        for p in patterns:
            var pp := p as ProphecyPattern
            if pp == null:
                continue
            match int(pp.difficulty_tier):
                ProphecyPattern.DifficultyTier.HARD:
                    hard_count += 1
                ProphecyPattern.DifficultyTier.MID:
                    mid_count += 1
                ProphecyPattern.DifficultyTier.EASY:
                    easy_count += 1

    return {
        "hard": hard_count,
        "mid": mid_count,
        "easy": easy_count,
    }


func _get_empty_slot_text() -> String:
    match slot_index:
        0:
            return "Pick EASY pattern"
        1:
            return "Optional MID pattern"
        2:
            return "Optional HARD pattern"
        _:
            return "Pick pattern"
