extends PanelContainer
class_name WaveTooltip

## Tooltip showing wave prophecy information
## Displays: Wave number, list of enemies, rewards

const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")
const RewardPresentationRegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")
const ProhesyMatesParserScript := preload("res://scripts/prophecy/modules/ProhesyMatesParser.gd")
const EnemyPortraitScene: PackedScene = preload("res://scenes/ui/components/EnemyPortrait.tscn")

var _default_rewards: Array = []
var _prohesy_mates_cache: Dictionary = {}

@onready var _wave_title: Label = $Margin/VBox/WaveTitle
@onready var _enemies_list: VBoxContainer = $Margin/VBox/EnemiesList
@onready var _rewards_list: VBoxContainer = $Margin/VBox/RewardsList

var _wave_number: int = 0

func _ready() -> void:
    set_anchors_preset(Control.PRESET_TOP_LEFT)
    size_flags_horizontal = 0
    size_flags_vertical = 0
    _default_rewards = _build_default_rewards()
    hide()
    
func setup_wave(wave_num: int, preview: Dictionary = {}) -> void:
    _wave_number = wave_num
    
    var wave_title: String = "Prophecy"
    if preview and preview.has("wave_title"):
        wave_title = str(preview.get("wave_title", "Prophecy"))
    _wave_title.text = wave_title
    _wave_title.add_theme_font_size_override("font_size", 25)
    _wave_title.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
    
    var mob_counts: Dictionary = {}
    if preview and preview.has("mob_counts") and typeof(preview["mob_counts"]) == TYPE_DICTIONARY:
        mob_counts = preview["mob_counts"]
    _populate_enemies(mob_counts)
    
    var rewards: Array = []
    if preview and preview.has("rewards") and typeof(preview["rewards"]) == TYPE_ARRAY:
        rewards = preview["rewards"]
    _populate_rewards(rewards)
    
    call_deferred("_fit_to_content")

func _populate_enemies(mob_counts: Dictionary) -> void:
    for child in _enemies_list.get_children():
        child.queue_free()
    
    if mob_counts == null or mob_counts.is_empty():
        _enemies_list.add_child(_build_enemy_row("goblin_bandit", 1))
        return
    
    var enemy_ids := mob_counts.keys()
    enemy_ids.sort()
    for enemy_id in enemy_ids:
        var count: int = int(mob_counts[enemy_id])
        _enemies_list.add_child(_build_enemy_row(enemy_id, max(1, count)))

func _build_enemy_row(enemy_id: String, enemy_count: int) -> Control:
    var row := HBoxContainer.new()
    row.set("theme_override_constants/separation", 8)
    
    var portrait := EnemyPortraitScene.instantiate()
    if portrait is Control:
        var portrait_control := portrait as Control
        portrait_control.custom_minimum_size = Vector2(32, 32)
        portrait_control.size = Vector2(32, 32)
    if portrait and portrait.has_method("set_enemy_portrait"):
        portrait.set_enemy_portrait(enemy_id)
    row.add_child(portrait)
    
    var label := Label.new()
    label.text = "x%d %s" % [enemy_count, _get_enemy_display_name(enemy_id)]
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
    row.add_child(label)
    
    return row

func _populate_rewards(rewards: Array) -> void:
    for child in _rewards_list.get_children():
        child.queue_free()
    
    _add_divider()
    
    if rewards == null or rewards.is_empty():
        for default_reward in _default_rewards:
            var icon_tex: Texture2D = default_reward.icon
            var label_text: String = default_reward.label
            _add_reward_row(icon_tex, label_text)
        return
    
    for reward in rewards:
        if typeof(reward) != TYPE_DICTIONARY:
            continue
    
        var reward_dict: Dictionary = reward
        var label_text: String = str(reward_dict.get("label", "Reward"))
        
        var icon_value = reward_dict.get("icon", null)
        var icon: Texture2D = null
        if icon_value is Texture2D:
            icon = icon_value
        if icon == null and reward_dict.has("icon_path"):
            var icon_path: String = str(reward_dict["icon_path"])
            var loaded_icon := load(icon_path)
            if loaded_icon is Texture2D:
                icon = loaded_icon
        
        _add_reward_row(icon, label_text)

func _add_reward_row(icon_texture: Texture2D, label_text: String) -> void:
    var row := HBoxContainer.new()
    row.set("theme_override_constants/separation", 8)
    _rewards_list.add_child(row)
    
    var icon := TextureRect.new()
    if icon_texture:
        icon.texture = icon_texture
        icon.custom_minimum_size = Vector2(36, 36)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    else:
        icon.visible = false
    row.add_child(icon)
    
    var label := Label.new()
    label.text = label_text
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
    row.add_child(label)

func _add_divider() -> void:
    var divider := ColorRect.new()
    divider.color = Color(0.55, 0.45, 0.3, 1)
    divider.custom_minimum_size = Vector2(200, 2)
    _rewards_list.add_child(divider)

func _get_enemy_display_name(enemy_id: String) -> String:
    if _prohesy_mates_cache.is_empty():
        _prohesy_mates_cache = ProhesyMatesParserScript.load_stats()
    return ProhesyMatesParserScript.get_enemy_display_name(enemy_id, _prohesy_mates_cache)

func _build_default_rewards() -> Array:
    return [
        {
            "icon": RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.DENARII),
            "label": "x10 %s" % RewardPresentationRegistryScript.get_reward_display_name(ProphecyPatternScript.RewardType.DENARII),
        },
        {
            "icon": RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.LEVY_BARRACKS),
            "label": RewardPresentationRegistryScript.get_reward_display_name(ProphecyPatternScript.RewardType.LEVY_BARRACKS),
        },
        {
            "icon": RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.BASIC_PRODUCTION),
            "label": RewardPresentationRegistryScript.get_reward_display_name(ProphecyPatternScript.RewardType.BASIC_PRODUCTION),
        },
        {
            "icon": RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.PROPHECY),
            "label": RewardPresentationRegistryScript.get_reward_display_name(ProphecyPatternScript.RewardType.PROPHECY),
        },
    ]

func _fit_to_content() -> void:
    custom_minimum_size = Vector2(220, 0)
    size = Vector2.ZERO
    reset_size()
    await get_tree().process_frame
    size = get_combined_minimum_size()
