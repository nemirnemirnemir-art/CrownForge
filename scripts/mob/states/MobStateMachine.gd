extends Node
class_name MobStateMachine

@export var initial_state: Node

var current_state: Node
var state_enter_time: float = 0.0
var states: Dictionary = {}

func _ready() -> void:
    var parent := get_parent()
    if not parent:
        return
    await parent.ready

    var mob_node: Node2D = null
    if parent is Node2D:
        mob_node = parent as Node2D
    else:
        var gp = parent.get_parent()
        if gp is Node2D:
            mob_node = gp as Node2D
    if mob_node == null:
        return

    process_mode = Node.PROCESS_MODE_INHERIT

    for child in get_children():
        if child.has_method("enter") and child.has_method("exit") and child.has_method("update"):
            states[child.name.to_lower()] = child
            if child.has_method("set_mob"):
                child.set_mob(mob_node)
            if child.has_method("set_state_machine"):
                child.set_state_machine(self)

    if initial_state:
        change_state(initial_state.name)
    elif states.size() > 0:
        change_state(states.keys()[0])

func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func change_state(state_name: String) -> void:
    var key := state_name.to_lower()
    var new_state = states.get(key)
    if not new_state:
        if key == "mobmovestate":
            if states.has("mobrunidlestate"):
                new_state = states.get("mobrunidlestate")
            elif initial_state and states.has(initial_state.name.to_lower()):
                new_state = states.get(initial_state.name.to_lower())
            elif states.size() > 0:
                new_state = states.get(states.keys()[0])
            else:
                return
        else:
            push_warning("[MobStateMachine] State not found: %s" % state_name)
            return
    if current_state:
        current_state.exit()
    current_state = new_state
    state_enter_time = Time.get_ticks_msec() / 1000.0
    current_state.enter()
