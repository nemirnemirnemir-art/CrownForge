extends SceneTree

const ProhesyMatesParserScript := preload("res://scripts/prophecy/modules/ProhesyMatesParser.gd")


func _init() -> void:
    print("[test_prohesy_mates_parser] Starting")

    var id1: String = ProhesyMatesParserScript._mob_name_to_id("Goblin Bandit")
    if id1 != "goblin_bandit":
        push_error("[test_prohesy_mates_parser] _mob_name_to_id failed for 'Goblin Bandit', got: " + id1)
        quit(1)
        return

    var id2: String = ProhesyMatesParserScript._mob_name_to_id("  Goblin-Pig  ")
    if id2 != "goblin_pig":
        push_error("[test_prohesy_mates_parser] _mob_name_to_id failed for '  Goblin-Pig  ', got: " + id2)
        quit(1)
        return

    var filename1: String = ProhesyMatesParserScript._enemy_id_to_wiki_filename("goblin_bandit")
    if filename1 != "Goblin_Bandit":
        push_error("[test_prohesy_mates_parser] _enemy_id_to_wiki_filename failed for 'goblin_bandit', got: " + filename1)
        quit(1)
        return

    var text1 := "# Goblin Bandit\nSome text"
    var header1: String = ProhesyMatesParserScript._extract_md_header_name(text1)
    if header1 != "Goblin Bandit":
        push_error("[test_prohesy_mates_parser] _extract_md_header_name failed for valid header, got: " + header1)
        quit(1)
        return

    var powers: Dictionary = ProhesyMatesParserScript.load_powers()
    if powers.is_empty():
        push_error("[test_prohesy_mates_parser] load_powers must return parsed data")
        quit(1)
        return
    if not powers.has("goblin_bandit"):
        push_error("[test_prohesy_mates_parser] load_powers missing goblin_bandit")
        quit(1)
        return
    var goblin_bandit_power: float = float(powers["goblin_bandit"])
    if not is_equal_approx(goblin_bandit_power, 15.0):
        push_error("[test_prohesy_mates_parser] goblin_bandit power must be 15.0, got: %f" % goblin_bandit_power)
        quit(1)
        return

    var stats: Dictionary = ProhesyMatesParserScript.load_stats()
    if stats.is_empty():
        push_error("[test_prohesy_mates_parser] load_stats must return parsed data")
        quit(1)
        return
    if not stats.has("goblin_bandit"):
        push_error("[test_prohesy_mates_parser] load_stats missing goblin_bandit")
        quit(1)
        return
    var goblin_bandit_stats: Dictionary = stats["goblin_bandit"]
    if int(goblin_bandit_stats.get("hp", -1)) != 50:
        push_error("[test_prohesy_mates_parser] goblin_bandit hp must be 50")
        quit(1)
        return
    if int(goblin_bandit_stats.get("dps", -1)) != 7:
        push_error("[test_prohesy_mates_parser] goblin_bandit dps must be 7")
        quit(1)
        return

    var re_hp := RegEx.new()
    var re_dps := RegEx.new()
    re_hp.compile("(?is)\\bHP\\b\\s*:?\\s*(\\d+)")
    re_dps.compile("(?is)(?:\\bDPS\\b|Damage\\s+per\\s+second)\\s*:?\\s*(\\d+)")
    var wiki_info: Dictionary = ProhesyMatesParserScript.parse_wiki_page("goblin_bandit", re_hp, re_dps)
    if String(wiki_info.get("name", "")) != "Goblin Bandit":
        push_error("[test_prohesy_mates_parser] parse_wiki_page name mismatch for goblin_bandit")
        quit(1)
        return
    if int(wiki_info.get("hp", -1)) != 50:
        push_error("[test_prohesy_mates_parser] parse_wiki_page hp mismatch for goblin_bandit")
        quit(1)
        return
    if int(wiki_info.get("dps", -1)) != 7:
        push_error("[test_prohesy_mates_parser] parse_wiki_page dps mismatch for goblin_bandit")
        quit(1)
        return

    print("[test_prohesy_mates_parser] PASS")
    quit(0)
