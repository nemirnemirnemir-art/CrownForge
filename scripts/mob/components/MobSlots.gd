extends Node
class_name MobSlots

@export var MAX_SLOTS: int = 4
var reserved_slots: Dictionary = {} # hero_id -> timestamp

func setup(_mob: Node2D) -> void:
    pass

func reserve_slot(hero_id: String) -> bool:
    if reserved_slots.has(hero_id):
        reserved_slots[hero_id] = Time.get_unix_time_from_system()
        return true
    if reserved_slots.size() >= MAX_SLOTS: return false
    reserved_slots[hero_id] = Time.get_unix_time_from_system()
    return true

func release_slot(hero_id: String) -> void:
    if reserved_slots.has(hero_id): reserved_slots.erase(hero_id)

func has_slot(hero_id: String) -> bool:
    return reserved_slots.has(hero_id)

func get_available_slots() -> int:
    return MAX_SLOTS - reserved_slots.size()
