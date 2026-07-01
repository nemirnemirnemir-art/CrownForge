extends RefCounted
class_name ProphecyBalancer

## Handles mathematical logic for generating valid mob count patterns and calculating weights

const MAX_MOBS_PER_PATTERN: int = 20

var _rng: RandomNumberGenerator

func setup(rng: RandomNumberGenerator) -> void:
    _rng = rng

func compute_single_count(unit_power: float, accept_min: float, accept_max: float) -> int:
    if unit_power <= 0.0:
        return 0
    var target: float = _rng.randf_range(accept_min, accept_max)
    var approx := int(round(target / unit_power))
    return clamp(approx, 1, MAX_MOBS_PER_PATTERN)

func find_best_counts_for_two(p1: float, p2: float, accept_min: float, accept_max: float) -> Dictionary:
    var target: float = _rng.randf_range(accept_min, accept_max)
    var best_err := 999999.0
    var best_c1 := 0
    var best_c2 := 0
    
    for c1 in range(1, MAX_MOBS_PER_PATTERN + 1):
        for c2 in range(1, MAX_MOBS_PER_PATTERN + 1 - c1):
            var total: float = p1 * float(c1) + p2 * float(c2)
            if total < accept_min or total > accept_max:
                continue
            var err: float = abs(total - target)
            if err < best_err:
                best_err = err
                best_c1 = c1
                best_c2 = c2
    
    if best_c1 <= 0 or best_c2 <= 0:
        return {}
    return {"c1": best_c1, "c2": best_c2}

func is_pair_allowed(is_r1: bool, is_r2: bool) -> bool:
    if is_r1 and not is_r2:
        return true
    if is_r2 and not is_r1:
        return true
    if is_r1 and is_r2:
        return true
    return true

func is_power_mix_ok(p1: float, p2: float) -> bool:
    if p1 <= 0.0 or p2 <= 0.0:
        return false
    var hi: float = p2
    var lo: float = p1
    if p1 >= p2:
        hi = p1
        lo = p2
    if lo <= 0.0:
        return false
    return (hi / lo) <= 3.0
