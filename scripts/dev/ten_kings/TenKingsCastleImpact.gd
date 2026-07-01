extends Node2D
## Castle impact splash effect with 3 damage zones and editable radii.
##
## Responsible for:
## - Holding the visual ring effect data (exported properties)
## - Computing splash damage falloff based on distance from impact center
## - Spawning the visual effect (3 gray rings in rapid sequence)

## Exported properties for scene editor customization
@export var inner_radius: float = 80.0
@export var middle_radius: float = 150.0
@export var outer_radius: float = 220.0

@export var inner_multiplier: float = 1.0		# 100% damage
@export var middle_multiplier: float = 0.5		# 50% damage
@export var outer_multiplier: float = 0.25		# 25% damage

## Timing for ring reveal (in seconds between rings)
@export var ring_reveal_delay: float = 0.05

## Compute splash damage multiplier based on distance from impact center
func get_splash_multiplier(distance: float) -> float:
	if distance <= inner_radius:
		return inner_multiplier
	elif distance <= middle_radius:
		return middle_multiplier
	elif distance <= outer_radius:
		return outer_multiplier
	else:
		return 0.0


## Get all three ring radii as an array
func get_ring_radii() -> Array:
	return [inner_radius, middle_radius, outer_radius]


## Get all three multipliers as an array
func get_ring_multipliers() -> Array:
	return [inner_multiplier, middle_multiplier, outer_multiplier]
