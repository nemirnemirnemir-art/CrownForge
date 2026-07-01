extends Node
class_name HeroStateMachine

## State Machine for heroes on the field
## Manages transitions between states

const HeroDeathState = preload("res://scripts/hero/states/HeroDeathState.gd")
const HeroHitAndRunRetreatState = preload("res://scripts/hero/states/HeroHitAndRunRetreatState.gd")
const HeroBoundsRetreatState = preload("res://scripts/hero/states/HeroBoundsRetreatState.gd")
const HeroSaveFromStackState = preload("res://scripts/hero/states/HeroSaveFromStackState.gd")

@export var initial_state: Node

var current_state: Node
var state_enter_time: float = 0.0
var states: Dictionary = {}

func _ready() -> void:
    # DEBUG: Log state machine initialization
    # print("[HeroStateMachine] _ready() called, waiting for parent ready...")
    
    # Wait until parent is ready
    var parent_node = get_parent()
    if not parent_node:
        print("[HeroStateMachine] No parent found!")
        return
    
    await parent_node.ready
    
    # Get hero - parent can be state_machine_node (Node); we need HeroOnField (Node2D)
    var hero: Node2D = null
    var hero_id_str: String = "unknown"
    
    # If parent is Node2D (HeroOnField), use it directly
    if parent_node is Node2D:
        hero = parent_node as Node2D
    else:
        # If parent is Node (state_machine_node), get its parent (HeroOnField)
        var grandparent = parent_node.get_parent()
        if grandparent is Node2D:
            hero = grandparent as Node2D
            # print("[HeroStateMachine] Got hero from grandparent (state_machine_node -> HeroOnField)")
    
    if hero:
        if "hero_id" in hero:
            hero_id_str = str(hero.hero_id)
        # print("[HeroStateMachine] Hero %s: Parent ready, initializing states..." % hero_id_str)
    else:
        print("[HeroStateMachine] Could not find HeroOnField (Node2D)! Parent: %s, Grandparent: %s" % [str(parent_node), str(parent_node.get_parent() if parent_node else null)])
        return
    
    # Ensure process_mode is set correctly
    process_mode = Node.PROCESS_MODE_INHERIT
    
    for child in get_children():
        # Check if child has HeroState methods (enter, exit, update)
        if child.has_method("enter") and child.has_method("exit") and child.has_method("update"):
            states[child.name.to_lower()] = child
            # print("[HeroStateMachine] Hero %s: Registered state: %s" % [hero_id_str, child.name])
            if child.has_method("set_hero"):
                if hero:
                    child.set_hero(hero)
                    # print("[HeroStateMachine] Hero %s: Set hero for state %s, hero is null: %s" % [hero_id_str, child.name, child.hero == null])
            if child.has_method("set_state_machine"):
                child.set_state_machine(self)

    # Ensure HeroDeathState always exists (some hero scenes don't include it as a child node)
    if not states.has("herodeathstate"):
        var death_state = HeroDeathState.new()
        death_state.name = "HeroDeathState"
        add_child(death_state)
        states[death_state.name.to_lower()] = death_state
        # print("[HeroStateMachine] Hero %s: Registered state: %s" % [hero_id_str, death_state.name])
        if death_state.has_method("set_hero") and hero:
            death_state.set_hero(hero)
            # print("[HeroStateMachine] Hero %s: Set hero for state %s, hero is null: %s" % [hero_id_str, death_state.name, death_state.hero == null])
        if death_state.has_method("set_state_machine"):
            death_state.set_state_machine(self)

    # Ensure HeroHitAndRunRetreatState exists for units with hit-and-run behavior.
    if not states.has("herohitandrunretreatstate"):
        var retreat_state = HeroHitAndRunRetreatState.new()
        retreat_state.name = "HeroHitAndRunRetreatState"
        add_child(retreat_state)
        states[retreat_state.name.to_lower()] = retreat_state
        if retreat_state.has_method("set_hero") and hero:
            retreat_state.set_hero(hero)
        if retreat_state.has_method("set_state_machine"):
            retreat_state.set_state_machine(self)
    
    # Ensure HeroBoundsRetreatState exists for boundary collision handling.
    if not states.has("heroboundsretreatstate"):
        var bounds_retreat = HeroBoundsRetreatState.new()
        bounds_retreat.name = "HeroBoundsRetreatState"
        add_child(bounds_retreat)
        states[bounds_retreat.name.to_lower()] = bounds_retreat
        if bounds_retreat.has_method("set_hero") and hero:
            bounds_retreat.set_hero(hero)
        if bounds_retreat.has_method("set_state_machine"):
            bounds_retreat.set_state_machine(self)

    # Ensure HeroSaveFromStackState exists because idle/watchdog logic may always transition into it.
    if not states.has("herosavefromstackstate"):
        var save_from_stack = HeroSaveFromStackState.new()
        save_from_stack.name = "HeroSaveFromStackState"
        add_child(save_from_stack)
        states[save_from_stack.name.to_lower()] = save_from_stack
        if save_from_stack.has_method("set_hero") and hero:
            save_from_stack.set_hero(hero)
        if save_from_stack.has_method("set_state_machine"):
            save_from_stack.set_state_machine(self)
    
    # print("[HeroStateMachine] Hero %s: Total states registered: %d" % [hero_id_str, states.size()])
    
    if initial_state:
        # print("[HeroStateMachine] Hero %s: Setting initial state: %s" % [hero_id_str, initial_state.name])
        change_state(initial_state.name)
    else:
        # print("[HeroStateMachine] Hero %s: No initial_state set!" % hero_id_str)
        # Use the first available state as initial
        if states.size() > 0:
            var first_state_name = states.keys()[0]
            # print("[HeroStateMachine] Hero %s: Using first available state: %s" % [hero_id_str, first_state_name])
            change_state(first_state_name)

func _get_hero() -> Node2D:
    # Get HeroOnField (Node2D) from parent or grandparent
    var parent = get_parent()
    if parent is Node2D:
        return parent as Node2D
    else:
        var grandparent = parent.get_parent() if parent else null
        if grandparent is Node2D:
            return grandparent as Node2D
    return null

func _process(delta: float) -> void:
    # DEBUG: Log first _process call
    if Engine.get_process_frames() == 1:
        var hero_node = _get_hero()
        var _hero_id_str: String = "unknown"
        if hero_node and "hero_id" in hero_node:
            _hero_id_str = str(hero_node.hero_id)
        # print("[HeroStateMachine] Hero %s: _process() called for the first time!" % _hero_id_str)
    
    if not current_state:
        # DEBUG: Log if current_state is not set
        var hero_node2 = _get_hero()
        if hero_node2 and Engine.get_process_frames() % 180 == 0:  # Every 3 seconds
            var _hero_id_str2: String = "unknown"
            if "hero_id" in hero_node2:
                _hero_id_str2 = str(hero_node2.hero_id)
            # print("[HeroStateMachine] Hero %s: _process() called but current_state is null!" % _hero_id_str2)
        return
    
    # DEBUG: Log update calls (periodically)
    var hero_node3 = _get_hero()
    if hero_node3 and Engine.get_process_frames() % 180 == 0:  # Every 3 seconds
        var _hero_id_str3: String = "unknown"
        if "hero_id" in hero_node3:
            _hero_id_str3 = str(hero_node3.hero_id)
        var _state_name_str: String = "None"
        if current_state:
            _state_name_str = str(current_state.name)
        # print("[HeroStateMachine] Hero %s: _process() called, current_state: %s" % [_hero_id_str3, _state_name_str])
    
    current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func change_state(state_name: String) -> void:
    var new_state = states.get(state_name.to_lower())
    if not new_state:
        var hero_node_nf = _get_hero()
        var hero_id_str: String = "unknown"
        if hero_node_nf and "hero_id" in hero_node_nf:
            hero_id_str = str(hero_node_nf.hero_id)
        push_error("[HeroStateMachine] Hero %s: State not found: %s. Available: %s" % [hero_id_str, state_name, str(states.keys())])
        return
    
    var _old_state_name: String = "None"
    if current_state:
        _old_state_name = str(current_state.name)
    
    # DEBUG: Log state change
    var hero_node = _get_hero()
    if hero_node:
        if "hero_id" in hero_node:
            var _hero_id_str4: String = str(hero_node.hero_id)
            # print("[HeroStateMachine] 🔄 Hero %s: %s -> %s" % [_hero_id_str4, _old_state_name, state_name])
    
    if current_state:
        current_state.exit()
    
    current_state = new_state
    
    # Ensure hero is set on the new state
    if current_state.has_method("set_hero") and hero_node:
        current_state.set_hero(hero_node)
    
    state_enter_time = Time.get_ticks_msec() / 1000.0
    current_state.enter()
