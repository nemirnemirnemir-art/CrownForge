extends Resource
class_name UnitUpgradeConfig

## UnitUpgradeConfig - Resource for unit upgrade data
## Based on wiki data from thekingiswatching.wiki.gg

## === BASIC INFO ===
@export_group("Basic Info")
@export var upgrade_id: String = ""
@export var display_name: String = "New Upgrade"
@export_multiline var description: String = ""
@export var icon: Texture2D = null

## === UNLOCK ===
@export_group("Unlock")
@export var required_building_level: int = 1
@export var is_unlocked: bool = false
