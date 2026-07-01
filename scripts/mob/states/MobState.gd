extends Node
class_name MobState

var mob: Node2D
var state_machine: Node

func set_mob(mob_node: Node2D) -> void:
	mob = mob_node

func set_state_machine(machine: Node) -> void:
	state_machine = machine

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
