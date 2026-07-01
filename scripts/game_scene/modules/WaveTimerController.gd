extends RefCounted
class_name WaveTimerController

## Handles preview payload building for WaveTimerBar

const RewardPresentationRegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")
const FIRST_WAVE_DELAY_SEC := 100.0
const PROPHECY_WAVE_INTERVAL_SEC := 60.0
const POST_TRADER_NEXT_CYCLE_DELAY_SEC := 90.0

func get_wave_interval_for_number(wave_number: int, trader_wave_number: int, post_trader_first_wave_number: int) -> float:
    if wave_number < 0:
        return 0.0
    if wave_number == 0:
        return FIRST_WAVE_DELAY_SEC

    if trader_wave_number >= 0:
        if wave_number == trader_wave_number:
            return PROPHECY_WAVE_INTERVAL_SEC
        if wave_number == (trader_wave_number + 1):
            return POST_TRADER_NEXT_CYCLE_DELAY_SEC

    if post_trader_first_wave_number > 0 and wave_number == post_trader_first_wave_number:
        return POST_TRADER_NEXT_CYCLE_DELAY_SEC

    return PROPHECY_WAVE_INTERVAL_SEC

func build_preview_payload(patterns: Array, display_wave_number: int, aggregate_func: Callable) -> Dictionary:
    var counts: Dictionary = aggregate_func.call(patterns)
    var primary_id: String = "goblin_bandit"
    var primary_count: int = 1
    for enemy_id in counts.keys():
        var cnt: int = int(counts[enemy_id])
        if cnt > primary_count or primary_id == "":
            primary_id = String(enemy_id)
            primary_count = max(1, cnt)
            
    var title: String = "Prophecy"
    var flag_label: String = ""
    if display_wave_number > 0:
        title = "Wave %d" % display_wave_number
        flag_label = "%d" % display_wave_number
        
    return {
        "enemy_id": primary_id,
        "enemy_count": primary_count,
        "mob_counts": counts,
        "wave_title": title,
        "display_wave_number": display_wave_number,
        "flag_label": flag_label,
        "rewards": build_rewards_tooltip_payload(patterns),
    }

func build_prophecy_marker_payload(prophecy_level: int, patterns: Array = [], rewards: Array = [], aggregate_func: Callable = Callable()) -> Dictionary:
    var counts: Dictionary = {}
    if aggregate_func.is_valid():
        counts = aggregate_func.call(patterns)
    var tooltip_rewards: Array = []
    for reward in rewards:
        if typeof(reward) != TYPE_DICTIONARY:
            continue
        var reward_dict: Dictionary = reward as Dictionary
        tooltip_rewards.append(reward_to_tooltip_dict(int(reward_dict.get("type", -1)), int(reward_dict.get("amount", 1))))
    return {
        "wave_title": "Prophecy %d" % prophecy_level,
        "flag_label": "P%d" % prophecy_level,
        "mob_counts": counts,
        "rewards": tooltip_rewards,
    }

func build_boss_preview_payload(patterns: Array, aggregate_func: Callable) -> Dictionary:
    var counts: Dictionary = aggregate_func.call(patterns)
    var primary_id: String = "goblin_giant"
    var primary_count: int = 1
    for enemy_id in counts.keys():
        var cnt: int = int(counts[enemy_id])
        if cnt > primary_count or primary_id == "":
            primary_id = String(enemy_id)
            primary_count = max(1, cnt)
    return {
        "enemy_id": primary_id,
        "enemy_count": primary_count,
        "mob_counts": counts,
        "wave_title": "Boss",
        "flag_label": "B",
        "rewards": build_rewards_tooltip_payload(patterns),
    }

func build_rewards_tooltip_payload(patterns: Array) -> Array:
    var result: Array = [reward_to_tooltip_dict(0, 10)]
    if patterns == null:
        return result
    for p in patterns:
        if p == null:
            continue
        result.append(reward_to_tooltip_dict(int(p.reward_1_type), int(p.reward_1_amount)))
        if bool(p.reward_2_enabled):
            result.append(reward_to_tooltip_dict(int(p.reward_2_type), int(p.reward_2_amount)))
    return result

func reward_to_tooltip_dict(t: int, amount: int) -> Dictionary:
    var reward_icon: Texture2D = RewardPresentationRegistryScript.get_reward_icon(t)
    var reward_name: String = RewardPresentationRegistryScript.get_reward_display_name(t)
    if reward_name == "Reward":
        reward_name = ""

    if t == 0: # ProphecyPattern.RewardType.DENARII
        return {"label": "x%d %s" % [amount, reward_name], "icon": reward_icon}
    if t == 1: # ProphecyPattern.RewardType.RESOURCE
        return {"label": "x%d %s" % [amount, reward_name], "icon": reward_icon}
    if reward_name != "":
        return {"label": reward_name, "icon": reward_icon}
    return {"label": "Reward"}
