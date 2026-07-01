extends Resource
class_name ProphecyPattern

enum RewardType {
	DENARII,
	RESOURCE,
	BASIC_PRODUCTION,
	ESTABLISHED_PRODUCTION,
	ADVANCED_PRODUCTION,
	LEVY_BARRACKS,
	VETERAN_BARRACKS,
	ELITE_BARRACKS,
	KINGDOM_INFRASTRUCTURE,
	ARTIFACT,
	LEGENDARY_ARTIFACT,
	SPELL,
	LEGENDARY_SPELL,
	BUILDING_UPGRADE,
	TROOP_TRAINING,
	PROPHECY
}

enum DifficultyTier {
	EASY,
	MID,
	HARD
}

@export var weight: int = 1
@export var power_rating: float = 0.0
@export var difficulty_tier: DifficultyTier = DifficultyTier.MID

@export_group("Metadata")
@export var level_min: int = 1
@export var level_max: int = 7
@export var family: String = ""
@export var reward_bias: String = ""
@export var primary_role: String = ""
@export var secondary_role: String = ""
@export var is_rare_strong: bool = false
@export var tags: Array[String] = []

@export_group("Mobs")
@export var mob_1_id: String = "goblin_bandit"
@export var mob_1_count: int = 1
@export var mob_2_enabled: bool = false
@export var mob_2_id: String = ""
@export var mob_2_count: int = 1

@export_group("Rewards")
@export var reward_1_type: RewardType = RewardType.DENARII
@export var reward_1_amount: int = 10
@export var reward_2_enabled: bool = false
@export var reward_2_type: RewardType = RewardType.DENARII
@export var reward_2_amount: int = 10
