extends RefCounted
class_name ProphecyWaveGenerator

const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")
const ProphecyEnemyPoolScript := preload("res://scripts/prophecy/modules/ProphecyEnemyPool.gd")
const ProphecyRewardPoolScript := preload("res://scripts/prophecy/modules/ProphecyRewardPool.gd")
const ProphecyBalancerScript := preload("res://scripts/prophecy/modules/ProphecyBalancer.gd")
const ProhesyMatesParserScript := preload("res://scripts/prophecy/modules/ProhesyMatesParser.gd")

const PROPHECY_RANGES: Dictionary = {
    1: {"min": 30.0, "max": 60.0},
    2: {"min": 60.0, "max": 95.0},
    3: {"min": 95.0, "max": 135.0},
    4: {"min": 135.0, "max": 185.0},
    5: {"min": 185.0, "max": 250.0},
    6: {"min": 250.0, "max": 340.0},
    7: {"min": 340.0, "max": 470.0},
}

var _rng: RandomNumberGenerator

var _enemy_pool: ProphecyEnemyPool
var _reward_pool: ProphecyRewardPool
var _balancer: ProphecyBalancer

var _remaining_patterns: int = 0
var _wall_buster_quota: int = 0
var _swarm_quota: int = 0

func setup(rng: RandomNumberGenerator, total_patterns: int, prophecy_level: int) -> void:
    _rng = rng
    _remaining_patterns = max(0, total_patterns)
    _wall_buster_quota = 0
    _swarm_quota = 0
    
    if prophecy_level >= 7 and _remaining_patterns > 0:
        _wall_buster_quota = int(floor(float(_remaining_patterns) * 0.10))
        _swarm_quota = int(floor(float(_remaining_patterns) * 0.25))
    
    _enemy_pool = ProphecyEnemyPoolScript.new()
    var powers = ProhesyMatesParserScript.load_powers()
    if powers.is_empty():
        powers = ProhesyMatesParserScript.get_fallback_powers()
    _enemy_pool.setup(powers)

    _reward_pool = ProphecyRewardPoolScript.new()
    _reward_pool.setup(_rng)

    _balancer = ProphecyBalancerScript.new()
    _balancer.setup(_rng)

func generate_pattern(prophecy_level: int) -> ProphecyPattern:
    var lvl: int = clamp(prophecy_level, 1, 7)
    var range_d: Dictionary = PROPHECY_RANGES.get(lvl, PROPHECY_RANGES[1])
    var min_p: float = float(range_d.get("min", 30.0))
    var max_p: float = float(range_d.get("max", 135.0))
    var accept_min: float = min_p * 0.8
    var accept_max: float = max_p * 1.2
    if lvl == 1:
        accept_min = min_p
        accept_max = max_p

    var generated: ProphecyPattern = null
    if lvl <= 1 and _rng and _rng.randf() < 0.32:
        var intro_pattern := _make_intro_variety_pattern(lvl, accept_min, accept_max)
        if intro_pattern != null:
            _remaining_patterns = max(0, _remaining_patterns - 1)
            _stamp_pattern_metadata(intro_pattern)
            return intro_pattern
    var special := _pick_special_kind(lvl)
    if special == "wall_buster_20":
        _remaining_patterns = max(0, _remaining_patterns - 1)
        generated = _make_wall_buster_20_pattern()
    elif special == "swarm":
        _remaining_patterns = max(0, _remaining_patterns - 1)
        generated = _make_swarm_pattern(lvl, accept_min, accept_max)
    else:
        var reserved: int = _wall_buster_quota + _swarm_quota
        if _enemy_pool.has_slug_pool(lvl) and _remaining_patterns > reserved and _rng.randf() < 0.18:
            _remaining_patterns = max(0, _remaining_patterns - 1)
            generated = _make_slug_pattern(lvl, accept_min, accept_max)
        else:
            _remaining_patterns = max(0, _remaining_patterns - 1)
            generated = _make_normal_pattern(lvl, accept_min, accept_max)

    _stamp_pattern_metadata(generated)
    return generated

func _stamp_pattern_metadata(pattern: ProphecyPattern) -> void:
    if pattern == null:
        return
    pattern.power_rating = _compute_pattern_power(pattern)


func get_level_power_range(prophecy_level: int) -> Dictionary:
    var lvl: int = clamp(prophecy_level, 1, 7)
    return (PROPHECY_RANGES.get(lvl, PROPHECY_RANGES[1]) as Dictionary).duplicate(true)

func _compute_pattern_power(pattern: ProphecyPattern) -> float:
    if pattern == null:
        return 0.0
    var total := 0.0
    if pattern.mob_1_id != "":
        total += _enemy_pool.get_power(pattern.mob_1_id) * float(pattern.mob_1_count)
    if pattern.mob_2_enabled and pattern.mob_2_id != "":
        total += _enemy_pool.get_power(pattern.mob_2_id) * float(pattern.mob_2_count)
    return total

func _make_slug_pattern(prophecy_level: int, accept_min: float, accept_max: float) -> ProphecyPattern:
    var pool := _enemy_pool.build_slug_pool(prophecy_level)
    if pool.is_empty():
        return _make_normal_pattern(prophecy_level, accept_min, accept_max)
    
    for _attempt in range(60):
        var mob_id := String(pool[_rng.randi_range(0, pool.size() - 1)])
        if mob_id == "":
            continue
        var power := _enemy_pool.get_power(mob_id)
        if power <= 0.0:
            continue
        var count := _balancer.compute_single_count(power, accept_min, accept_max)
        if count <= 0:
            continue
        var total_power := power * float(count)
        if total_power < accept_min or total_power > accept_max:
            continue
        var p := ProphecyPatternScript.new() as ProphecyPattern
        p.weight = 1
        p.mob_1_id = mob_id
        p.mob_1_count = count
        p.mob_2_enabled = false
        _reward_pool.apply_rewards(p, prophecy_level, total_power)
        return p
    
    return _make_normal_pattern(prophecy_level, accept_min, accept_max)

func _pick_special_kind(prophecy_level: int) -> String:
    if _remaining_patterns <= 0:
        return ""
    
    if prophecy_level >= 7 and _wall_buster_quota > 0:
        var chance := float(_wall_buster_quota) / float(_remaining_patterns)
        if _rng.randf() <= chance:
            _wall_buster_quota -= 1
            return "wall_buster_20"
    
    if prophecy_level >= 7 and _swarm_quota > 0:
        var chance2 := float(_swarm_quota) / float(_remaining_patterns)
        if _rng.randf() <= chance2:
            _swarm_quota -= 1
            return "swarm"
    
    return ""

func _make_wall_buster_20_pattern() -> ProphecyPattern:
    var p := ProphecyPatternScript.new() as ProphecyPattern
    p.weight = 1
    p.mob_1_id = "wall_buster"
    p.mob_1_count = 20
    p.mob_2_enabled = false
    p.reward_1_type = ProphecyPatternScript.RewardType.DENARII
    p.reward_1_amount = 30
    p.reward_2_enabled = false
    return p

func _make_swarm_pattern(prophecy_level: int, accept_min: float, accept_max: float) -> ProphecyPattern:
    var pool := _enemy_pool.build_swarm_pool(prophecy_level)
    if pool.is_empty():
        return _make_normal_pattern(prophecy_level, accept_min, accept_max)
    
    for _attempt in range(60):
        var mob_id := String(pool[_rng.randi_range(0, pool.size() - 1)])
        if mob_id == "":
            continue
        if _enemy_pool.is_slug(mob_id):
            continue
        
        var power := _enemy_pool.get_power(mob_id)
        if power <= 0.0:
            continue
        
        var count := _rng.randi_range(14, 20)
        var total_power := power * float(count)
        if total_power < accept_min or total_power > accept_max:
            continue
        
        if _enemy_pool.is_ranged(mob_id):
            continue
        
        var p := ProphecyPatternScript.new() as ProphecyPattern
        p.weight = 1
        p.mob_1_id = mob_id
        p.mob_1_count = count
        p.mob_2_enabled = false
        _reward_pool.apply_rewards(p, prophecy_level, total_power)
        return p
    
    return _make_normal_pattern(prophecy_level, accept_min, accept_max)

func _make_normal_pattern(prophecy_level: int, accept_min: float, accept_max: float) -> ProphecyPattern:
    var pool := _enemy_pool.build_mob_pool(prophecy_level)
    if pool.is_empty():
        return _make_level_fallback(prophecy_level)
    
    for _attempt in range(80):
        var want_two_types: bool = _rng.randf() < 0.55
        
        var mob1 := String(pool[_rng.randi_range(0, pool.size() - 1)])
        if mob1 == "":
            continue
        if _enemy_pool.is_slug(mob1) and want_two_types:
            continue
        var p1 := _enemy_pool.get_power(mob1)
        if p1 <= 0.0:
            continue
        
        if not want_two_types:
            if _enemy_pool.is_ranged(mob1):
                continue
            var count1 := _balancer.compute_single_count(p1, accept_min, accept_max)
            if count1 <= 0:
                continue
            var total_power := p1 * float(count1)
            if total_power < accept_min or total_power > accept_max:
                continue
            var pat := ProphecyPatternScript.new() as ProphecyPattern
            pat.weight = 1
            pat.mob_1_id = mob1
            pat.mob_1_count = count1
            pat.mob_2_enabled = false
            _reward_pool.apply_rewards(pat, prophecy_level, total_power)
            return pat
        
        var mob2 := String(pool[_rng.randi_range(0, pool.size() - 1)])
        if mob2 == "" or mob2 == mob1:
            continue
        if _enemy_pool.is_slug(mob2):
            continue
        var p2 := _enemy_pool.get_power(mob2)
        if p2 <= 0.0:
            continue
        
        if not _balancer.is_pair_allowed(_enemy_pool.is_ranged(mob1), _enemy_pool.is_ranged(mob2)):
            continue
        if not _balancer.is_power_mix_ok(p1, p2):
            continue
        
        var best := _balancer.find_best_counts_for_two(p1, p2, accept_min, accept_max)
        if best.is_empty():
            continue
        
        var c1: int = int(best.get("c1", 0))
        var c2: int = int(best.get("c2", 0))
        if c1 <= 0 or c2 <= 0:
            continue
        if c1 + c2 > _balancer.MAX_MOBS_PER_PATTERN:
            continue
        
        var total_power2 := p1 * float(c1) + p2 * float(c2)
        if total_power2 < accept_min or total_power2 > accept_max:
            continue
        
        var pat2 := ProphecyPatternScript.new() as ProphecyPattern
        pat2.weight = 1
        pat2.mob_1_id = mob1
        pat2.mob_1_count = c1
        pat2.mob_2_enabled = true
        pat2.mob_2_id = mob2
        pat2.mob_2_count = c2
        _reward_pool.apply_rewards(pat2, prophecy_level, total_power2)
        return pat2
    
    return _make_level_fallback(prophecy_level)

func _make_intro_variety_pattern(prophecy_level: int, accept_min: float, accept_max: float) -> ProphecyPattern:
    var blueprints: Array = [
        {
            "mob_1_id": "wall_buster",
            "mob_1_count": 2,
            "bonus_reward_types": [
                ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE,
                ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION,
                ProphecyPatternScript.RewardType.TROOP_TRAINING,
            ],
        },
        {
            "mob_1_id": "goblin_bandit",
            "mob_1_count": 1,
            "mob_2_id": "goblin_crossbowman",
            "mob_2_count": 1,
        },
        {
            "mob_1_id": "goblin_bandit",
            "mob_1_count": 6,
            "bonus_reward_types": [
                ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE,
                ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION,
                ProphecyPatternScript.RewardType.VETERAN_BARRACKS,
                ProphecyPatternScript.RewardType.TROOP_TRAINING,
            ],
        },
        {
            "mob_1_id": "goblin_swordsman",
            "mob_1_count": 2,
            "mob_2_id": "goblin_crossbowman",
            "mob_2_count": 1,
        },
        {
            "mob_1_id": "goblin_bandit",
            "mob_1_count": 2,
            "mob_2_id": "goblin_swordsman",
            "mob_2_count": 1,
        },
        {
            "mob_1_id": "goblin_crossbowman",
            "mob_1_count": 1,
            "mob_2_id": "goblin_swordsman",
            "mob_2_count": 2,
        },
    ]
    if _rng:
        blueprints.shuffle()
    for raw_blueprint in blueprints:
        var blueprint := raw_blueprint as Dictionary
        var pattern := _build_pattern_from_blueprint(blueprint, prophecy_level, accept_min, accept_max)
        if pattern != null:
            return pattern
    return null

func _build_pattern_from_blueprint(blueprint: Dictionary, prophecy_level: int, accept_min: float, accept_max: float) -> ProphecyPattern:
    var mob_1_id := String(blueprint.get("mob_1_id", "")).strip_edges().to_lower()
    var mob_1_count := int(blueprint.get("mob_1_count", 0))
    if mob_1_id == "" or mob_1_count <= 0:
        return null
    var power_1 := _enemy_pool.get_power(mob_1_id)
    if power_1 <= 0.0:
        return null

    var mob_2_id := String(blueprint.get("mob_2_id", "")).strip_edges().to_lower()
    var mob_2_count := int(blueprint.get("mob_2_count", 0))
    var total_power := power_1 * float(mob_1_count)
    if mob_2_id != "":
        var power_2 := _enemy_pool.get_power(mob_2_id)
        if power_2 <= 0.0 or mob_2_count <= 0:
            return null
        total_power += power_2 * float(mob_2_count)

    var relaxed_min := accept_min * 0.72
    var relaxed_max := accept_max * 1.18
    if total_power < relaxed_min or total_power > relaxed_max:
        return null
    if mob_1_count + mob_2_count > _balancer.MAX_MOBS_PER_PATTERN:
        return null

    var pattern := ProphecyPatternScript.new() as ProphecyPattern
    pattern.weight = 1
    pattern.mob_1_id = mob_1_id
    pattern.mob_1_count = mob_1_count
    pattern.mob_2_enabled = mob_2_id != ""
    pattern.mob_2_id = mob_2_id
    pattern.mob_2_count = mob_2_count
    _reward_pool.apply_rewards(pattern, prophecy_level, total_power)

    var bonus_reward_types := blueprint.get("bonus_reward_types", []) as Array
    if bonus_reward_types != null and not bonus_reward_types.is_empty():
        _apply_intro_bonus_reward(pattern, bonus_reward_types)
    return pattern

func _apply_intro_bonus_reward(pattern: ProphecyPattern, reward_types: Array) -> void:
    if pattern == null or reward_types == null or reward_types.is_empty():
        return
    if _rng == null:
        return
    var reward_index := _rng.randi_range(0, reward_types.size() - 1)
    pattern.reward_1_type = int(reward_types[reward_index])
    pattern.reward_1_amount = 1
    pattern.reward_2_enabled = false

func _make_level_fallback(prophecy_level: int) -> ProphecyPattern:
    var lvl: int = clamp(prophecy_level, 1, 7)
    var range_d: Dictionary = PROPHECY_RANGES.get(lvl, PROPHECY_RANGES[1])
    var target_min: float = float(range_d.get("min", 30.0))

    var fallback_id := "goblin_bandit"
    var fallback_power: float = _enemy_pool.get_power(fallback_id)
    var pool := _enemy_pool.build_mob_pool(lvl)
    if _rng:
        pool.shuffle()
    for mob_id in pool:
        var candidate_id := String(mob_id)
        if candidate_id == "":
            continue
        if _enemy_pool.is_ranged(candidate_id):
            continue
        var candidate_power := _enemy_pool.get_power(candidate_id)
        if candidate_power <= 0.0:
            continue
        fallback_id = candidate_id
        fallback_power = candidate_power
        break

    if fallback_power <= 0.0:
        fallback_power = 15.0

    var count: int = clampi(int(ceili(target_min / fallback_power)), 1, _balancer.MAX_MOBS_PER_PATTERN)
    var fallback := ProphecyPatternScript.new() as ProphecyPattern
    fallback.mob_1_id = fallback_id
    fallback.mob_1_count = count
    fallback.mob_2_enabled = false
    _reward_pool.apply_rewards(fallback, prophecy_level, fallback_power * float(count))
    return fallback
