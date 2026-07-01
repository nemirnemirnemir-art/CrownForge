extends SceneTree

const SCENE_PATHS: Array[String] = [
	"res://scenes/spells/effects/ArmageddonEffect.tscn",
	"res://scenes/spells/effects/BanishEffect.tscn",
	"res://scenes/spells/effects/BladecasterEffect.tscn",
	"res://scenes/spells/effects/BladefallEffect.tscn",
	"res://scenes/spells/effects/BlindingLightEffect.tscn",
	"res://scenes/spells/effects/BurstingBunchEffect.tscn",
	"res://scenes/spells/effects/BurstingGuy.tscn",
	"res://scenes/spells/effects/ChainLightningEffect.tscn",
	"res://scenes/effects/DeforestationEffect.tscn",
	"res://scenes/spells/effects/EvasionEffect.tscn",
	"res://scenes/spells/effects/FallingBlade.tscn",
	"res://scenes/spells/effects/FireballEffect.tscn",
	"res://scenes/spells/effects/FireworksEffect.tscn",
	"res://scenes/spells/effects/FreezeEffect.tscn",
	"res://scenes/spells/effects/FissureEffect.tscn",
	"res://scenes/spells/effects/FrailtyEffect.tscn",
	"res://scenes/spells/effects/GroundfireEffect.tscn",
	"res://scenes/mobs/effects/FireFromDragon.tscn",
	"res://scenes/spells/effects/HealingPoolEffect.tscn",
	"res://scenes/spells/effects/ImmortalityEffect.tscn",
	"res://scenes/spells/effects/IncinerationEffect.tscn",
	"res://scenes/spells/effects/InfernalUnit.tscn",
	"res://scenes/spells/effects/LandmineEffect.tscn",
	"res://scenes/spells/effects/LandmineSpawner.tscn",
	"res://scenes/spells/effects/MeteoriteEffect.tscn",
	"res://scenes/spells/effects/MoonshineBarrelEffect.tscn",
	"res://scenes/spells/effects/NecromancyEffect.tscn",
	"res://scenes/spells/effects/PoisonPuddleEffect.tscn",
	"res://scenes/spells/effects/QuicksandEffect.tscn",
	"res://scenes/spells/effects/LastStandEffect.tscn",
	"res://scenes/spells/effects/RootsEffect.tscn",

	"res://scenes/spells/effects/ShieldsUpEffect.tscn",
	"res://scenes/spells/effects/SummonInfernalsEffect.tscn",
	"res://scenes/spells/effects/ThunderstormEffect.tscn",
	"res://scenes/spells/effects/TNTBarrelEffect.tscn",
	"res://scenes/spells/effects/TornadoEffect.tscn",
	"res://scenes/spells/effects/TurnToSheepEffect.tscn",
	"res://scenes/spells/effects/WeaknessEffect.tscn",
	"res://scenes/spells/effects/WrathEffect.tscn",
]


func _init() -> void:
	
	var all_ok = true
	for path in SCENE_PATHS:
		var scene = load(path)
		if scene == null:
			printerr("FAILED to load: ", path)
			all_ok = false
		else:
			print("SUCCESS: Loaded ", path)
	
	if all_ok:
		print("VERIFICATION COMPLETE: All scenes loaded successfully.")
		quit(0)
	else:
		printerr("VERIFICATION FAILED: Some scenes could not be loaded.")
		quit(1)
