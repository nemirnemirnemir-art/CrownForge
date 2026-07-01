extends RefCounted
class_name RerollCost

static func get_next_reroll_cost(rerolls_done: int) -> int:
	var next_index := rerolls_done + 1
	if next_index <= 1:
		return 10
	return (next_index - 1) * 30
