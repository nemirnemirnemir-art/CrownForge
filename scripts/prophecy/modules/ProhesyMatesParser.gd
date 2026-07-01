extends RefCounted
class_name ProhesyMatesParser

const PROPHECY_DATA_PATHS: Array[String] = [
    "res://docs/wiki/systems/PROPHECY_PATTERNS.md",
    "res://docs/Prohesy_mates.md",
    "res://assets/docs/Prohesy_mates.md",
]

const WIKI_PAGE_DIRS: Array[String] = [
    "res://docs/wiki/pages",
    "res://docs/wiki_pages",
    "res://assets/docs/wiki_pages",
]

const MobSceneRegistryScript = preload("res://scripts/game_scene/modules/MobSceneRegistry.gd")

const FALLBACK_POWER_BY_MOB_ID := {
    "goblin_bandit": 15.0,
    "goblin_crossbowman": 20.0,
    "goblin_lightning_mage": 25.0,
    "goblin_swordsman": 30.0,
    "wall_buster": 32.0,
    "goblin_shaman": 35.0,
    "blue_slime": 40.0,
    "goblin_pig": 45.0,
    "goblin_lizard": 50.0,
    "goblin_fire_mage": 50.0,
    "goblin_giant": 75.0,
    "blue_slug": 79.0,
    "stone_golem": 100.0,
    "goblin_bat_rider": 100.0,
    "show_golem": 109.0,
    "green_slug": 150.0,
    "crab_rider": 169.0,
    "mechanical_bat": 171.0,
    "sand_golem": 180.0,
    "sunfaced": 200.0,
    "mechanical_mammoth": 320.0,
}

static var _mob_stats_cache: Dictionary = {}


static func load_powers() -> Dictionary:
    var rows: Array = _parse_prophecy_table_rows(_load_prophecy_source_text())
    var power_by_mob_id: Dictionary = get_fallback_powers()

    for row_any in rows:
        var row: Dictionary = row_any
        var mob_id: String = str(row.get("id", ""))
        var power: float = float(row.get("power", 0.0))
        if mob_id == "":
            continue
        if power <= 0.0:
            continue
        power_by_mob_id[mob_id] = power

    return power_by_mob_id


static func load_stats() -> Dictionary:
    var rows: Array = _parse_prophecy_table_rows(_load_prophecy_source_text())
    var stats_by_mob_id: Dictionary = {}

    for row_any in rows:
        var row: Dictionary = row_any
        var mob_id: String = str(row.get("id", ""))
        if mob_id == "":
            continue

        var hp: int = int(row.get("hp", 0))
        var dps: int = int(row.get("dps", 0))
        if hp <= 0 and dps <= 0:
            continue

        stats_by_mob_id[mob_id] = {
            "name": str(row.get("name", mob_id)),
            "hp": hp,
            "dps": dps,
        }

    if not stats_by_mob_id.is_empty():
        return stats_by_mob_id

    return _get_cached_scene_stats()


static func _get_cached_scene_stats() -> Dictionary:
    if not _mob_stats_cache.is_empty():
        return _mob_stats_cache

    for enemy_id in MobSceneRegistryScript.MOB_SCENES_BY_ID.keys():
        var scene: PackedScene = MobSceneRegistryScript.MOB_SCENES_BY_ID.get(enemy_id, null)
        if scene == null:
            continue

        var mob_node := scene.instantiate()
        if mob_node == null:
            continue

        var hp: int = 0
        var health := mob_node.get_node_or_null("Components/Health")
        if health != null and "fixed_max_health" in health:
            hp = int(health.get("fixed_max_health"))

        var dps: int = 0
        if "mob_damage" in mob_node:
            dps = int(mob_node.get("mob_damage"))

        if hp > 0 or dps > 0:
            _mob_stats_cache[enemy_id] = {
                "name": enemy_id.replace("_", " ").capitalize(),
                "hp": hp,
                "dps": dps,
            }

        if is_instance_valid(mob_node):
            mob_node.queue_free()

    return _mob_stats_cache


static func get_enemy_info(enemy_id: String, re_hp: RegEx, re_dps: RegEx, stats_cache: Dictionary = {}) -> Dictionary:
    var info: Dictionary = parse_wiki_page(enemy_id, re_hp, re_dps)
    var merged_stats: Dictionary = stats_cache
    if merged_stats.is_empty():
        merged_stats = load_stats()

    var key := enemy_id.to_lower()
    if merged_stats.has(key):
        var stats: Dictionary = merged_stats[key]
        if String(info.get("name", "")) == "" or String(info.get("name", "")) == enemy_id:
            info["name"] = str(stats.get("name", enemy_id))
        if info.get("hp", null) == null:
            info["hp"] = stats.get("hp", null)
        if info.get("dps", null) == null:
            info["dps"] = stats.get("dps", null)

    return info


static func get_enemy_display_name(enemy_id: String, stats_cache: Dictionary = {}) -> String:
    if enemy_id == "":
        return ""

    var merged_stats: Dictionary = stats_cache
    if merged_stats.is_empty():
        merged_stats = load_stats()

    var key := enemy_id.to_lower()
    if merged_stats.has(key):
        var data: Dictionary = merged_stats[key]
        var display_name := str(data.get("name", ""))
        if display_name != "":
            return display_name

    var wiki_file_name := _enemy_id_to_wiki_filename(enemy_id)
    if wiki_file_name == "":
        return enemy_id
    return wiki_file_name.replace("_", " ")


static func get_fallback_powers() -> Dictionary:
    return FALLBACK_POWER_BY_MOB_ID.duplicate(true)


static func parse_wiki_page(enemy_id: String, re_hp: RegEx, re_dps: RegEx) -> Dictionary:
    var info: Dictionary = {"name": enemy_id, "hp": null, "dps": null}
    var file_name := _enemy_id_to_wiki_filename(enemy_id)
    if file_name == "":
        return info

    var path := _resolve_wiki_page_path(file_name)
    if path == "":
        return info

    var text := _read_text_file(path)
    if text == "":
        return info

    var header_name := _extract_md_header_name(text)
    if header_name != "":
        info["name"] = header_name

    var m_hp := re_hp.search(text)
    if m_hp and m_hp.get_group_count() >= 1:
        info["hp"] = int(m_hp.get_string(1))

    var m_dps := re_dps.search(text)
    if m_dps and m_dps.get_group_count() >= 1:
        info["dps"] = int(m_dps.get_string(1))

    return info


static func _load_prophecy_source_text() -> String:
    for path in PROPHECY_DATA_PATHS:
        var text := _read_text_file(path)
        if text != "":
            return text
    return ""


static func _resolve_wiki_page_path(file_name: String) -> String:
    for dir_path in WIKI_PAGE_DIRS:
        var path := "%s/%s.md" % [dir_path, file_name]
        if FileAccess.file_exists(path):
            return path
    return ""


static func _read_text_file(path: String) -> String:
    if path == "":
        return ""
    if not FileAccess.file_exists(path):
        return ""
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return ""
    var text := f.get_as_text()
    f.close()
    return text


static func _parse_prophecy_table_rows(text: String) -> Array:
    var rows: Array = []
    if text.strip_edges() == "":
        return rows

    var lines := text.split("\n")
    for line in lines:
        var l := String(line).strip_edges()
        if not l.begins_with("|"):
            continue
        var parts := _split_markdown_row(l)
        if parts.size() < 4:
            continue

        var mob_name := String(parts[0]).strip_edges()
        if _is_separator_or_header(mob_name):
            continue

        var hp_s := String(parts[1]).strip_edges()
        var dps_s := String(parts[2]).strip_edges()
        var power_s := String(parts[3]).strip_edges()

        if hp_s == "" or dps_s == "":
            continue

        var mob_id := _mob_name_to_id(mob_name)
        if mob_id == "":
            continue

        var row := {
            "id": mob_id,
            "name": mob_name,
            "hp": hp_s.to_int(),
            "dps": dps_s.to_int(),
            "power": power_s.to_float(),
        }
        rows.append(row)

    return rows


static func _split_markdown_row(line: String) -> Array:
    var row := line.strip_edges()
    if row.begins_with("|"):
        row = row.substr(1)
    if row.ends_with("|"):
        row = row.substr(0, row.length() - 1)
    var parts := row.split("|", false)
    for i in range(parts.size()):
        parts[i] = String(parts[i]).strip_edges()
    return parts


static func _is_separator_or_header(cell_value: String) -> bool:
    if cell_value == "":
        return true
    if cell_value == "Mob":
        return true
    var compact := cell_value.replace("-", "").strip_edges()
    return compact == ""


static func _mob_name_to_id(mob_name: String) -> String:
    var out := mob_name.strip_edges().to_lower()
    out = out.replace("-", " ")
    while out.contains("  "):
        out = out.replace("  ", " ")
    out = out.replace(" ", "_")
    return out


static func _enemy_id_to_wiki_filename(enemy_id: String) -> String:
    var parts := enemy_id.split("_", false)
    var out_parts: Array[String] = []
    for p in parts:
        if p == "":
            continue
        out_parts.append(p.substr(0, 1).to_upper() + p.substr(1, p.length() - 1))
    return "_".join(out_parts)


static func _extract_md_header_name(text: String) -> String:
    var lines := text.split("\n")
    for l in lines:
        var line := String(l).strip_edges()
        if line.begins_with("# "):
            return line.substr(2, line.length() - 2).strip_edges()
    return ""
