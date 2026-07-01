extends RefCounted
class_name ProphecyWaveCardRowBuilder

const RewardPresentationRegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")


static func compute_total_mob_counts(patterns: Array) -> Dictionary:
    var counts: Dictionary = {}
    for p in patterns:
        if p == null:
            continue
        _add_mob_count(counts, String(p.mob_1_id), int(p.mob_1_count))
        if bool(p.mob_2_enabled) and String(p.mob_2_id) != "":
            _add_mob_count(counts, String(p.mob_2_id), int(p.mob_2_count))
    return counts


static func compute_min_size(rows_count: int, card_min_width: float, mob_portrait_size: Vector2, row_vertical_separation: float, card_vertical_padding: float) -> Vector2:
    var clamped_rows: int = max(1, rows_count)
    var rows_height: float = float(clamped_rows) * mob_portrait_size.y
    rows_height += float(max(0, clamped_rows - 1)) * row_vertical_separation
    return Vector2(card_min_width, rows_height + card_vertical_padding)


static func build_pattern_row(
    p: ProphecyPattern,
    total_mob_counts: Dictionary,
    shown: Dictionary,
    mob_cell_spacing: int,
    mob_portrait_size: Vector2,
    mob_count_font_size: int,
    thaleah_font: Font,
    enemy_portrait_scene: PackedScene
) -> Control:
    var row := HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.set("theme_override_constants/separation", 30)
    row.clip_contents = true

    var mobs := HBoxContainer.new()
    mobs.set("theme_override_constants/separation", mob_cell_spacing)
    mobs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mobs.clip_contents = true

    var mob1_id := String(p.mob_1_id)
    if mob1_id != "" and not shown.has(mob1_id):
        shown[mob1_id] = true
        mobs.add_child(_build_mob_cell(mob1_id, int(total_mob_counts.get(mob1_id, int(p.mob_1_count))), mob_portrait_size, mob_count_font_size, thaleah_font, enemy_portrait_scene))

    if p.mob_2_enabled and p.mob_2_id != "":
        var mob2_id := String(p.mob_2_id)
        if mob2_id != "" and not shown.has(mob2_id):
            shown[mob2_id] = true
            mobs.add_child(_build_mob_cell(mob2_id, int(total_mob_counts.get(mob2_id, int(p.mob_2_count))), mob_portrait_size, mob_count_font_size, thaleah_font, enemy_portrait_scene))

    var rewards := HBoxContainer.new()
    rewards.set("theme_override_constants/separation", 6)
    rewards.size_flags_horizontal = Control.SIZE_SHRINK_END
    rewards.clip_contents = true

    rewards.add_child(_build_reward_icon(RewardPresentationRegistryScript.get_reward_icon(int(p.reward_1_type))))
    if p.reward_2_enabled:
        rewards.add_child(_build_reward_icon(RewardPresentationRegistryScript.get_reward_icon(int(p.reward_2_type))))

    row.add_child(mobs)
    row.add_child(rewards)
    return row


static func _add_mob_count(counts: Dictionary, mob_id: String, mob_count: int) -> void:
    if mob_id == "":
        return
    if not counts.has(mob_id):
        counts[mob_id] = 0
    counts[mob_id] = int(counts[mob_id]) + mob_count


static func _build_reward_icon(tex: Texture2D) -> Control:
    var icon := TextureRect.new()
    icon.texture = tex
    icon.custom_minimum_size = Vector2(42, 42)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    return icon


static func _build_mob_cell(
    mob_id: String,
    mob_count: int,
    mob_portrait_size: Vector2,
    mob_count_font_size: int,
    thaleah_font: Font,
    enemy_portrait_scene: PackedScene
) -> Control:
    var cell := HBoxContainer.new()
    cell.set("theme_override_constants/separation", 6)
    cell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    cell.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

    var portrait_wrapper := Control.new()
    portrait_wrapper.custom_minimum_size = mob_portrait_size
    portrait_wrapper.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    portrait_wrapper.clip_contents = true

    var portrait_texture := _get_enemy_portrait_texture(mob_id, enemy_portrait_scene)
    var portrait_rect := TextureRect.new()
    portrait_rect.texture = portrait_texture
    portrait_rect.custom_minimum_size = mob_portrait_size
    portrait_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    portrait_rect.offset_left = 0
    portrait_rect.offset_top = 0
    portrait_rect.offset_right = 0
    portrait_rect.offset_bottom = 0
    portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
    portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait_wrapper.add_child(portrait_rect)
    cell.add_child(portrait_wrapper)

    var label := Label.new()
    label.text = "%d" % mob_count
    label.add_theme_font_override("font", thaleah_font)
    label.add_theme_font_size_override("font_size", mob_count_font_size)
    label.add_theme_color_override("font_color", Color(1, 1, 1))
    label.add_theme_constant_override("outline_size", 3)
    label.add_theme_color_override("outline_color", Color.BLACK)
    label.custom_minimum_size = Vector2(0, mob_portrait_size.y)
    label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    label.size_flags_vertical = Control.SIZE_SHRINK_END
    cell.add_child(label)

    return cell


static func _get_enemy_portrait_texture(enemy_id: String, enemy_portrait_scene: PackedScene) -> Texture2D:
    var portrait := enemy_portrait_scene.instantiate()
    if portrait and portrait.has_method("set_enemy_portrait"):
        portrait.set_enemy_portrait(enemy_id)
        if portrait is TextureRect:
            var tex := (portrait as TextureRect).texture
            portrait.queue_free()
            return tex
    portrait.queue_free()
    return null
