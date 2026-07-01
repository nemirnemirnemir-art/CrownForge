extends RefCounted
class_name MobSceneRegistry

const GOBLIN_IDS: Array[String] = [
    "goblin_bandit", "blue_slime", "goblin_crossbowman", "goblin_swordsman",
    "goblin_shaman", "goblin_fire_mage", "goblin_lightning_mage", "goblin_lizard",
    "goblin_giant", "wall_buster", "goblin_bat_rider", "goblin_pig",
    "crab_rider", "stone_golem", "sunfaced"
]

const GOBLIN_SCENES: Array[PackedScene] = [
    preload("res://scenes/mobs/GoblinBandit.tscn"),
    preload("res://scenes/mobs/BlueSlime.tscn"),
    preload("res://scenes/mobs/GoblinCrossbowman.tscn"),
    preload("res://scenes/mobs/GoblinSwordsman.tscn"),
    preload("res://scenes/mobs/GoblinShaman.tscn"),
    preload("res://scenes/mobs/GoblinFireMage.tscn"),
    preload("res://scenes/mobs/GoblinLightningMage.tscn"),
    preload("res://scenes/mobs/GoblinLizard.tscn"),
    preload("res://scenes/mobs/GoblinGiant.tscn"),
    preload("res://scenes/mobs/WallBuster.tscn"),
    preload("res://scenes/mobs/GoblinBatRider.tscn"),
    preload("res://scenes/mobs/GoblinPig.tscn"),
    preload("res://scenes/mobs/CrabRider.tscn"),
    preload("res://scenes/mobs/StoneGolem.tscn"),
    preload("res://scenes/mobs/Sunfaced.tscn")
]

const MOB_SCENES_BY_ID := {
    "goblin_bandit": preload("res://scenes/mobs/GoblinBandit.tscn"),
    "blue_slime": preload("res://scenes/mobs/BlueSlime.tscn"),
    "goblin_crossbowman": preload("res://scenes/mobs/GoblinCrossbowman.tscn"),
    "goblin_swordsman": preload("res://scenes/mobs/GoblinSwordsman.tscn"),
    "goblin_shaman": preload("res://scenes/mobs/GoblinShaman.tscn"),
    "goblin_fire_mage": preload("res://scenes/mobs/GoblinFireMage.tscn"),
    "goblin_lightning_mage": preload("res://scenes/mobs/GoblinLightningMage.tscn"),
    "goblin_lizard": preload("res://scenes/mobs/GoblinLizard.tscn"),
    "goblin_giant": preload("res://scenes/mobs/GoblinGiant.tscn"),
    "wall_buster": preload("res://scenes/mobs/WallBuster.tscn"),
    "goblin_bat_rider": preload("res://scenes/mobs/GoblinBatRider.tscn"),
    "goblin_pig": preload("res://scenes/mobs/GoblinPig.tscn"),
    "crab_rider": preload("res://scenes/mobs/CrabRider.tscn"),
    "stone_golem": preload("res://scenes/mobs/StoneGolem.tscn"),
    "sunfaced": preload("res://scenes/mobs/Sunfaced.tscn"),
    "dragon": preload("res://scenes/mobs/Dragon.tscn"),
}


func get_goblin_ids() -> Array[String]:
    return GOBLIN_IDS.duplicate()


func get_goblin_scenes() -> Array[PackedScene]:
    return GOBLIN_SCENES.duplicate()


func get_random_goblin_id() -> String:
    if GOBLIN_IDS.is_empty():
        return ""
    return GOBLIN_IDS[randi() % GOBLIN_IDS.size()]


func get_mob_scene(enemy_id: String) -> PackedScene:
    var id: String = enemy_id.to_lower()
    var scene: PackedScene = MOB_SCENES_BY_ID.get(id, null) as PackedScene
    if scene != null:
        return scene

    push_warning("[MobSceneRegistry] Unknown mob_id: %s (fallback to goblin_bandit)" % enemy_id)
    return MOB_SCENES_BY_ID.get("goblin_bandit", null) as PackedScene
