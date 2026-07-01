extends HBoxContainer
class_name ProphecyCardTooltip

const EnemyPortraitScene: PackedScene = preload("res://scenes/ui/components/EnemyPortrait.tscn")
const EnemyInfoCardScene: PackedScene = preload("res://scenes/ui/prophecy/ProphecyEnemyInfoCard.tscn")
const RewardPresentationRegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")
const ProhesyMatesParserScript := preload("res://scripts/prophecy/modules/ProhesyMatesParser.gd")

const ThaleahFont := preload("res://assets/ui/fonts/ThaleahFat.ttf")

const DEBUG_PROPHECY_TOOLTIP := true

@onready var title_label: Label = get_node_or_null("CardPanel/Margin/VBox/Title")
@onready var rewards_title_label: Label = get_node_or_null("CardPanel/Margin/VBox/RewardsTitle")
@onready var enemies_rows: VBoxContainer = get_node_or_null("CardPanel/Margin/VBox/EnemiesRows")
@onready var rewards_rows: VBoxContainer = get_node_or_null("CardPanel/Margin/VBox/RewardsRows")
@onready var enemy_cards: VBoxContainer = get_node_or_null("EnemyCards")

static var _enemy_doc_cache: Dictionary = {}
static var _prohesy_mates_cache: Dictionary = {}
static var _re_hp := RegEx.new()
static var _re_dps := RegEx.new()

var _pending_patterns: Array = []
var _has_pending_setup: bool = false

func _ready() -> void:
    if DEBUG_PROPHECY_TOOLTIP:
        print("[ProphecyCardTooltip] _ready name=", name, " title_label=", title_label, " enemies_rows=", enemies_rows, " rewards_rows=", rewards_rows, " enemy_cards=", enemy_cards)
    if _re_hp.get_pattern() == "":
        _re_hp.compile("(?is)\\bHP\\b\\s*:?\\s*(\\d+)")
        _re_dps.compile("(?is)(?:\\bDPS\\b|Damage\\s+per\\s+second)\\s*:?\\s*(\\d+)")
    if _has_pending_setup:
        _has_pending_setup = false
        var pending := _pending_patterns
        _pending_patterns = []
        if DEBUG_PROPHECY_TOOLTIP:
            print("[ProphecyCardTooltip] _ready applying pending setup patterns=", (pending.size() if pending != null else -1))
        _populate(pending)

func setup(option_patterns: Array) -> void:
    if DEBUG_PROPHECY_TOOLTIP:
        print("[ProphecyCardTooltip] setup called node_ready=", is_node_ready(), " patterns=", (option_patterns.size() if option_patterns != null else -1))
    if not is_node_ready():
        _pending_patterns = option_patterns.duplicate()
        _has_pending_setup = true
        if DEBUG_PROPHECY_TOOLTIP:
            print("[ProphecyCardTooltip] setup deferred until _ready pending=", _pending_patterns.size())
        return
    _populate(option_patterns)

func _populate(option_patterns: Array) -> void:
    if DEBUG_PROPHECY_TOOLTIP:
        print("[ProphecyCardTooltip] _populate start patterns=", (option_patterns.size() if option_patterns != null else -1))
    if rewards_title_label:
        rewards_title_label.visible = false
    if enemies_rows:
        for ch in enemies_rows.get_children():
            ch.queue_free()
    if rewards_rows:
        for ch in rewards_rows.get_children():
            ch.queue_free()
    if enemy_cards:
        for ch in enemy_cards.get_children():
            ch.queue_free()
    if DEBUG_PROPHECY_TOOLTIP and (title_label == null or enemies_rows == null or rewards_rows == null or enemy_cards == null):
        print("[ProphecyCardTooltip] WARNING missing nodes title_label=", title_label, " enemies_rows=", enemies_rows, " rewards_rows=", rewards_rows, " enemy_cards=", enemy_cards)

    var order: Array[String] = []
    var counts: Dictionary = {}
    var rewards: Array[Dictionary] = []
    var title_set: bool = false

    for p in option_patterns:
        if p == null:
            continue
        _add_enemy_count(order, counts, String(p.mob_1_id), int(p.mob_1_count))
        if bool(p.mob_2_enabled) and String(p.mob_2_id) != "":
            _add_enemy_count(order, counts, String(p.mob_2_id), int(p.mob_2_count))
        _append_reward_entry(rewards, int(p.reward_1_type), int(p.reward_1_amount))
        if bool(p.reward_2_enabled):
            _append_reward_entry(rewards, int(p.reward_2_type), int(p.reward_2_amount))

    for enemy_id in order:
        var c: int = int(counts.get(enemy_id, 0))
        var info := _get_enemy_doc_info(enemy_id)
        var display_name: String = info.get("name", enemy_id)
        var hp: Variant = info.get("hp", null)
        var dps: Variant = info.get("dps", null)

        if not title_set and title_label:
            title_set = true
            title_label.text = "Prophecy card"

        if enemies_rows:
            enemies_rows.add_child(_build_enemy_row(enemy_id, display_name, c))
        if enemy_cards and EnemyInfoCardScene:
            var card := EnemyInfoCardScene.instantiate()
            if card is Control:
                var card_control := card as Control
                card_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                card_control.custom_minimum_size.x = maxf(card_control.custom_minimum_size.x, 380.0)
            enemy_cards.add_child(card)
            if card is ProphecyEnemyInfoCard:
                card.call_deferred("setup", enemy_id, display_name, hp, dps)

    if rewards_rows:
        for reward_entry in rewards:
            rewards_rows.add_child(_build_reward_row(reward_entry))

    if title_label and not title_set:
        title_label.text = "Prophecy card"

func _add_enemy_count(order: Array[String], counts: Dictionary, enemy_id: String, add_count: int) -> void:
    if enemy_id == "":
        return
    if not counts.has(enemy_id):
        counts[enemy_id] = 0
        order.append(enemy_id)
    counts[enemy_id] = int(counts[enemy_id]) + add_count

func _build_enemy_row(enemy_id: String, display_name: String, count: int) -> Control:
    var row := HBoxContainer.new()
    row.set("theme_override_constants/separation", 8)

    var portrait := EnemyPortraitScene.instantiate()
    if portrait and portrait.has_method("set_enemy_portrait"):
        portrait.set_enemy_portrait(enemy_id)
    if portrait is Control:
        (portrait as Control).custom_minimum_size = Vector2(28, 28)
        (portrait as Control).size = Vector2(28, 28)
    row.add_child(portrait)

    var label := Label.new()
    label.text = "x%d %s" % [count, display_name]
    label.add_theme_font_override("font", ThaleahFont)
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color.BLACK)
    row.add_child(label)

    return row

func _append_reward_entry(rewards: Array[Dictionary], reward_type: int, amount: int) -> void:
    var reward_key := "%d:%d" % [reward_type, amount]
    for reward_entry in rewards:
        if str(reward_entry.get("key", "")) == reward_key:
            return
    rewards.append({
        "key": reward_key,
        "type": reward_type,
        "amount": amount,
    })

func _build_reward_row(reward_entry: Dictionary) -> Control:
    var row := HBoxContainer.new()
    row.set("theme_override_constants/separation", 8)

    var reward_type := int(reward_entry.get("type", -1))
    var amount := int(reward_entry.get("amount", 0))

    var icon := TextureRect.new()
    icon.texture = _get_reward_icon(reward_type)
    icon.custom_minimum_size = Vector2(30, 30)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    row.add_child(icon)

    var label := Label.new()
    label.text = _format_reward_display_name(reward_type, amount)
    label.add_theme_font_override("font", ThaleahFont)
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
    row.add_child(label)

    return row

func _format_reward_display_name(reward_type: int, amount: int) -> String:
    var base_name := _get_reward_display_name(reward_type)
    if amount > 0:
        return "%s x%d" % [base_name, amount]
    return base_name

func _get_reward_icon(t: int) -> Texture2D:
    return RewardPresentationRegistryScript.get_reward_icon(t)

func _get_reward_display_name(t: int) -> String:
    return RewardPresentationRegistryScript.get_reward_display_name(t)

func _get_enemy_doc_info(enemy_id: String) -> Dictionary:
    var key := enemy_id.to_lower()
    if _enemy_doc_cache.has(key):
        return _enemy_doc_cache[key]

    if _prohesy_mates_cache.is_empty():
        _prohesy_mates_cache = ProhesyMatesParserScript.load_stats()

    var info := ProhesyMatesParserScript.get_enemy_info(enemy_id, _re_hp, _re_dps, _prohesy_mates_cache)

    _enemy_doc_cache[key] = info
    return info
