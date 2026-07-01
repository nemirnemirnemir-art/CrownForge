extends RefCounted
class_name SkillInstance

signal activated(duration: float)
signal ended()

var id: int
var name: String
var active: bool = false
var timer: float = 0.0
var cooldown_timer: float = 0.0 # For cooldown tracking (Skills 9, 10)
var cost: float = 100.0
var duration: float = 30.0
var cooldown: float = 0.0

# Effect Multiplier Storage (for "Next Effect x2")
var effect_multiplier: float = 1.0

# Dependencies
var core: Node # Reference to SkillCore for signals/checks

func _init(_core: Node, _id: int, _name: String, _cost: float, _dur: float = 30.0, _cd: float = 0.0) -> void:
    core = _core
    id = _id
    name = _name
    cost = _cost
    duration = _dur
    cooldown = _cd

func can_activate(_mage_tower_level: int) -> bool:
    if active: return false # Already active
    if cooldown > 0.0 and get_cooldown_remaining() > 0: return false
    
    # Check unlock (Mage Tower)
    # Assuming standard unlock: Skill N requires Mage Tower level N (or simplified check)
    # Using TownCore check if available
    if TownCore and not TownCore.is_mage_tower_skill_purchased(id):
        return false
        
    return true

func activate(get_multiplier: Callable) -> bool:
    effect_multiplier = get_multiplier.call()
    active = true
    timer = duration
    
    # Set cooldown timestamp if needed
    if cooldown > 0.0:
        cooldown_timer = Time.get_unix_time_from_system()
        
    # Special logic for Skill 1 (AutoClicker) - hits scaling
    # Handled by signal listener or getter in Core
    
    activated.emit(timer)
    return true

func force_end() -> void:
    if active:
        active = false
        timer = 0.0
        ended.emit()

func process(delta: float) -> void:
    if active:
        timer -= delta
        # Skill 6 (Heal) tick logic needs to be handled externally or via callback
        # For generic skills, just active duration
        if timer <= 0:
            active = false
            ended.emit()

func get_cooldown_remaining() -> float:
    if cooldown <= 0: return 0.0
    var now = Time.get_unix_time_from_system()
    var elapsed = now - cooldown_timer
    return max(0.0, cooldown - elapsed)

func reset_cooldown() -> void:
    cooldown_timer = 0.0

func get_save_data() -> Dictionary:
    return {
        "cd_timer": cooldown_timer
    }

func load_save_data(data: Dictionary) -> void:
    cooldown_timer = data.get("cd_timer", 0.0)
