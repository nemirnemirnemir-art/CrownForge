extends Resource
class_name BuildingConfig

## BuildingConfig - Resource used for building configuration
## Edited directly in the Godot inspector

enum BuildingType {
	MILITARY,   ## Produces units
	RESOURCE,   ## Produces resources
	SPECIAL     ## Special behavior (code)
}

enum BuildingCategory {
	BASIC_PRODUCTION,
	ESTABLISHED_PRODUCTION,
	ADVANCED_PRODUCTION,
	LEVY_BARRACKS,
	VETERAN_BARRACKS,
	ELITE_BARRACKS,
	KINGDOM_INFRASTRUCTURE,
	OTHER
}

## === MAIN SETTINGS ===
@export_group("Basic Info")
@export var building_id: String = ""
@export var display_name: String = "New Building"
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var use_vzor_animation: bool = false
@export var vzor_frames: SpriteFrames = null
@export var vzor_animation_name: StringName = &"default"

## === BUILDING TYPE ===
@export_group("Building Type")
@export var building_type: BuildingType = BuildingType.RESOURCE
@export var building_category: BuildingCategory = BuildingCategory.BASIC_PRODUCTION

## === BUILD COST ===
@export_group("Build Cost")
@export var build_costs: Array[BuildingCostEntry] = []

## === PRODUCTION ===
@export_group("Production")
@export var cycle_time: float = 1.0  ## One production cycle time in seconds

## For RESOURCE buildings - what it produces
@export var produces: Array[BuildingProductionEntry] = []

## For RESOURCE buildings - what it consumes (optional)
@export var consumes: Array[BuildingProductionEntry] = []

## === MILITARY SETTINGS ===
@export_group("Military (Unit Production)")
@export var produced_unit_id: String = ""  ## Unit ID to produce
@export var max_units: int = 3  ## Maximum number of units from this building

## === SPECIAL SETTINGS ===
@export_group("Special Behavior")
@export var has_special_behavior: bool = false
@export var special_script_path: String = ""  ## Path to special behavior script

## Get icon or placeholder
func get_icon_or_placeholder() -> Texture2D:
	if icon != null:
		return icon
	if use_vzor_animation and vzor_frames != null:
		var anim_name := StringName(vzor_animation_name)
		if anim_name == StringName():
			anim_name = &"default"
		if vzor_frames.has_animation(anim_name):
			var count := vzor_frames.get_frame_count(anim_name)
			if count > 0:
				return vzor_frames.get_frame_texture(anim_name, 0)
	# Return null - MapSlot will create a placeholder
	return null

## Check if the player can afford the building
func can_afford() -> bool:
	var mult := 1.0
	var resource_core := _get_resource_core()
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		var artifact_core := tree.root.get_node_or_null("ArtifactCore")
		if artifact_core != null and artifact_core.has_method("get_build_cost_multiplier"):
			mult = float(artifact_core.call("get_build_cost_multiplier"))
	for cost in build_costs:
		if cost == null:
			continue
		var amount := cost.amount
		if mult != 1.0:
			amount = int(round(float(amount) * mult))
			if cost.amount > 0 and amount < 1:
				amount = 1
		var current := int(resource_core.call("get_resource", cost.resource_id)) if resource_core != null else 0
		if current < amount:
			return false
	return true

## Spend resources to build
func pay_build_cost() -> bool:
	if not can_afford():
		return false
	var mult := 1.0
	var resource_core := _get_resource_core()
	var tree := Engine.get_main_loop() as SceneTree
	var artifact_core: Node = null
	if tree:
		artifact_core = tree.root.get_node_or_null("ArtifactCore")
		if artifact_core != null and artifact_core.has_method("get_build_cost_multiplier"):
			mult = float(artifact_core.call("get_build_cost_multiplier"))
	var paid_costs: Array[Dictionary] = []
	for cost in build_costs:
		if cost == null:
			continue
		var amount := cost.amount
		if mult != 1.0:
			amount = int(round(float(amount) * mult))
			if cost.amount > 0 and amount < 1:
				amount = 1
		if resource_core != null:
			resource_core.call("consume_resource", cost.resource_id, amount)
		paid_costs.append({"resource_id": cost.resource_id, "amount": amount})
	if artifact_core != null and artifact_core.has_method("apply_build_refund"):
		artifact_core.call("apply_build_refund", paid_costs)
	return true

## Check if there are input resources available for production
func can_produce() -> bool:
	var resource_core := _get_resource_core()
	for consume in consumes:
		if consume == null:
			continue
		var current := int(resource_core.call("get_resource", consume.resource_id)) if resource_core != null else 0
		if current < consume.amount:
			return false
	return true

## Consume input resources
func consume_inputs() -> void:
	var resource_core := _get_resource_core()
	for consume in consumes:
		if consume == null:
			continue
		if resource_core != null:
			resource_core.call("consume_resource", consume.resource_id, consume.amount)

## Grant produced outputs
func produce_outputs() -> void:
	var resource_core := _get_resource_core()
	for produce in produces:
		if produce == null:
			continue
		if resource_core != null:
			resource_core.call("add_resource", produce.resource_id, produce.amount)

func _get_resource_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ResourceCore")
