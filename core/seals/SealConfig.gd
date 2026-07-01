extends Resource
class_name SealConfig

enum SealTier {
	CURSED = 0,
	NORMAL = 1,
	EPIC = 2,
	LEGENDARY = 3
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var tier: SealTier = SealTier.NORMAL
@export var production_modifier: float = 0.0 # 0.20 = +20%, -0.25 = -25%
@export var cost: Dictionary = {} # {"crystal": 100}
@export var icon: Texture2D = null
@export var color: Color = Color.WHITE

func get_cost_text() -> String:
	if cost.is_empty():
		return "Free"
	var parts = []
	for res in cost:
		parts.append("%d %s" % [cost[res], res.capitalize()])
	return ", ".join(parts)
