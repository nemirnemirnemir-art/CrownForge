extends Control

const UnitFaceLibraryScript := preload("res://scripts/utils/UnitFaceLibrary.gd")

enum ClassTokenPhysicsMode {
    TAUT_ROPE,
    ELASTIC_ROPE,
}

@export_enum("Taut Rope", "Elastic Rope") var class_token_physics_mode: int = ClassTokenPhysicsMode.TAUT_ROPE
@export_range(200.0, 4000.0, 10.0) var class_token_gravity: float = 1800.0
@export_range(0.0, 30.0, 0.1) var class_token_linear_damping: float = 4.5
@export_range(0.0, 40.0, 0.1) var class_token_rotation_lerp_speed: float = 14.0
@export_range(0.0, 1.0, 0.01) var class_token_rotation_influence: float = 0.9
@export_range(0.1, 4.0, 0.05) var class_token_release_velocity_multiplier: float = 1.0
@export_range(0.0, 1.0, 0.01) var class_token_drag_velocity_smoothing: float = 0.35
@export_range(0.0, 200.0, 0.5) var class_token_spring_strength: float = 45.0
@export_range(0.0, 40.0, 0.1) var class_token_spring_damping: float = 8.0
@export_range(0.0, 2.0, 0.01) var class_token_max_stretch_ratio: float = 2.0
@export_range(0.0, 5000.0, 10.0) var class_token_release_spring_boost: float = 2600.0
@export_range(0.1, 20.0, 0.1) var class_token_rope_visual_width: float = 6.0
@export_range(0.05, 1.0, 0.01) var class_token_rope_min_width_ratio: float = 0.22
@export_range(0.0, 1000.0, 5.0) var class_token_idle_sway_strength: float = 140.0
@export_range(0.05, 2.0, 0.01) var class_token_idle_sway_frequency: float = 0.2
@export_range(200.0, 4000.0, 10.0) var name_sign_gravity: float = 1400.0
@export_range(0.0, 30.0, 0.1) var name_sign_linear_damping: float = 5.0
@export_range(0.0, 40.0, 0.1) var name_sign_rotation_lerp_speed: float = 12.0
@export_range(0.0, 1.0, 0.01) var name_sign_rotation_influence: float = 0.72
@export_range(0.1, 4.0, 0.05) var name_sign_release_velocity_multiplier: float = 1.0
@export_range(0.0, 1.0, 0.01) var name_sign_drag_velocity_smoothing: float = 0.35
@export_range(0.0, 200.0, 0.5) var name_sign_spring_strength: float = 40.0
@export_range(0.0, 40.0, 0.1) var name_sign_spring_damping: float = 8.0
@export_range(0.0, 2.0, 0.01) var name_sign_max_stretch_ratio: float = 1.35
@export_range(0.0, 5000.0, 10.0) var name_sign_release_spring_boost: float = 1700.0
@export_range(0.1, 20.0, 0.1) var name_sign_rope_visual_width: float = 7.0
@export_range(0.05, 1.0, 0.01) var name_sign_rope_min_width_ratio: float = 0.45
@export_range(0.0, 1000.0, 5.0) var name_sign_idle_sway_strength: float = 95.0
@export_range(0.05, 2.0, 0.01) var name_sign_idle_sway_frequency: float = 0.16
@export_range(2.0, 12.0, 0.5) var input_focus_caret_width: float = 4.0
@export_range(0.3, 2.0, 0.05) var input_focus_caret_pulse_interval: float = 1.0
@export_range(0.05, 0.95, 0.05) var input_focus_caret_min_alpha: float = 0.2

const STAT_MIN := 1
const STAT_MAX := 12
const STAT_DEFAULT := 6
const FREE_POINTS_DEFAULT := 6
const AGE_MIN := 16
const AGE_MAX := 60
const AGE_TEXT_MAX_LENGTH := 2
const NAME_MAX_LENGTH := 16
const ROPE_TEXTURE_PATH := "res://assets/Characher_Creation/rope/rope400_30.png"
const ROPE_HOLDER_TEXTURE_PATH := "res://assets/Characher_Creation/rope/rope_holder.png"
const NAME_SIGN_TEXTURE_PATH := "res://assets/Characher_Creation/name_sign.png"
const DESCRIPTION_PANEL_TEXTURE := preload("res://assets/Characher_Creation/Description/description_panel.png")
const SPELL_CANCEL_TEXTURE_PATH := "res://assets/Characher_Creation/spells/cancel.png"
const RESOURCE_WOOD_TEXTURE_PATH := "res://assets/items/resources/wood_1.png"
const RESOURCE_WINE_TEXTURE_PATH := "res://assets/items/resources/wine.png"
const RESOURCE_MEAT_TEXTURE_PATH := "res://assets/items/resources/meat_9.png"
const REWARD_ESTABLISHED_PRODUCTION_TEXTURE_PATH := "res://assets/ui/possible_rewards/Established Production.png"
const REWARD_LEGENDARY_ARTIFACT_TEXTURE_PATH := "res://assets/ui/possible_rewards/Legendary Artifact.png"
const REWARD_SPELL_TEXTURE_PATH := "res://assets/ui/possible_rewards/Spell.png"
const SPELL_FOCUS_TEXTURE := preload("res://assets/ui/icons/gaze.png")
const SPELL_CONFIRM_TEXTURE := preload("res://assets/Characher_Creation/spells/checkmark.png")
const SPELL_CANCEL_TEXTURE := preload("res://assets/Characher_Creation/spells/cancel.png")
const SPELL_WATER_TEXTURE := preload("res://assets/items/resources/water_-1.png")
const SPELL_GOLD_TEXTURE := preload("res://assets/items/resources/gold_4.png")
const SPELL_WINE_TEXTURE := preload("res://assets/items/resources/wine.png")
const SPELL_MEAT_TEXTURE := preload("res://assets/items/resources/meat_9.png")
const STAT_IDS := ["power", "speed", "thinking", "lucky", "heath", "charisma", "crown"]
const STAT_DISPLAY_NAMES := {
    "power": "Power",
    "speed": "Speed",
    "thinking": "Thinking",
    "lucky": "Lucky",
    "heath": "Health",
    "charisma": "Charisma",
    "crown": "Crown",
}
const SPELL_ICON_SIZE := Vector2(100.0, 100.0)
const DESCRIPTION_INLINE_ICON_SIZE := 22
const SPELL_DROPDOWN_OFFSET := Vector2(132.0, -33.0)
const ACTIVE_GLOBAL_SPELL_IDS := ["forced_tax", "fast_production", "frenzy", "boys_at_work", "training"]
const ACTIVE_CLASS_SPELL_IDS := {
    "chivalry": ["tough_guys"],
    "necromancy": ["resurrection"],
    "demonology": ["pocket_demons"],
}
const PASSIVE_SPELL_IDS := ["lumberjack", "reward", "good_reward", "last_chance", "spells_for_work", "spicy_boys"]
const SPELL_DEFS := {
    "tough_guys": {
        "category": "active",
        "display_name": "Tough Guys",
        "texture": preload("res://assets/Characher_Creation/spells/tough_guys.png"),
        "resource": "water",
        "cost": 30,
        "cooldown": 100,
        "description": "Summons 3 Peasants (+1 per upgrade).",
        "description_segments": [
            {"text": "Summons "},
            {"unit_face_id": "peasant"},
            {"text": " 3 Peasants (+1 per upgrade)."},
        ],
    },
    "resurrection": {
        "category": "active",
        "display_name": "Resurrection",
        "texture": preload("res://assets/Characher_Creation/spells/resurrection.png"),
        "resource": "water",
        "cost": 25,
        "cooldown": 120,
        "description": "Resurrect up to 2 dead bodies in an area to fight for you (+1 body per upgrade).",
    },
    "pocket_demons": {
        "category": "active",
        "display_name": "Pocket Demons",
        "texture": preload("res://assets/Characher_Creation/spells/pocket_demons.png"),
        "resource": "water",
        "cost": 100,
        "cooldown": 150,
        "description": "Summon 1 Familiar (+25% all base stats per upgrade). Base Familiar stats: 120 HP, 20 DPS.",
    },
    "fast_production": {
        "category": "active",
        "display_name": "Fast Production",
        "texture": preload("res://assets/Characher_Creation/spells/fast_production.png"),
        "resource": "gold",
        "cost": 20,
        "cooldown": 240,
        "description": "Increases all building production by 32% for 25 seconds (+8% per upgrade).",
    },
    "forced_tax": {
        "category": "active",
        "display_name": "Forced Tax",
        "texture": preload("res://assets/Characher_Creation/spells/forced_tax.png"),
        "resource": "gold",
        "cost": 35,
        "cooldown": 240,
        "description": "Gain 100 resources of your choice (-10 sec cooldown per upgrade).",
    },
    "frenzy": {
        "category": "active",
        "display_name": "Frenzy",
        "texture": preload("res://assets/Characher_Creation/spells/Frenzy.png"),
        "resource": "wine",
        "cost": 10,
        "cooldown": 200,
        "description": "Gives Wrath to all player units for 6 seconds.",
        "description_segments": [
            {"text": "Gives "},
            {"icon_path": REWARD_SPELL_TEXTURE_PATH},
            {"text": " Wrath to all player units for 6 seconds."},
        ],
    },
    "boys_at_work": {
        "category": "active",
        "display_name": "Boys at Work",
        "texture": preload("res://assets/Characher_Creation/spells/Boys at Work.png"),
        "resource": "gold",
        "cost": 20,
        "cooldown": 200,
        "description": "All buildings work for 15 seconds regardless of their current gaze position.",
    },
    "training": {
        "category": "active",
        "display_name": "Training",
        "texture": preload("res://assets/Characher_Creation/spells/Traning.png"),
        "resource": "meat",
        "cost": 10,
        "cooldown": 180,
        "description": "Adds 100 HP to each player unit on the battlefield.",
    },
    "lumberjack": {
        "category": "passive",
        "display_name": "Lumberjack",
        "texture": preload("res://assets/Characher_Creation/Passive_spells/Lumberjack.png"),
        "description": "After cutting 10 trees, can get 300 wood.",
        "description_segments": [
            {"text": "After cutting 10 trees, can get "},
            {"icon_path": RESOURCE_WOOD_TEXTURE_PATH},
            {"text": " 300 wood."},
        ],
    },
    "reward": {
        "category": "passive",
        "display_name": "Reward",
        "texture": preload("res://assets/Characher_Creation/Passive_spells/Reward.png"),
        "description": "After killing a Boss, can get an Established Production building blueprint.",
        "description_segments": [
            {"text": "After killing a "},
            {"icon_path": SPELL_CANCEL_TEXTURE_PATH},
            {"text": " Boss, can get an "},
            {"icon_path": REWARD_ESTABLISHED_PRODUCTION_TEXTURE_PATH},
            {"text": " Established Production building blueprint."},
        ],
    },
    "good_reward": {
        "category": "passive",
        "display_name": "Good Reward",
        "texture": preload("res://assets/Characher_Creation/Passive_spells/Good Reward.png"),
        "description": "After killing 2 Bosses, can get a Legendary Artifact.",
        "description_segments": [
            {"text": "After killing 2 "},
            {"icon_path": SPELL_CANCEL_TEXTURE_PATH},
            {"text": " Bosses, can get a "},
            {"icon_path": REWARD_LEGENDARY_ARTIFACT_TEXTURE_PATH},
            {"text": " Legendary Artifact."},
        ],
    },
    "last_chance": {
        "category": "passive",
        "display_name": "Last Chance",
        "texture": preload("res://assets/Characher_Creation/Passive_spells/last chance.png"),
        "description": "After castle HP drops below 30, can summon 10 Militia to help.",
        "description_segments": [
            {"text": "After castle HP drops below 30, can summon 10 "},
            {"icon_path": SPELL_CANCEL_TEXTURE_PATH},
            {"text": " Militia to help."},
        ],
    },
    "spells_for_work": {
        "category": "passive",
        "display_name": "Spells for Work",
        "texture": preload("res://assets/Characher_Creation/Passive_spells/Spells for work.png"),
        "description": "After killing a Boss, can get 3 choices of Spells.",
        "description_segments": [
            {"text": "After killing a "},
            {"icon_path": SPELL_CANCEL_TEXTURE_PATH},
            {"text": " Boss, can get 3 choices of "},
            {"icon_path": REWARD_SPELL_TEXTURE_PATH},
            {"text": " Spells."},
        ],
    },
    "spicy_boys": {
        "category": "passive",
        "display_name": "Spicy Boys",
        "texture": preload("res://assets/Characher_Creation/Passive_spells/Spicy boys.png"),
        "description": "With 70 morale, can summon 10 Bumblebees.",
        "description_segments": [
            {"text": "With 70 "},
            {"icon_path": SPELL_CANCEL_TEXTURE_PATH},
            {"text": " morale, can summon 10 "},
            {"icon_path": SPELL_CANCEL_TEXTURE_PATH},
            {"text": " Bumblebees."},
        ],
    },
}
const CLASS_DEFS := [
    {
        "id": "chivalry",
        "display_name": "Сhivalry",
        "texture": preload("res://assets/Characher_Creation/classes/Сhivalry.png"),
    },
    {
        "id": "necromancy",
        "display_name": "Necromancy",
        "texture": preload("res://assets/Characher_Creation/classes/Necromancy.png"),
    },
    {
        "id": "demonology",
        "display_name": "Demonology",
        "texture": preload("res://assets/Characher_Creation/classes/Demonology.png"),
    },
]

var free_points: int = FREE_POINTS_DEFAULT
var selected_class_index: int = 0
var selected_age: int = AGE_MIN
var player_name: String = ""
var stat_values: Dictionary = {}
var _rows_by_stat: Dictionary = {}
var _is_updating_age_text: bool = false
var _is_updating_name_text: bool = false
var _class_token_position: Vector2 = Vector2.ZERO
var _class_token_velocity: Vector2 = Vector2.ZERO
var _class_token_drag_velocity: Vector2 = Vector2.ZERO
var _class_token_rotation: float = 0.0
var _class_token_rope_length: float = 140.0
var _class_token_attach_position: Vector2 = Vector2.ZERO
var _class_token_drag_active: bool = false
var _class_token_drag_mouse_offset: Vector2 = Vector2.ZERO
var _class_token_tension_ratio: float = 0.0
var _class_token_idle_time: float = 0.0
var _name_sign_position: Vector2 = Vector2.ZERO
var _name_sign_velocity: Vector2 = Vector2.ZERO
var _name_sign_drag_velocity: Vector2 = Vector2.ZERO
var _name_sign_rotation: float = 0.0
var _name_sign_rope_length: float = 120.0
var _name_sign_attach_position: Vector2 = Vector2.ZERO
var _name_sign_drag_active: bool = false
var _name_sign_drag_mouse_offset: Vector2 = Vector2.ZERO
var _name_sign_tension_ratio: float = 0.0
var _name_sign_idle_time: float = 0.0
var _input_focus_caret_time: float = 0.0
var _runtime_ui_textures: Dictionary = {}
var _button_visual_state: Dictionary = {}
var _button_tweens: Dictionary = {}
var confirmed_active_spell_id: String = ""
var pending_active_spell_id: String = ""
var confirmed_passive_spell_id: String = ""
var pending_passive_spell_id: String = ""
var focused_stat_id: String = ""
var focused_spell_id: String = ""
var focused_spell_category: String = ""
var focused_entry_type: String = ""
var is_active_spell_dropdown_open: bool = false
var is_passive_spell_dropdown_open: bool = false
var _selection_focus_time: float = 0.0
var _stat_icon_controls: Dictionary = {}
var _active_spell_option_buttons: Array[TextureButton] = []
var _passive_spell_option_buttons: Array[TextureButton] = []

@onready var free_points_label: Label = $FreePointsPanel/FreePointsLabel
@onready var power_row: HBoxContainer = $StatsPanel/Margin/Rows/PowerRow
@onready var speed_row: HBoxContainer = $StatsPanel/Margin/Rows/SpeedRow
@onready var thinking_row: HBoxContainer = $StatsPanel/Margin/Rows/ThinkingRow
@onready var lucky_row: HBoxContainer = $StatsPanel/Margin/Rows/LuckyRow
@onready var heath_row: HBoxContainer = $StatsPanel/Margin/Rows/HeathRow
@onready var charisma_row: HBoxContainer = $StatsPanel/Margin/Rows/CharismaRow
@onready var crown_row: HBoxContainer = $StatsPanel/Margin/Rows/CrownRow
@onready var slider_left_button: TextureButton = $ClassPanel/SliderLeft
@onready var slider_right_button: TextureButton = $ClassPanel/SliderRight
@onready var token_rig: Node2D = $ClassPanel/TokenRig
@onready var rope_anchor: Marker2D = $ClassPanel/TokenRig/RopeAnchor
@onready var token_spawn_point: Marker2D = $ClassPanel/TokenRig/TokenSpawnPoint
@onready var token_rest_point: Marker2D = $ClassPanel/TokenRig/TokenRestPoint
@onready var rope_line: Line2D = $ClassPanel/TokenRig/RopeLine
@onready var class_rope_sprite: Sprite2D = get_node_or_null("ClassPanel/TokenRig/RopeSprite") as Sprite2D
@onready var class_rope_top_holder: Sprite2D = get_node_or_null("ClassPanel/TokenRig/RopeTopHolder") as Sprite2D
@onready var class_rope_bottom_holder: Sprite2D = get_node_or_null("ClassPanel/TokenRig/RopeBottomHolder") as Sprite2D
@onready var token_root: Node2D = $ClassPanel/TokenRig/TokenRoot
@onready var token_sprite: Sprite2D = $ClassPanel/TokenRig/TokenRoot/TokenSprite
@onready var token_attach_point: Marker2D = $ClassPanel/TokenRig/TokenRoot/TokenAttachPoint
@onready var class_name_label: Label = $ClassPanel/ClassNamePanel/ClassNameLabel
@onready var age_input: LineEdit = $AgePanel/AgeInput
@onready var name_input: LineEdit = $NamePanel/NameInput
@onready var age_focus_caret: ColorRect = get_node_or_null("AgePanel/AgeFocusCaret") as ColorRect
@onready var name_focus_caret: ColorRect = get_node_or_null("NamePanel/NameFocusCaret") as ColorRect
@onready var name_sign_rig: Node2D = get_node_or_null("NamePanel/NameSignRig") as Node2D
@onready var name_sign_left_anchor: Marker2D = get_node_or_null("NamePanel/NameSignRig/LeftAnchor") as Marker2D
@onready var name_sign_right_anchor: Marker2D = get_node_or_null("NamePanel/NameSignRig/RightAnchor") as Marker2D
@onready var name_sign_spawn_point: Marker2D = get_node_or_null("NamePanel/NameSignRig/SignSpawnPoint") as Marker2D
@onready var name_sign_rest_point: Marker2D = get_node_or_null("NamePanel/NameSignRig/SignRestPoint") as Marker2D
@onready var name_sign_left_rope: Sprite2D = get_node_or_null("NamePanel/NameSignRig/LeftRope") as Sprite2D
@onready var name_sign_right_rope: Sprite2D = get_node_or_null("NamePanel/NameSignRig/RightRope") as Sprite2D
@onready var name_sign_left_top_holder: Sprite2D = get_node_or_null("NamePanel/NameSignRig/LeftTopHolder") as Sprite2D
@onready var name_sign_right_top_holder: Sprite2D = get_node_or_null("NamePanel/NameSignRig/RightTopHolder") as Sprite2D
@onready var name_sign_left_bottom_holder: Sprite2D = get_node_or_null("NamePanel/NameSignRig/LeftBottomHolder") as Sprite2D
@onready var name_sign_right_bottom_holder: Sprite2D = get_node_or_null("NamePanel/NameSignRig/RightBottomHolder") as Sprite2D
@onready var name_sign_root: Node2D = get_node_or_null("NamePanel/NameSignRig/SignRoot") as Node2D
@onready var name_sign_sprite: Sprite2D = get_node_or_null("NamePanel/NameSignRig/SignRoot/SignSprite") as Sprite2D
@onready var name_sign_label: Label = get_node_or_null("NamePanel/NameSignRig/SignRoot/SignLabel") as Label
@onready var name_sign_left_attach_point: Marker2D = get_node_or_null("NamePanel/NameSignRig/SignRoot/LeftAttachPoint") as Marker2D
@onready var name_sign_right_attach_point: Marker2D = get_node_or_null("NamePanel/NameSignRig/SignRoot/RightAttachPoint") as Marker2D
@onready var active_selected_spell_button: TextureButton = get_node_or_null("SpellPanel/SelectedSpellButton") as TextureButton
@onready var active_spell_dropdown_panel: Control = get_node_or_null("SpellPanel/DropdownPanel") as Control
@onready var active_spell_options_grid: GridContainer = get_node_or_null("SpellPanel/DropdownPanel/Margin/VBox/OptionsGrid") as GridContainer
@onready var active_spell_confirm_button: TextureButton = get_node_or_null("SpellPanel/DropdownPanel/Margin/VBox/ActionRow/ConfirmButton") as TextureButton
@onready var active_spell_cancel_button: TextureButton = get_node_or_null("SpellPanel/DropdownPanel/Margin/VBox/ActionRow/CancelButton") as TextureButton
@onready var passive_selected_spell_button: TextureButton = get_node_or_null("PassiveSpellPanel/SelectedSpellButton") as TextureButton
@onready var passive_spell_dropdown_panel: Control = get_node_or_null("PassiveSpellPanel/DropdownPanel") as Control
@onready var passive_spell_options_grid: GridContainer = get_node_or_null("PassiveSpellPanel/DropdownPanel/Margin/VBox/OptionsGrid") as GridContainer
@onready var passive_spell_confirm_button: TextureButton = get_node_or_null("PassiveSpellPanel/DropdownPanel/Margin/VBox/ActionRow/ConfirmButton") as TextureButton
@onready var passive_spell_cancel_button: TextureButton = get_node_or_null("PassiveSpellPanel/DropdownPanel/Margin/VBox/ActionRow/CancelButton") as TextureButton
@onready var description_panel_background: TextureRect = get_node_or_null("DescriptionPanel/Background") as TextureRect
@onready var description_title_label: Label = get_node_or_null("DescriptionPanel/Margin/VBox/TitleLabel") as Label
@onready var description_body_label: RichTextLabel = get_node_or_null("DescriptionPanel/Margin/VBox/BodyLabel") as RichTextLabel
@onready var description_cost_icon: TextureRect = get_node_or_null("DescriptionPanel/Margin/VBox/MetaRow/CostInfo/CostIcon") as TextureRect
@onready var description_cost_label: Label = get_node_or_null("DescriptionPanel/Margin/VBox/MetaRow/CostInfo/CostLabel") as Label
@onready var description_cooldown_icon: Label = get_node_or_null("DescriptionPanel/Margin/VBox/MetaRow/CooldownInfo/CooldownIcon") as Label
@onready var description_cooldown_label: Label = get_node_or_null("DescriptionPanel/Margin/VBox/MetaRow/CooldownInfo/CooldownLabel") as Label
@onready var next_button: Button = get_node_or_null("NextButton") as Button
@onready var selection_focus: TextureRect = get_node_or_null("SelectionFocus") as TextureRect

func _ready() -> void:
    _rows_by_stat = {
        "power": _build_row_refs(power_row),
        "speed": _build_row_refs(speed_row),
        "thinking": _build_row_refs(thinking_row),
        "lucky": _build_row_refs(lucky_row),
        "heath": _build_row_refs(heath_row),
        "charisma": _build_row_refs(charisma_row),
        "crown": _build_row_refs(crown_row),
    }
    _connect_stat_buttons()
    _connect_meta_controls()
    _setup_runtime_hanging_textures()
    _setup_line_edit_visuals()
    _setup_button_feedback()
    _setup_spell_ui()
    _initialize_stats()
    _initialize_meta_state()
    _initialize_spell_state()
    _initialize_class_token_state()
    _initialize_name_sign_state()
    _refresh_ui()
    _refresh_meta_ui()
    _reset_class_token_state()
    _reset_name_sign_state()
    if next_button:
        next_button.text = "Continue"

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        if mouse_event.button_index != MOUSE_BUTTON_LEFT:
            return
        if mouse_event.pressed:
            _release_text_focus_if_clicked_outside()
            _close_spell_dropdown_if_clicked_outside(mouse_event.position)
            if _is_mouse_over_class_token():
                _begin_class_token_drag()
                get_viewport().set_input_as_handled()
            elif _is_mouse_over_name_sign():
                _begin_name_sign_drag()
                get_viewport().set_input_as_handled()
        elif _class_token_drag_active:
            _end_class_token_drag()
            get_viewport().set_input_as_handled()
        elif _name_sign_drag_active:
            _end_name_sign_drag()
            get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
    _update_class_token(delta)
    _update_name_sign(delta)
    _update_focus_carets(delta)
    _update_selection_focus(delta)

func _build_row_refs(row: HBoxContainer) -> Dictionary:
    return {
        "icon": row.get_node("Icon") as TextureRect,
        "minus_button": row.get_node("MinusButton") as TextureButton,
        "value_label": row.get_node("ValueHolder/ValueLabel") as Label,
        "plus_button": row.get_node("PlusButton") as TextureButton,
    }

func _connect_stat_buttons() -> void:
    for stat_id in STAT_IDS:
        var row_data: Dictionary = _rows_by_stat.get(stat_id, {})
        var minus_button := row_data.get("minus_button") as TextureButton
        var plus_button := row_data.get("plus_button") as TextureButton
        var minus_callable := Callable(self, "_on_minus_pressed").bind(stat_id)
        var plus_callable := Callable(self, "_on_plus_pressed").bind(stat_id)
        if minus_button and not minus_button.pressed.is_connected(minus_callable):
            minus_button.pressed.connect(minus_callable)
        if plus_button and not plus_button.pressed.is_connected(plus_callable):
            plus_button.pressed.connect(plus_callable)

func _connect_meta_controls() -> void:
    var slider_left_callable := Callable(self, "_on_slider_left_pressed")
    var slider_right_callable := Callable(self, "_on_slider_right_pressed")
    if slider_left_button and not slider_left_button.pressed.is_connected(slider_left_callable):
        slider_left_button.pressed.connect(slider_left_callable)
    if slider_right_button and not slider_right_button.pressed.is_connected(slider_right_callable):
        slider_right_button.pressed.connect(slider_right_callable)
    if age_input:
        age_input.max_length = AGE_TEXT_MAX_LENGTH
        var age_text_changed_callable := Callable(self, "_on_age_text_changed")
        var age_text_submitted_callable := Callable(self, "_on_age_text_submitted")
        var age_focus_exited_callable := Callable(self, "_on_age_focus_exited")
        if not age_input.text_changed.is_connected(age_text_changed_callable):
            age_input.text_changed.connect(age_text_changed_callable)
        if not age_input.text_submitted.is_connected(age_text_submitted_callable):
            age_input.text_submitted.connect(age_text_submitted_callable)
        if not age_input.focus_exited.is_connected(age_focus_exited_callable):
            age_input.focus_exited.connect(age_focus_exited_callable)
    if name_input:
        name_input.max_length = NAME_MAX_LENGTH
        var name_text_changed_callable := Callable(self, "_on_name_text_changed")
        if not name_input.text_changed.is_connected(name_text_changed_callable):
            name_input.text_changed.connect(name_text_changed_callable)
    if next_button:
        var next_pressed_callable := Callable(self, "_on_next_pressed")
        if not next_button.pressed.is_connected(next_pressed_callable):
            next_button.pressed.connect(next_pressed_callable)

func _on_next_pressed() -> void:
    _store_character_creation_state()
    if KingSpellState != null:
        KingSpellState.begin_run_from_character_creation()
    if GameStartSettings != null:
        GameStartSettings.go_to_game_scene(get_tree())
        return
    var tree := get_tree()
    if tree:
        tree.change_scene_to_file("res://scenes/game/GameScene.tscn")

func _store_character_creation_state() -> void:
    if CharacterCreationState == null:
        return
    CharacterCreationState.apply_selection(
        _get_current_class_id(),
        confirmed_active_spell_id,
        confirmed_passive_spell_id,
        selected_age,
        player_name
    )

func _on_slider_left_pressed() -> void:
    _shift_class_selection(-1)

func _on_slider_right_pressed() -> void:
    _shift_class_selection(1)

func _shift_class_selection(direction: int) -> void:
    var class_count := CLASS_DEFS.size()
    if class_count == 0:
        return
    selected_class_index = (selected_class_index + direction) % class_count
    if selected_class_index < 0:
        selected_class_index += class_count
    _refresh_meta_ui()
    _reset_class_token_state()

func _setup_runtime_hanging_textures() -> void:
    var rope_texture := _load_runtime_texture(ROPE_TEXTURE_PATH)
    var rope_holder_texture := _load_runtime_texture(ROPE_HOLDER_TEXTURE_PATH)
    var name_sign_texture := _load_runtime_texture(NAME_SIGN_TEXTURE_PATH)
    if class_rope_sprite:
        class_rope_sprite.texture = rope_texture
    if class_rope_top_holder:
        class_rope_top_holder.texture = rope_holder_texture
    if class_rope_bottom_holder:
        class_rope_bottom_holder.texture = rope_holder_texture
    if name_sign_left_rope:
        name_sign_left_rope.texture = rope_texture
    if name_sign_right_rope:
        name_sign_right_rope.texture = rope_texture
    if name_sign_left_top_holder:
        name_sign_left_top_holder.texture = rope_holder_texture
    if name_sign_right_top_holder:
        name_sign_right_top_holder.texture = rope_holder_texture
    if name_sign_left_bottom_holder:
        name_sign_left_bottom_holder.texture = rope_holder_texture
    if name_sign_right_bottom_holder:
        name_sign_right_bottom_holder.texture = rope_holder_texture
    if name_sign_sprite:
        name_sign_sprite.texture = name_sign_texture

func _load_runtime_texture(resource_path: String) -> Texture2D:
    if _runtime_ui_textures.has(resource_path):
        return _runtime_ui_textures[resource_path] as Texture2D
    var absolute_path := ProjectSettings.globalize_path(resource_path)
    var image := Image.load_from_file(absolute_path)
    if image == null or image.is_empty():
        return null
    var texture := ImageTexture.create_from_image(image)
    _runtime_ui_textures[resource_path] = texture
    return texture

func _setup_line_edit_visuals() -> void:
    var inputs: Array[LineEdit] = [age_input, name_input]
    for line_edit in inputs:
        if line_edit == null:
            continue
        var empty_style := StyleBoxEmpty.new()
        line_edit.flat = true
        line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
        line_edit.add_theme_stylebox_override("normal", empty_style)
        line_edit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        line_edit.add_theme_stylebox_override("read_only", StyleBoxEmpty.new())
        line_edit.add_theme_color_override("caret_color", Color(0.0, 0.0, 0.0, 0.0))
    if name_input:
        _apply_name_input_theme()

func _apply_name_input_theme() -> void:
    if name_input == null:
        return
    name_input.placeholder_text = "Name"
    name_input.add_theme_color_override("font_color", Color(0.14, 0.08, 0.02, 1.0))
    name_input.add_theme_color_override("font_selected_color", Color(0.14, 0.08, 0.02, 1.0))
    name_input.add_theme_color_override("selection_color", Color(1.0, 0.92, 0.72, 0.55))
    name_input.add_theme_color_override("font_uneditable_color", Color(0.35, 0.22, 0.08, 0.65))
    name_input.add_theme_color_override("caret_color", Color(0.14, 0.08, 0.02, 1.0))

func _setup_button_feedback() -> void:
    _configure_slider_button_feedback(slider_left_button, -10.0)
    _configure_slider_button_feedback(slider_right_button, 10.0)
    for stat_id in STAT_IDS:
        var row_data: Dictionary = _rows_by_stat.get(stat_id, {})
        _configure_stat_button_feedback(row_data.get("minus_button") as TextureButton)
        _configure_stat_button_feedback(row_data.get("plus_button") as TextureButton)

func _setup_spell_ui() -> void:
    _setup_stat_focus_targets()
    if description_panel_background:
        description_panel_background.texture = DESCRIPTION_PANEL_TEXTURE
    if description_body_label:
        description_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        description_body_label.scroll_active = false
        description_body_label.fit_content = true
    if description_cost_icon:
        description_cost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        description_cost_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    if selection_focus:
        selection_focus.texture = SPELL_FOCUS_TEXTURE
        selection_focus.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        selection_focus.stretch_mode = TextureRect.STRETCH_SCALE
        selection_focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
        selection_focus.z_as_relative = false
        selection_focus.z_index = 600
    _configure_spell_dropdown_panel(active_spell_dropdown_panel)
    _configure_spell_dropdown_panel(passive_spell_dropdown_panel)
    _active_spell_option_buttons = _collect_spell_option_buttons(active_spell_options_grid, "SpellOption")
    _passive_spell_option_buttons = _collect_spell_option_buttons(passive_spell_options_grid, "PassiveOption")
    _setup_spell_panel_controls("active", active_selected_spell_button, _active_spell_option_buttons, active_spell_confirm_button, active_spell_cancel_button)
    _setup_spell_panel_controls("passive", passive_selected_spell_button, _passive_spell_option_buttons, passive_spell_confirm_button, passive_spell_cancel_button)

func _configure_spell_dropdown_panel(dropdown_panel: Control) -> void:
    if dropdown_panel == null:
        return
    dropdown_panel.top_level = true
    dropdown_panel.z_as_relative = false
    dropdown_panel.z_index = 500
    dropdown_panel.mouse_filter = Control.MOUSE_FILTER_STOP

func _collect_spell_option_buttons(grid: GridContainer, option_name_prefix: String) -> Array[TextureButton]:
    var buttons: Array[TextureButton] = []
    if grid == null:
        return buttons
    for index in range(1, 7):
        var button := grid.get_node_or_null("%s%d" % [option_name_prefix, index]) as TextureButton
        if button:
            buttons.append(button)
    return buttons

func _setup_spell_panel_controls(spell_category: String, selected_button: TextureButton, option_buttons: Array[TextureButton], confirm_button: TextureButton, cancel_button: TextureButton) -> void:
    _configure_spell_texture_button(selected_button)
    for button in option_buttons:
        _configure_spell_texture_button(button)
    _configure_spell_icon_button(confirm_button, SPELL_CONFIRM_TEXTURE)
    _configure_spell_icon_button(cancel_button, SPELL_CANCEL_TEXTURE)

    if selected_button:
        var selected_callable := Callable(self, "_on_selected_spell_pressed").bind(spell_category)
        if not selected_button.pressed.is_connected(selected_callable):
            selected_button.pressed.connect(selected_callable)

    for button in option_buttons:
        if button == null:
            continue
        var option_callable := Callable(self, "_on_spell_option_pressed").bind(button, spell_category)
        if not button.pressed.is_connected(option_callable):
            button.pressed.connect(option_callable)

    if confirm_button:
        var confirm_callable := Callable(self, "_on_spell_confirm_pressed").bind(spell_category)
        if not confirm_button.pressed.is_connected(confirm_callable):
            confirm_button.pressed.connect(confirm_callable)
    if cancel_button:
        var cancel_callable := Callable(self, "_on_spell_cancel_pressed").bind(spell_category)
        if not cancel_button.pressed.is_connected(cancel_callable):
            cancel_button.pressed.connect(cancel_callable)

func _setup_stat_focus_targets() -> void:
    _stat_icon_controls.clear()
    for stat_id in STAT_IDS:
        var row_data: Dictionary = _rows_by_stat.get(stat_id, {})
        var icon_rect := row_data.get("icon") as TextureRect
        if icon_rect == null:
            continue
        icon_rect.mouse_filter = Control.MOUSE_FILTER_STOP
        icon_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        var icon_callable := Callable(self, "_on_stat_icon_gui_input").bind(stat_id)
        if not icon_rect.gui_input.is_connected(icon_callable):
            icon_rect.gui_input.connect(icon_callable)
        _stat_icon_controls[stat_id] = icon_rect

func _configure_spell_texture_button(button: TextureButton) -> void:
    if button == null:
        return
    button.ignore_texture_size = true
    button.custom_minimum_size = SPELL_ICON_SIZE
    button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    button.focus_mode = Control.FOCUS_NONE

func _configure_spell_icon_button(button: TextureButton, texture_value: Texture2D) -> void:
    if button == null:
        return
    button.texture_normal = texture_value
    button.texture_pressed = texture_value
    button.texture_hover = texture_value
    button.texture_disabled = texture_value
    button.ignore_texture_size = true
    button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    button.focus_mode = Control.FOCUS_NONE

func _initialize_spell_state() -> void:
    is_active_spell_dropdown_open = false
    is_passive_spell_dropdown_open = false
    _ensure_spell_selection_valid(true)

func _get_current_class_id() -> String:
    if selected_class_index < 0 or selected_class_index >= CLASS_DEFS.size():
        return ""
    return String(CLASS_DEFS[selected_class_index].get("id", ""))

func _get_available_spell_ids(spell_category: String) -> Array[String]:
    var available: Array[String] = []
    if spell_category == "active":
        var class_id := _get_current_class_id()
        var class_spell_ids: Array = ACTIVE_CLASS_SPELL_IDS.get(class_id, [])
        for spell_id_variant in class_spell_ids:
            var class_spell_id := String(spell_id_variant)
            if SPELL_DEFS.has(class_spell_id):
                available.append(class_spell_id)
        for spell_id_variant in ACTIVE_GLOBAL_SPELL_IDS:
            var active_spell_id := String(spell_id_variant)
            if SPELL_DEFS.has(active_spell_id):
                available.append(active_spell_id)
        return available
    for spell_id_variant in PASSIVE_SPELL_IDS:
        var passive_spell_id := String(spell_id_variant)
        if SPELL_DEFS.has(passive_spell_id):
            available.append(passive_spell_id)
    return available

func _ensure_spell_selection_valid(force_reset: bool = false) -> void:
    var active_available := _get_available_spell_ids("active")
    if active_available.is_empty():
        confirmed_active_spell_id = ""
        pending_active_spell_id = ""
    else:
        if force_reset or not active_available.has(confirmed_active_spell_id):
            confirmed_active_spell_id = active_available[0]
        if force_reset or not active_available.has(pending_active_spell_id):
            pending_active_spell_id = confirmed_active_spell_id

    var passive_available := _get_available_spell_ids("passive")
    if passive_available.is_empty():
        confirmed_passive_spell_id = ""
        pending_passive_spell_id = ""
    else:
        if force_reset or not passive_available.has(confirmed_passive_spell_id):
            confirmed_passive_spell_id = passive_available[0]
        if force_reset or not passive_available.has(pending_passive_spell_id):
            pending_passive_spell_id = confirmed_passive_spell_id

    var has_valid_focus := false
    if focused_entry_type == "active_spell":
        has_valid_focus = active_available.has(focused_spell_id)
    elif focused_entry_type == "passive_spell":
        has_valid_focus = passive_available.has(focused_spell_id)
    elif focused_entry_type == "stat":
        has_valid_focus = focused_stat_id != ""

    if not has_valid_focus:
        if confirmed_active_spell_id != "":
            _focus_spell("active", confirmed_active_spell_id)
        elif confirmed_passive_spell_id != "":
            _focus_spell("passive", confirmed_passive_spell_id)
        else:
            focused_entry_type = ""
            focused_spell_id = ""
            focused_spell_category = ""
            focused_stat_id = ""

func _refresh_spell_ui() -> void:
    _refresh_spell_panel_ui("active")
    _refresh_spell_panel_ui("passive")

func _refresh_spell_panel_ui(spell_category: String) -> void:
    var confirmed_spell_id := _get_confirmed_spell_id(spell_category)
    var pending_spell_id := _get_pending_spell_id(spell_category)
    var display_spell_id := confirmed_spell_id
    if _is_spell_dropdown_open(spell_category) and pending_spell_id != "":
        display_spell_id = pending_spell_id
    _apply_spell_texture(_get_selected_spell_button(spell_category), display_spell_id)

    var dropdown_panel := _get_spell_dropdown_panel(spell_category)
    if dropdown_panel:
        _sync_spell_dropdown_panel_position(spell_category)
        dropdown_panel.visible = _is_spell_dropdown_open(spell_category)
        if dropdown_panel.visible:
            dropdown_panel.move_to_front()

    var available := _get_available_spell_ids(spell_category)
    var spell_buttons := _get_spell_buttons(spell_category)
    for index in range(spell_buttons.size()):
        var button := spell_buttons[index]
        if button == null:
            continue
        if index < available.size():
            var spell_id := available[index]
            button.visible = true
            button.set_meta("spell_id", spell_id)
            _apply_spell_texture(button, spell_id)
        else:
            button.visible = false
            button.set_meta("spell_id", "")

    var has_pending_change := pending_spell_id != "" and pending_spell_id != confirmed_spell_id
    var confirm_button := _get_spell_confirm_button(spell_category)
    if confirm_button:
        confirm_button.visible = _is_spell_dropdown_open(spell_category) and has_pending_change
    var cancel_button := _get_spell_cancel_button(spell_category)
    if cancel_button:
        cancel_button.visible = _is_spell_dropdown_open(spell_category) and has_pending_change

func _apply_spell_texture(button: TextureButton, spell_id: String) -> void:
    if button == null:
        return
    var spell_def: Dictionary = SPELL_DEFS.get(spell_id, {})
    var spell_texture := spell_def.get("texture") as Texture2D
    button.texture_normal = spell_texture
    button.texture_pressed = spell_texture
    button.texture_hover = spell_texture
    button.texture_disabled = spell_texture

func _focus_stat(stat_id: String) -> void:
    focused_entry_type = "stat"
    focused_stat_id = stat_id
    focused_spell_id = ""
    focused_spell_category = ""
    _refresh_description_panel()

func _focus_spell(spell_category: String, spell_id: String) -> void:
    focused_entry_type = "%s_spell" % spell_category
    focused_spell_id = spell_id
    focused_spell_category = spell_category
    focused_stat_id = ""
    _refresh_description_panel()

func _on_stat_icon_gui_input(event: InputEvent, stat_id: String) -> void:
    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
            if is_active_spell_dropdown_open or is_passive_spell_dropdown_open:
                _close_all_spell_dropdowns(true)
                _refresh_spell_ui()
            _focus_stat(stat_id)
            get_viewport().set_input_as_handled()

func _on_selected_spell_pressed(spell_category: String) -> void:
    if _is_spell_dropdown_open(spell_category):
        _set_pending_spell_id(spell_category, _get_confirmed_spell_id(spell_category))
        _set_spell_dropdown_open(spell_category, false)
        _focus_spell(spell_category, _get_confirmed_spell_id(spell_category))
    else:
        _close_all_spell_dropdowns(true)
        _set_pending_spell_id(spell_category, _get_confirmed_spell_id(spell_category))
        _set_spell_dropdown_open(spell_category, true)
        _focus_spell(spell_category, _get_pending_spell_id(spell_category))
    _refresh_spell_ui()

func _on_spell_option_pressed(button: TextureButton, spell_category: String) -> void:
    if button == null or not button.has_meta("spell_id"):
        return
    var spell_id := String(button.get_meta("spell_id", ""))
    if spell_id == "":
        return
    _set_pending_spell_id(spell_category, spell_id)
    _focus_spell(spell_category, spell_id)
    _refresh_spell_ui()

func _on_spell_confirm_pressed(spell_category: String) -> void:
    var pending_spell_id := _get_pending_spell_id(spell_category)
    if pending_spell_id == "":
        return
    _set_confirmed_spell_id(spell_category, pending_spell_id)
    _set_spell_dropdown_open(spell_category, false)
    _focus_spell(spell_category, pending_spell_id)
    _refresh_spell_ui()

func _on_spell_cancel_pressed(spell_category: String) -> void:
    _set_pending_spell_id(spell_category, _get_confirmed_spell_id(spell_category))
    _set_spell_dropdown_open(spell_category, false)
    _focus_spell(spell_category, _get_confirmed_spell_id(spell_category))
    _refresh_spell_ui()

func _close_spell_dropdown_if_clicked_outside(mouse_position: Vector2) -> void:
    if _is_click_inside_spell_panel("active", mouse_position) or _is_click_inside_spell_panel("passive", mouse_position):
        return
    if not is_active_spell_dropdown_open and not is_passive_spell_dropdown_open:
        return
    var last_focused_spell_category := focused_spell_category
    _close_all_spell_dropdowns(true)
    if last_focused_spell_category != "" and _get_confirmed_spell_id(last_focused_spell_category) != "":
        _focus_spell(last_focused_spell_category, _get_confirmed_spell_id(last_focused_spell_category))
    _refresh_spell_ui()

func _is_click_inside_spell_panel(spell_category: String, mouse_position: Vector2) -> bool:
    var selected_button := _get_selected_spell_button(spell_category)
    if selected_button and selected_button.get_global_rect().has_point(mouse_position):
        return true
    var dropdown_panel := _get_spell_dropdown_panel(spell_category)
    return dropdown_panel != null and dropdown_panel.get_global_rect().has_point(mouse_position)

func _close_all_spell_dropdowns(reset_pending: bool) -> void:
    if reset_pending:
        pending_active_spell_id = confirmed_active_spell_id
        pending_passive_spell_id = confirmed_passive_spell_id
    is_active_spell_dropdown_open = false
    is_passive_spell_dropdown_open = false

func _refresh_description_panel() -> void:
    if description_title_label == null or description_body_label == null:
        return
    if focused_entry_type == "stat" and focused_stat_id != "":
        description_title_label.text = String(STAT_DISPLAY_NAMES.get(focused_stat_id, focused_stat_id.capitalize()))
        _set_description_body_plain_text("Current value: %d" % int(stat_values.get(focused_stat_id, STAT_DEFAULT)))
        _set_spell_meta_visible(false)
        return

    var spell_id := focused_spell_id
    if spell_id == "":
        if confirmed_active_spell_id != "":
            spell_id = confirmed_active_spell_id
        elif confirmed_passive_spell_id != "":
            spell_id = confirmed_passive_spell_id
    var spell_def: Dictionary = SPELL_DEFS.get(spell_id, {})
    if spell_def.is_empty():
        description_title_label.text = "King Ability"
        _set_description_body_plain_text("Choose one active and one passive king ability.")
        _set_spell_meta_visible(false)
        return

    description_title_label.text = String(spell_def.get("display_name", "King Ability"))
    var description_segments: Array = spell_def.get("description_segments", [])
    if description_segments.is_empty():
        _set_description_body_plain_text(String(spell_def.get("description", "Choose one king ability.")))
    else:
        _set_description_body_segments(description_segments)

    var is_active_spell := String(spell_def.get("category", "active")) == "active"
    _set_spell_meta_visible(is_active_spell)
    if is_active_spell:
        if description_cost_icon:
            description_cost_icon.texture = _get_spell_resource_texture(String(spell_def.get("resource", "")))
        if description_cost_label:
            description_cost_label.text = "%d %s" % [
                int(spell_def.get("cost", 0)),
                _get_spell_resource_label(String(spell_def.get("resource", "")))
            ]
        if description_cooldown_icon:
            description_cooldown_icon.text = "⌛"
        if description_cooldown_label:
            description_cooldown_label.text = "%d sec" % int(spell_def.get("cooldown", 0))

func _set_description_body_plain_text(text_value: String) -> void:
    if description_body_label == null:
        return
    description_body_label.clear()
    description_body_label.add_text(text_value)

func _set_description_body_segments(segments: Array) -> void:
    if description_body_label == null:
        return
    description_body_label.clear()
    for segment_variant in segments:
        var segment := segment_variant as Dictionary
        if segment.has("unit_face_id"):
            var unit_face_id := String(segment.get("unit_face_id", ""))
            var unit_face := UnitFaceLibraryScript.get_face_texture(unit_face_id, unit_face_id.capitalize())
            if unit_face == null:
                unit_face = SPELL_CANCEL_TEXTURE
            description_body_label.add_image(unit_face, DESCRIPTION_INLINE_ICON_SIZE, DESCRIPTION_INLINE_ICON_SIZE)
        if segment.has("icon_path"):
            var icon_path := String(segment.get("icon_path", ""))
            var texture := _load_runtime_texture(icon_path)
            if texture == null:
                texture = SPELL_CANCEL_TEXTURE
            description_body_label.add_image(texture, DESCRIPTION_INLINE_ICON_SIZE, DESCRIPTION_INLINE_ICON_SIZE)
        if segment.has("text"):
            description_body_label.add_text(String(segment.get("text", "")))

func _set_spell_meta_visible(is_visible: bool) -> void:
    if description_cost_icon:
        description_cost_icon.visible = is_visible
    if description_cost_label:
        description_cost_label.visible = is_visible
    if description_cooldown_icon:
        description_cooldown_icon.visible = is_visible
    if description_cooldown_label:
        description_cooldown_label.visible = is_visible

func _get_spell_resource_texture(resource_id: String) -> Texture2D:
    if resource_id == "water":
        return SPELL_WATER_TEXTURE
    if resource_id == "gold":
        return SPELL_GOLD_TEXTURE
    if resource_id == "wine":
        return SPELL_WINE_TEXTURE
    if resource_id == "meat":
        return SPELL_MEAT_TEXTURE
    return null

func _get_spell_resource_label(resource_id: String) -> String:
    if resource_id == "water":
        return "Water"
    if resource_id == "gold":
        return "Gold"
    if resource_id == "wine":
        return "Wine"
    if resource_id == "meat":
        return "Meat"
    return resource_id.capitalize()

func _update_selection_focus(delta: float) -> void:
    if selection_focus == null:
        return
    _selection_focus_time += delta
    var target := _get_focused_control()
    selection_focus.visible = target != null
    if target == null:
        return
    var pulse_ratio := 0.5 + 0.5 * sin(_selection_focus_time * TAU)
    var padding := lerpf(6.0, 11.0, pulse_ratio)
    var local_origin := global_position
    var target_rect := target.get_global_rect()
    selection_focus.position = target_rect.position - local_origin - Vector2(padding, padding)
    selection_focus.size = target_rect.size + Vector2.ONE * padding * 2.0
    selection_focus.modulate = Color(1.0, 1.0, 1.0, lerpf(0.62, 1.0, pulse_ratio))
    selection_focus.move_to_front()

func _sync_spell_dropdown_panel_position(spell_category: String) -> void:
    var dropdown_panel := _get_spell_dropdown_panel(spell_category)
    var selected_button := _get_selected_spell_button(spell_category)
    if dropdown_panel == null or selected_button == null:
        return
    dropdown_panel.global_position = selected_button.get_global_rect().position + SPELL_DROPDOWN_OFFSET

func _get_focused_control() -> Control:
    if focused_entry_type == "stat":
        return _stat_icon_controls.get(focused_stat_id) as Control
    if focused_entry_type == "active_spell":
        if is_active_spell_dropdown_open:
            var active_option_button := _find_spell_option_button("active", focused_spell_id)
            if active_option_button and active_option_button.visible:
                return active_option_button
        return active_selected_spell_button
    if focused_entry_type == "passive_spell":
        if is_passive_spell_dropdown_open:
            var passive_option_button := _find_spell_option_button("passive", focused_spell_id)
            if passive_option_button and passive_option_button.visible:
                return passive_option_button
        return passive_selected_spell_button
    return null

func _find_spell_option_button(spell_category: String, spell_id: String) -> TextureButton:
    var spell_buttons := _get_spell_buttons(spell_category)
    for button in spell_buttons:
        if button == null or not button.has_meta("spell_id"):
            continue
        if String(button.get_meta("spell_id", "")) == spell_id:
            return button
    return null

func _get_spell_buttons(spell_category: String) -> Array[TextureButton]:
    if spell_category == "active":
        return _active_spell_option_buttons
    return _passive_spell_option_buttons

func _get_selected_spell_button(spell_category: String) -> TextureButton:
    if spell_category == "active":
        return active_selected_spell_button
    return passive_selected_spell_button

func _get_spell_dropdown_panel(spell_category: String) -> Control:
    if spell_category == "active":
        return active_spell_dropdown_panel
    return passive_spell_dropdown_panel

func _get_spell_confirm_button(spell_category: String) -> TextureButton:
    if spell_category == "active":
        return active_spell_confirm_button
    return passive_spell_confirm_button

func _get_spell_cancel_button(spell_category: String) -> TextureButton:
    if spell_category == "active":
        return active_spell_cancel_button
    return passive_spell_cancel_button

func _is_spell_dropdown_open(spell_category: String) -> bool:
    if spell_category == "active":
        return is_active_spell_dropdown_open
    return is_passive_spell_dropdown_open

func _set_spell_dropdown_open(spell_category: String, is_open: bool) -> void:
    if spell_category == "active":
        is_active_spell_dropdown_open = is_open
    else:
        is_passive_spell_dropdown_open = is_open

func _get_confirmed_spell_id(spell_category: String) -> String:
    if spell_category == "active":
        return confirmed_active_spell_id
    return confirmed_passive_spell_id

func _set_confirmed_spell_id(spell_category: String, spell_id: String) -> void:
    if spell_category == "active":
        confirmed_active_spell_id = spell_id
    else:
        confirmed_passive_spell_id = spell_id

func _get_pending_spell_id(spell_category: String) -> String:
    if spell_category == "active":
        return pending_active_spell_id
    return pending_passive_spell_id

func _set_pending_spell_id(spell_category: String, spell_id: String) -> void:
    if spell_category == "active":
        pending_active_spell_id = spell_id
    else:
        pending_passive_spell_id = spell_id

func _configure_slider_button_feedback(button: TextureButton, rotation_degrees: float) -> void:
    if button == null:
        return
    _ensure_button_visual_state(button)
    var enter_callable := Callable(self, "_on_slider_hover_entered").bind(button)
    var exit_callable := Callable(self, "_on_slider_hover_exited").bind(button)
    var down_callable := Callable(self, "_on_slider_button_down").bind(button, rotation_degrees)
    var up_callable := Callable(self, "_on_slider_button_up").bind(button)
    if not button.mouse_entered.is_connected(enter_callable):
        button.mouse_entered.connect(enter_callable)
    if not button.mouse_exited.is_connected(exit_callable):
        button.mouse_exited.connect(exit_callable)
    if not button.button_down.is_connected(down_callable):
        button.button_down.connect(down_callable)
    if not button.button_up.is_connected(up_callable):
        button.button_up.connect(up_callable)

func _configure_stat_button_feedback(button: TextureButton) -> void:
    if button == null:
        return
    _ensure_button_visual_state(button)
    var down_callable := Callable(self, "_on_stat_button_down").bind(button)
    if not button.button_down.is_connected(down_callable):
        button.button_down.connect(down_callable)

func _ensure_button_visual_state(button: TextureButton) -> void:
    if button == null:
        return
    var button_id := button.get_instance_id()
    if _button_visual_state.has(button_id):
        return
    button.pivot_offset = button.size * 0.5
    var resize_callable := Callable(self, "_on_feedback_button_resized").bind(button)
    if not button.resized.is_connected(resize_callable):
        button.resized.connect(resize_callable)
    _button_visual_state[button_id] = {
        "scale": button.scale,
        "modulate": button.modulate,
        "rotation": button.rotation,
    }

func _on_feedback_button_resized(button: TextureButton) -> void:
    if button:
        button.pivot_offset = button.size * 0.5

func _on_slider_hover_entered(button: TextureButton) -> void:
    _animate_slider_button_to(button, 1.1, 1.15, _get_button_base_rotation(button), 0.12)

func _on_slider_hover_exited(button: TextureButton) -> void:
    _animate_slider_button_to(button, 1.0, 1.0, _get_button_base_rotation(button), 0.12)

func _on_slider_button_down(button: TextureButton, rotation_degrees: float) -> void:
    if button == null:
        return
    _kill_button_tween(button)
    var button_data := _get_button_visual_data(button)
    if button_data.is_empty():
        return
    var base_scale: Vector2 = button_data.get("scale", Vector2.ONE)
    var base_modulate: Color = button_data.get("modulate", Color.WHITE)
    var base_rotation: float = button_data.get("rotation", 0.0)
    var tween := create_tween()
    _button_tweens[button.get_instance_id()] = tween
    tween.set_parallel(true)
    tween.tween_property(button, "scale", base_scale * 1.2, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "modulate", _scaled_modulate(base_modulate, 1.2), 0.08)
    tween.tween_property(button, "rotation", base_rotation + deg_to_rad(rotation_degrees), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_slider_button_up(button: TextureButton) -> void:
    if button == null:
        return
    var is_hovered := button.get_global_rect().has_point(get_global_mouse_position())
    if is_hovered:
        _animate_slider_button_to(button, 1.1, 1.15, _get_button_base_rotation(button), 0.2)
    else:
        _animate_slider_button_to(button, 1.0, 1.0, _get_button_base_rotation(button), 0.2)

func _on_stat_button_down(button: TextureButton) -> void:
    if button == null:
        return
    _kill_button_tween(button)
    var button_data := _get_button_visual_data(button)
    if button_data.is_empty():
        return
    var base_scale: Vector2 = button_data.get("scale", Vector2.ONE)
    var tween := create_tween()
    _button_tweens[button.get_instance_id()] = tween
    tween.tween_property(button, "scale", base_scale * 0.85, 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", base_scale * 1.15, 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", base_scale, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _animate_slider_button_to(button: TextureButton, scale_multiplier: float, brightness_multiplier: float, target_rotation: float, duration: float) -> void:
    if button == null:
        return
    _kill_button_tween(button)
    var button_data := _get_button_visual_data(button)
    if button_data.is_empty():
        return
    var base_scale: Vector2 = button_data.get("scale", Vector2.ONE)
    var base_modulate: Color = button_data.get("modulate", Color.WHITE)
    var tween := create_tween()
    _button_tweens[button.get_instance_id()] = tween
    tween.set_parallel(true)
    tween.tween_property(button, "scale", base_scale * scale_multiplier, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "modulate", _scaled_modulate(base_modulate, brightness_multiplier), duration)
    tween.tween_property(button, "rotation", target_rotation, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _kill_button_tween(button: TextureButton) -> void:
    if button == null:
        return
    var button_id := button.get_instance_id()
    if _button_tweens.has(button_id):
        var tween: Tween = _button_tweens[button_id]
        if tween:
            tween.kill()
        _button_tweens.erase(button_id)

func _get_button_visual_data(button: TextureButton) -> Dictionary:
    if button == null:
        return {}
    return _button_visual_state.get(button.get_instance_id(), {})

func _get_button_base_rotation(button: TextureButton) -> float:
    var button_data := _get_button_visual_data(button)
    return float(button_data.get("rotation", 0.0))

func _scaled_modulate(color_value: Color, brightness_multiplier: float) -> Color:
    return Color(
        minf(color_value.r * brightness_multiplier, 1.0),
        minf(color_value.g * brightness_multiplier, 1.0),
        minf(color_value.b * brightness_multiplier, 1.0),
        color_value.a
    )

func _initialize_stats() -> void:
    free_points = FREE_POINTS_DEFAULT
    stat_values.clear()
    for stat_id in STAT_IDS:
        stat_values[stat_id] = STAT_DEFAULT

func _initialize_meta_state() -> void:
    selected_class_index = 0
    selected_age = AGE_MIN
    player_name = ""

func _initialize_class_token_state() -> void:
    _class_token_rope_length = _measure_class_token_rope_length()
    _class_token_attach_position = _get_class_token_attach_position()

func _initialize_name_sign_state() -> void:
    _name_sign_rope_length = _measure_name_sign_rope_length()
    _name_sign_attach_position = _get_name_sign_mid_attach_position()

func _on_minus_pressed(stat_id: String) -> void:
    var current := int(stat_values.get(stat_id, STAT_DEFAULT))
    if current <= STAT_MIN:
        return
    stat_values[stat_id] = current - 1
    free_points += 1
    _refresh_ui()

func _on_plus_pressed(stat_id: String) -> void:
    var current := int(stat_values.get(stat_id, STAT_DEFAULT))
    if current >= STAT_MAX:
        return
    if free_points <= 0:
        return
    stat_values[stat_id] = current + 1
    free_points -= 1
    _refresh_ui()

func _on_age_text_changed(new_text: String) -> void:
    if _is_updating_age_text:
        return
    var cleaned := _sanitize_age_text(new_text)
    if cleaned != new_text:
        _set_age_input_text(cleaned)

func _on_age_text_submitted(_new_text: String) -> void:
    _commit_age_input()
    age_input.release_focus()

func _on_age_focus_exited() -> void:
    _commit_age_input()

func _on_name_text_changed(new_text: String) -> void:
    if _is_updating_name_text:
        return
    var cleaned := _sanitize_name_text(new_text)
    if cleaned != new_text:
        _set_name_input_text(cleaned)
    player_name = cleaned
    _refresh_name_sign_display()

func _refresh_ui() -> void:
    if free_points_label:
        free_points_label.text = str(free_points)
    for stat_id in STAT_IDS:
        var row_data: Dictionary = _rows_by_stat.get(stat_id, {})
        var value_label := row_data.get("value_label") as Label
        var minus_button := row_data.get("minus_button") as TextureButton
        var plus_button := row_data.get("plus_button") as TextureButton
        var current := int(stat_values.get(stat_id, STAT_DEFAULT))
        if value_label:
            value_label.text = str(current)
        if minus_button:
            minus_button.disabled = current <= STAT_MIN
        if plus_button:
            plus_button.disabled = current >= STAT_MAX or free_points <= 0
    _refresh_description_panel()

func _refresh_meta_ui() -> void:
    var class_def: Dictionary = CLASS_DEFS[selected_class_index]
    if token_sprite:
        var texture_value: Variant = class_def.get("texture")
        if texture_value is Texture2D:
            token_sprite.texture = texture_value as Texture2D
    if class_name_label:
        class_name_label.text = String(class_def.get("display_name", "")).strip_edges()
    _set_age_input_text(str(selected_age))
    _set_name_input_text(player_name)
    _refresh_name_sign_display()
    _ensure_spell_selection_valid()
    _refresh_spell_ui()
    _refresh_description_panel()

func _commit_age_input() -> void:
    var cleaned := _sanitize_age_text(age_input.text)
    if cleaned == "":
        cleaned = str(selected_age)
    selected_age = clampi(int(cleaned), AGE_MIN, AGE_MAX)
    _set_age_input_text(str(selected_age))

func _set_age_input_text(value: String) -> void:
    _is_updating_age_text = true
    age_input.text = value
    age_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
    age_input.caret_column = age_input.text.length()
    _is_updating_age_text = false

func _set_name_input_text(value: String) -> void:
    _is_updating_name_text = true
    name_input.text = value
    name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_input.caret_column = name_input.text.length()
    _is_updating_name_text = false

func _refresh_name_sign_display() -> void:
    if name_sign_label == null:
        return
    var display_text := player_name.strip_edges()
    name_sign_label.text = display_text

func _sanitize_age_text(value: String) -> String:
    var result := ""
    for index in range(value.length()):
        var character := value.substr(index, 1)
        if character >= "0" and character <= "9":
            result += character
            if result.length() >= AGE_TEXT_MAX_LENGTH:
                break
    return result

func _sanitize_name_text(value: String) -> String:
    var result := ""
    for index in range(value.length()):
        var character := value.substr(index, 1)
        if _is_allowed_name_character(character):
            result += character
            if result.length() >= NAME_MAX_LENGTH:
                break
    return result

func _is_allowed_name_character(character: String) -> bool:
    if character == " ":
        return true
    var code := character.unicode_at(0)
    return (
        (code >= 65 and code <= 90)
        or (code >= 97 and code <= 122)
        or (code >= 1040 and code <= 1103)
        or code == 1025
        or code == 1105
    )

func _release_text_focus_if_clicked_outside() -> void:
    var focus_owner := get_viewport().gui_get_focus_owner()
    if focus_owner == null:
        return
    if focus_owner != age_input and focus_owner != name_input:
        return
    var focused_control := focus_owner as Control
    if focused_control == null:
        return
    var mouse_position := get_global_mouse_position()
    if focused_control.get_global_rect().has_point(mouse_position):
        return
    focused_control.release_focus()

func _reset_class_token_state() -> void:
    if token_root == null or token_spawn_point == null:
        return
    _class_token_drag_active = false
    _class_token_drag_mouse_offset = Vector2.ZERO
    _class_token_drag_velocity = Vector2.ZERO
    _class_token_velocity = Vector2.ZERO
    _class_token_rotation = 0.0
    _class_token_idle_time = 0.0
    _class_token_position = token_spawn_point.position
    _class_token_attach_position = _get_class_token_attach_position()
    _apply_class_token_nodes()

func _update_class_token(delta: float) -> void:
    if token_root == null or rope_anchor == null or rope_line == null:
        return
    _class_token_idle_time += delta
    if _class_token_drag_active:
        var mouse_local := _get_token_mouse_local_position()
        var target_position := mouse_local + _class_token_drag_mouse_offset
        var frame_velocity := (target_position - _class_token_position) / maxf(delta, 0.0001)
        _class_token_drag_velocity = _class_token_drag_velocity.lerp(frame_velocity, class_token_drag_velocity_smoothing)
        _class_token_position = target_position
        if class_token_physics_mode == ClassTokenPhysicsMode.TAUT_ROPE:
            _apply_taut_rope_constraint()
        else:
            _clamp_class_token_stretch()
    else:
        _class_token_velocity.y += class_token_gravity * delta
        var idle_force := sin(_class_token_idle_time * TAU * class_token_idle_sway_frequency) * class_token_idle_sway_strength
        _class_token_velocity.x += idle_force * delta
        if class_token_physics_mode == ClassTokenPhysicsMode.ELASTIC_ROPE:
            _apply_elastic_rope_force(delta)
        var damping_scale := maxf(1.0 - class_token_linear_damping * delta, 0.0)
        _class_token_velocity *= damping_scale
        _class_token_position += _class_token_velocity * delta
        if class_token_physics_mode == ClassTokenPhysicsMode.TAUT_ROPE:
            _apply_taut_rope_constraint()
        else:
            _clamp_class_token_stretch()
    _update_class_token_rotation(delta)
    _class_token_attach_position = _get_class_token_attach_position()
    _apply_class_token_nodes()

func _begin_class_token_drag() -> void:
    _class_token_drag_active = true
    _class_token_drag_velocity = Vector2.ZERO
    _class_token_drag_mouse_offset = _class_token_position - _get_token_mouse_local_position()

func _end_class_token_drag() -> void:
    _class_token_drag_active = false
    var release_velocity := _class_token_drag_velocity * class_token_release_velocity_multiplier
    release_velocity += _calculate_rope_release_impulse()
    _class_token_velocity = release_velocity

func _apply_taut_rope_constraint() -> void:
    var attach_offset := _get_class_token_attach_offset()
    var attach_position := _class_token_position + attach_offset
    var rope_vector := attach_position - rope_anchor.position
    var rope_distance := rope_vector.length()
    if rope_distance <= _class_token_rope_length or rope_distance <= 0.001:
        _class_token_attach_position = attach_position
        return
    var rope_direction := rope_vector / rope_distance
    attach_position = rope_anchor.position + rope_direction * _class_token_rope_length
    _class_token_position = attach_position - attach_offset
    var radial_velocity := _class_token_velocity.dot(rope_direction)
    if radial_velocity > 0.0:
        _class_token_velocity -= rope_direction * radial_velocity
    _class_token_attach_position = attach_position

func _apply_elastic_rope_force(delta: float) -> void:
    var attach_position := _get_class_token_attach_position()
    var rope_vector := attach_position - rope_anchor.position
    var rope_distance := rope_vector.length()
    if rope_distance <= _class_token_rope_length or rope_distance <= 0.001:
        _class_token_attach_position = attach_position
        return
    var rope_direction := rope_vector / rope_distance
    var stretch := rope_distance - _class_token_rope_length
    var spring_force := -rope_direction * stretch * class_token_spring_strength
    var radial_velocity := _class_token_velocity.dot(rope_direction)
    spring_force -= rope_direction * radial_velocity * class_token_spring_damping
    _class_token_velocity += spring_force * delta
    _class_token_attach_position = attach_position

func _clamp_class_token_stretch() -> void:
    var attach_offset := _get_class_token_attach_offset()
    var attach_position := _class_token_position + attach_offset
    var rope_vector := attach_position - rope_anchor.position
    var max_distance := _class_token_rope_length * (1.0 + class_token_max_stretch_ratio)
    var rope_distance := rope_vector.length()
    if rope_distance > max_distance and rope_distance > 0.001:
        var rope_direction := rope_vector / rope_distance
        attach_position = rope_anchor.position + rope_direction * max_distance
        _class_token_position = attach_position - attach_offset
        var radial_velocity := _class_token_velocity.dot(rope_direction)
        if radial_velocity > 0.0:
            _class_token_velocity -= rope_direction * radial_velocity
    _class_token_attach_position = _class_token_position + attach_offset

func _update_class_token_rotation(delta: float) -> void:
    var rope_vector := _class_token_attach_position - rope_anchor.position
    if rope_vector.length() <= 0.001:
        return
    var angle_from_vertical := atan2(rope_vector.x, rope_vector.y)
    var target_rotation := angle_from_vertical * class_token_rotation_influence
    _class_token_rotation = lerp_angle(
        _class_token_rotation,
        target_rotation,
        minf(class_token_rotation_lerp_speed * delta, 1.0)
    )

func _apply_class_token_nodes() -> void:
    if token_root:
        token_root.position = _class_token_position
        token_root.rotation = _class_token_rotation
    if rope_line:
        rope_line.visible = class_rope_sprite == null
        var rope_points := PackedVector2Array([rope_anchor.position, _class_token_attach_position])
        rope_line.points = rope_points
        var rope_vector := _class_token_attach_position - rope_anchor.position
        var rope_distance := rope_vector.length()
        if class_token_max_stretch_ratio <= 0.0:
            _class_token_tension_ratio = 0.0
        else:
            var stretch := maxf(rope_distance - _class_token_rope_length, 0.0)
            var max_stretch := _class_token_rope_length * class_token_max_stretch_ratio
            _class_token_tension_ratio = clampf(stretch / maxf(max_stretch, 0.001), 0.0, 1.0)
        var width_lerp: float = lerp(
            class_token_rope_visual_width,
            class_token_rope_visual_width * class_token_rope_min_width_ratio,
            _class_token_tension_ratio
        )
        rope_line.width = width_lerp
    _update_rope_visual_sprite(
        class_rope_sprite,
        rope_anchor.position,
        _class_token_attach_position,
        class_token_rope_visual_width,
        class_token_rope_min_width_ratio,
        _class_token_tension_ratio
    )
    _place_holder_sprite(class_rope_top_holder, rope_anchor.position)
    _place_holder_sprite(class_rope_bottom_holder, _class_token_attach_position)

func _update_rope_visual_sprite(rope_sprite: Sprite2D, start_position: Vector2, end_position: Vector2, visual_width: float, min_width_ratio: float, tension_ratio: float) -> void:
    if rope_sprite == null or rope_sprite.texture == null:
        return
    var rope_vector := end_position - start_position
    var rope_length := rope_vector.length()
    rope_sprite.visible = rope_length > 0.001
    if not rope_sprite.visible:
        return
    var texture_size := rope_sprite.texture.get_size()
    var effective_width := lerpf(visual_width, visual_width * min_width_ratio, tension_ratio)
    rope_sprite.position = (start_position + end_position) * 0.5
    rope_sprite.rotation = rope_vector.angle()
    rope_sprite.scale = Vector2(
        rope_length / maxf(texture_size.x, 1.0),
        effective_width / maxf(texture_size.y, 1.0)
    )

func _place_holder_sprite(holder_sprite: Sprite2D, holder_position: Vector2) -> void:
    if holder_sprite == null:
        return
    holder_sprite.position = holder_position

func _measure_class_token_rope_length() -> float:
    if rope_anchor == null or token_rest_point == null or token_attach_point == null:
        return 140.0
    var rest_attach_position := token_rest_point.position + token_attach_point.position
    return maxf((rest_attach_position - rope_anchor.position).length(), 1.0)

func _get_class_token_attach_position() -> Vector2:
    return _class_token_position + _get_class_token_attach_offset()

func _get_class_token_attach_offset() -> Vector2:
    if token_attach_point == null:
        return Vector2.ZERO
    return token_attach_point.position.rotated(_class_token_rotation)

func _get_token_mouse_local_position() -> Vector2:
    if token_rig == null:
        return Vector2.ZERO
    return token_rig.to_local(get_global_mouse_position())

func _is_mouse_over_class_token() -> bool:
    if token_sprite == null:
        return false
    var radius := 80.0
    if token_sprite.texture:
        var texture_size := token_sprite.texture.get_size() * token_sprite.scale.abs()
        radius = maxf(texture_size.x, texture_size.y) * 0.55
    return _get_token_mouse_local_position().distance_to(_class_token_position) <= radius

func _calculate_rope_release_impulse() -> Vector2:
    if rope_anchor == null:
        return Vector2.ZERO
    var attach_position := _get_class_token_attach_position()
    var rope_vector := attach_position - rope_anchor.position
    var rope_distance := rope_vector.length()
    if rope_distance <= _class_token_rope_length or rope_vector == Vector2.ZERO:
        return Vector2.ZERO
    var stretch := rope_distance - _class_token_rope_length
    var max_stretch := _class_token_rope_length * maxf(class_token_max_stretch_ratio, 0.001)
    var normalized_stretch := clampf(stretch / max_stretch, 0.0, 1.0)
    var rope_direction := rope_vector / rope_distance
    var impulse_strength := pow(normalized_stretch, 1.35) * class_token_release_spring_boost
    return -rope_direction * impulse_strength

func _reset_name_sign_state() -> void:
    if name_sign_root == null or name_sign_spawn_point == null:
        return
    _name_sign_drag_active = false
    _name_sign_drag_mouse_offset = Vector2.ZERO
    _name_sign_drag_velocity = Vector2.ZERO
    _name_sign_velocity = Vector2.ZERO
    _name_sign_rotation = 0.0
    _name_sign_idle_time = 0.0
    _name_sign_position = name_sign_spawn_point.position
    _name_sign_attach_position = _get_name_sign_mid_attach_position()
    _apply_name_sign_nodes()

func _update_name_sign(delta: float) -> void:
    if name_sign_root == null or name_sign_left_anchor == null or name_sign_right_anchor == null:
        return
    _name_sign_idle_time += delta
    if _name_sign_drag_active:
        var mouse_local := _get_name_sign_mouse_local_position()
        var target_position := mouse_local + _name_sign_drag_mouse_offset
        var frame_velocity := (target_position - _name_sign_position) / maxf(delta, 0.0001)
        _name_sign_drag_velocity = _name_sign_drag_velocity.lerp(frame_velocity, name_sign_drag_velocity_smoothing)
        _name_sign_position = target_position
        if class_token_physics_mode == ClassTokenPhysicsMode.TAUT_ROPE:
            _apply_name_sign_taut_constraints()
        else:
            _clamp_name_sign_stretch()
    else:
        _name_sign_velocity.y += name_sign_gravity * delta
        var idle_force := sin(_name_sign_idle_time * TAU * name_sign_idle_sway_frequency) * name_sign_idle_sway_strength
        _name_sign_velocity.x += idle_force * delta
        if class_token_physics_mode == ClassTokenPhysicsMode.ELASTIC_ROPE:
            _apply_name_sign_elastic_forces(delta)
        var damping_scale := maxf(1.0 - name_sign_linear_damping * delta, 0.0)
        _name_sign_velocity *= damping_scale
        _name_sign_position += _name_sign_velocity * delta
        if class_token_physics_mode == ClassTokenPhysicsMode.TAUT_ROPE:
            _apply_name_sign_taut_constraints()
        else:
            _clamp_name_sign_stretch()
    _update_name_sign_rotation(delta)
    _name_sign_attach_position = _get_name_sign_mid_attach_position()
    _apply_name_sign_nodes()

func _begin_name_sign_drag() -> void:
    _name_sign_drag_active = true
    _name_sign_drag_velocity = Vector2.ZERO
    _name_sign_drag_mouse_offset = _name_sign_position - _get_name_sign_mouse_local_position()

func _end_name_sign_drag() -> void:
    _name_sign_drag_active = false
    var release_velocity := _name_sign_drag_velocity * name_sign_release_velocity_multiplier
    release_velocity += _calculate_name_sign_release_impulse()
    _name_sign_velocity = release_velocity

func _apply_name_sign_taut_constraints() -> void:
    var anchors: Array = [name_sign_left_anchor.position, name_sign_right_anchor.position]
    var attach_offsets: Array = _get_name_sign_attach_offsets()
    for index in range(anchors.size()):
        var attach_position: Vector2 = _name_sign_position + attach_offsets[index]
        var rope_vector: Vector2 = attach_position - anchors[index]
        var rope_distance: float = rope_vector.length()
        if rope_distance <= _name_sign_rope_length or rope_distance <= 0.001:
            continue
        var rope_direction: Vector2 = rope_vector / rope_distance
        _name_sign_position -= rope_direction * (rope_distance - _name_sign_rope_length)
        var radial_velocity: float = _name_sign_velocity.dot(rope_direction)
        if radial_velocity > 0.0:
            _name_sign_velocity -= rope_direction * radial_velocity

func _apply_name_sign_elastic_forces(delta: float) -> void:
    var anchors: Array = [name_sign_left_anchor.position, name_sign_right_anchor.position]
    var attach_offsets: Array = _get_name_sign_attach_offsets()
    var total_force: Vector2 = Vector2.ZERO
    for index in range(anchors.size()):
        var attach_position: Vector2 = _name_sign_position + attach_offsets[index]
        var rope_vector: Vector2 = attach_position - anchors[index]
        var rope_distance: float = rope_vector.length()
        if rope_distance <= _name_sign_rope_length or rope_distance <= 0.001:
            continue
        var rope_direction: Vector2 = rope_vector / rope_distance
        var stretch: float = rope_distance - _name_sign_rope_length
        var spring_force: Vector2 = -rope_direction * stretch * name_sign_spring_strength
        var radial_velocity: float = _name_sign_velocity.dot(rope_direction)
        spring_force -= rope_direction * radial_velocity * name_sign_spring_damping
        total_force += spring_force
    _name_sign_velocity += total_force * delta

func _clamp_name_sign_stretch() -> void:
    var anchors: Array = [name_sign_left_anchor.position, name_sign_right_anchor.position]
    var attach_offsets: Array = _get_name_sign_attach_offsets()
    var max_distance: float = _name_sign_rope_length * (1.0 + name_sign_max_stretch_ratio)
    for index in range(anchors.size()):
        var attach_position: Vector2 = _name_sign_position + attach_offsets[index]
        var rope_vector: Vector2 = attach_position - anchors[index]
        var rope_distance: float = rope_vector.length()
        if rope_distance <= max_distance or rope_distance <= 0.001:
            continue
        var rope_direction: Vector2 = rope_vector / rope_distance
        _name_sign_position -= rope_direction * (rope_distance - max_distance)
        var radial_velocity: float = _name_sign_velocity.dot(rope_direction)
        if radial_velocity > 0.0:
            _name_sign_velocity -= rope_direction * radial_velocity

func _update_name_sign_rotation(delta: float) -> void:
    var midpoint_anchor := (name_sign_left_anchor.position + name_sign_right_anchor.position) * 0.5
    var midpoint_attach := _get_name_sign_mid_attach_position()
    var rope_vector := midpoint_attach - midpoint_anchor
    if rope_vector.length() <= 0.001:
        return
    var angle_from_vertical := atan2(rope_vector.x, rope_vector.y)
    var left_attach_position := _get_name_sign_attach_position(name_sign_left_attach_point)
    var right_attach_position := _get_name_sign_attach_position(name_sign_right_attach_point)
    var balance_rotation := clampf((left_attach_position.y - right_attach_position.y) * 0.003, -0.18, 0.18)
    var target_rotation := angle_from_vertical * name_sign_rotation_influence + balance_rotation
    _name_sign_rotation = lerp_angle(
        _name_sign_rotation,
        target_rotation,
        minf(name_sign_rotation_lerp_speed * delta, 1.0)
    )

func _apply_name_sign_nodes() -> void:
    if name_sign_root:
        name_sign_root.position = _name_sign_position
        name_sign_root.rotation = _name_sign_rotation
    var left_attach_position := _get_name_sign_attach_position(name_sign_left_attach_point)
    var right_attach_position := _get_name_sign_attach_position(name_sign_right_attach_point)
    var max_stretch := _name_sign_rope_length * maxf(name_sign_max_stretch_ratio, 0.001)
    var left_distance := (left_attach_position - name_sign_left_anchor.position).length()
    var right_distance := (right_attach_position - name_sign_right_anchor.position).length()
    var left_stretch := maxf(left_distance - _name_sign_rope_length, 0.0)
    var right_stretch := maxf(right_distance - _name_sign_rope_length, 0.0)
    _name_sign_tension_ratio = clampf(maxf(left_stretch, right_stretch) / maxf(max_stretch, 0.001), 0.0, 1.0)
    _update_rope_visual_sprite(
        name_sign_left_rope,
        name_sign_left_anchor.position,
        left_attach_position,
        name_sign_rope_visual_width,
        name_sign_rope_min_width_ratio,
        _name_sign_tension_ratio
    )
    _update_rope_visual_sprite(
        name_sign_right_rope,
        name_sign_right_anchor.position,
        right_attach_position,
        name_sign_rope_visual_width,
        name_sign_rope_min_width_ratio,
        _name_sign_tension_ratio
    )
    _place_holder_sprite(name_sign_left_top_holder, name_sign_left_anchor.position)
    _place_holder_sprite(name_sign_right_top_holder, name_sign_right_anchor.position)
    _place_holder_sprite(name_sign_left_bottom_holder, left_attach_position)
    _place_holder_sprite(name_sign_right_bottom_holder, right_attach_position)

func _measure_name_sign_rope_length() -> float:
    if name_sign_left_anchor == null or name_sign_right_anchor == null or name_sign_rest_point == null:
        return 120.0
    var left_rest_attach := name_sign_rest_point.position + _get_name_sign_attach_offset(name_sign_left_attach_point)
    var right_rest_attach := name_sign_rest_point.position + _get_name_sign_attach_offset(name_sign_right_attach_point)
    var left_length := (left_rest_attach - name_sign_left_anchor.position).length()
    var right_length := (right_rest_attach - name_sign_right_anchor.position).length()
    return maxf((left_length + right_length) * 0.5, 1.0)

func _get_name_sign_attach_offsets() -> Array:
    return [
        _get_name_sign_attach_offset(name_sign_left_attach_point),
        _get_name_sign_attach_offset(name_sign_right_attach_point),
    ]

func _get_name_sign_attach_offset(attach_point: Marker2D) -> Vector2:
    if attach_point == null:
        return Vector2.ZERO
    var scaled_offset := attach_point.position
    if name_sign_root:
        var root_scale := name_sign_root.scale
        scaled_offset = Vector2(scaled_offset.x * root_scale.x, scaled_offset.y * root_scale.y)
    return scaled_offset.rotated(_name_sign_rotation)

func _get_name_sign_attach_position(attach_point: Marker2D) -> Vector2:
    return _name_sign_position + _get_name_sign_attach_offset(attach_point)

func _get_name_sign_mid_attach_position() -> Vector2:
    return (_get_name_sign_attach_position(name_sign_left_attach_point) + _get_name_sign_attach_position(name_sign_right_attach_point)) * 0.5

func _get_name_sign_mouse_local_position() -> Vector2:
    if name_sign_rig == null:
        return Vector2.ZERO
    return name_sign_rig.to_local(get_global_mouse_position())

func _is_mouse_over_name_sign() -> bool:
    if name_sign_sprite == null:
        return false
    var sprite_size := Vector2(200.0, 80.0)
    if name_sign_sprite.texture:
        sprite_size = name_sign_sprite.texture.get_size() * name_sign_sprite.scale.abs()
    if name_sign_root:
        var root_scale := name_sign_root.scale.abs()
        sprite_size.x *= root_scale.x
        sprite_size.y *= root_scale.y
    var half_extent := sprite_size * 0.5
    var local_point := _get_name_sign_mouse_local_position() - _name_sign_position
    return absf(local_point.x) <= half_extent.x and absf(local_point.y) <= half_extent.y

func _calculate_name_sign_release_impulse() -> Vector2:
    if name_sign_left_anchor == null or name_sign_right_anchor == null:
        return Vector2.ZERO
    var midpoint_anchor := (name_sign_left_anchor.position + name_sign_right_anchor.position) * 0.5
    var midpoint_attach := _get_name_sign_mid_attach_position()
    var rope_vector := midpoint_attach - midpoint_anchor
    var rope_distance := rope_vector.length()
    if rope_distance <= _name_sign_rope_length or rope_distance <= 0.001:
        return Vector2.ZERO
    var stretch := rope_distance - _name_sign_rope_length
    var max_stretch := _name_sign_rope_length * maxf(name_sign_max_stretch_ratio, 0.001)
    var normalized_stretch := clampf(stretch / max_stretch, 0.0, 1.0)
    var rope_direction := rope_vector / rope_distance
    var impulse_strength := pow(normalized_stretch, 1.2) * name_sign_release_spring_boost
    return -rope_direction * impulse_strength

func _update_focus_carets(delta: float) -> void:
    _input_focus_caret_time += delta
    _update_focus_caret(age_input, age_focus_caret)
    _update_focus_caret(name_input, name_focus_caret)

func _update_focus_caret(line_edit: LineEdit, caret: ColorRect) -> void:
    if line_edit == null or caret == null:
        return
    caret.visible = line_edit.has_focus()
    if not caret.visible:
        return
    var cycle := maxf(input_focus_caret_pulse_interval, 0.001)
    var pulse_ratio := 0.5 + 0.5 * sin((_input_focus_caret_time / cycle) * TAU)
    var caret_height := line_edit.size.y * 0.62
    var caret_alpha := lerpf(input_focus_caret_min_alpha, 1.0, pulse_ratio)
    caret.color = Color(0.08, 0.05, 0.02, 1.0)
    caret.modulate.a = caret_alpha
    caret.size = Vector2(input_focus_caret_width, caret_height)
    caret.position = line_edit.position + Vector2(
        _get_centered_caret_x(line_edit) - input_focus_caret_width * 0.5,
        (line_edit.size.y - caret_height) * 0.5
    )

func _get_centered_caret_x(line_edit: LineEdit) -> float:
    if line_edit == null:
        return 0.0
    var font := line_edit.get_theme_font("font")
    if font == null:
        return line_edit.size.x * 0.5
    var font_size := line_edit.get_theme_font_size("font_size")
    var full_text := line_edit.text
    if full_text == "":
        return line_edit.size.x * 0.5
    var prefix_text := full_text.substr(0, mini(line_edit.caret_column, full_text.length()))
    var full_width := font.get_string_size(full_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    var prefix_width := font.get_string_size(prefix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    var start_x := (line_edit.size.x - full_width) * 0.5
    return clampf(start_x + prefix_width, 0.0, line_edit.size.x)
