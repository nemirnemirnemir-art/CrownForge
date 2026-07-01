# Quickstart: Enemy Death FX v1

**Date**: 2025-01-27  
**Feature**: Enemy Death FX v1 — Hybrid LOD + Pooling

## Prerequisites

- Godot 4.3 engine
- Existing enemy system (`Enemy.gd`, `HealthComponent`)
- Player in scene tree (group "player")

## Setup Steps

### 1. Create Shader

Create `shaders/enemy_death_dissolve.gdshader`:

```glsl
shader_type canvas_item;

uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_texture : source_color;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    float noise = texture(noise_texture, UV * 10.0).r;
    float threshold = dissolve_progress;
    
    if (noise < threshold) {
        discard;
    }
    
    COLOR = color;
}
```

**Note**: Simple noise-based dissolve. Can be enhanced with pixelation, color effects, etc.

---

### 2. Create Shader Material Resource

Create `shaders/enemy_death_dissolve_material.tres`:

1. In Godot editor: Resource → New → ShaderMaterial
2. Set `shader` property to `enemy_death_dissolve.gdshader`
3. Set `shader_parameter/dissolve_progress = 0.0`
4. (Optional) Set `shader_parameter/noise_texture` to a noise texture
5. Save as `res://shaders/enemy_death_dissolve_material.tres`

---

### 3. Create Configuration Resource

Create `data/config/EnemyDeathConfig.gd`:

```gdscript
extends Resource
class_name EnemyDeathConfig

@export var near_death_radius_px: float = 500.0
@export var nice_fx_duration_sec: float = 0.6
@export var cheap_fade_duration_sec: float = 0.15
@export var max_active_nice_fx: int = 30
```

Create `data/config/EnemyDeathConfig.tres`:

1. In Godot editor: Resource → New → EnemyDeathConfig
2. Set default values (or leave as-is)
3. Save as `res://data/config/EnemyDeathConfig.tres`

---

### 4. Create EnemyDeathController

Create `gameplay/enemies/EnemyDeathController.gd`:

```gdscript
extends Node
class_name EnemyDeathController

@export var config: EnemyDeathConfig
@export var debug_logs: bool = false

var _active_nice_fx_count: int = 0
var _player: Node2D = null
var _shared_shader_material: ShaderMaterial = null

const SHADER_MATERIAL_PATH = preload("res://shaders/enemy_death_dissolve_material.tres")

func _ready() -> void:
	if config == null:
		push_error("[EnemyDeathController] config is null")
		return
	
	_shared_shader_material = SHADER_MATERIAL_PATH.duplicate() as ShaderMaterial
	if _shared_shader_material == null:
		push_error("[EnemyDeathController] Failed to load shader material")
	
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		push_warning("[EnemyDeathController] Player not found in group 'player'")

func handle_enemy_death(enemy: Node, from: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	
	var enemy_node := enemy as Enemy
	if enemy_node == null:
		return
	
	# Set dying state, disable AI/collisions
	_set_enemy_dying_state(enemy_node)
	
	# Trigger loot/XP/kill counters (immediate)
	_trigger_death_events(enemy_node, from)
	
	# Decide FX type and start
	if _should_use_nice_fx(enemy_node):
		_start_nice_fx(enemy_node)
	else:
		_start_cheap_fx(enemy_node)

func _should_use_nice_fx(enemy: Enemy) -> bool:
	if _player == null:
		return false
	
	var dist := enemy.global_position.distance_to(_player.global_position)
	if dist > config.near_death_radius_px:
		return false
	
	if _active_nice_fx_count >= config.max_active_nice_fx:
		return false
	
	return true

func _start_nice_fx(enemy: Enemy) -> void:
	var sprite := _get_enemy_sprite(enemy)
	if sprite == null:
		_start_cheap_fx(enemy)  # Fallback
		return
	
	if _shared_shader_material == null:
		_start_cheap_fx(enemy)  # Fallback
		return
	
	# Apply shader material
	var material := _shared_shader_material.duplicate() as ShaderMaterial
	sprite.material = material
	material.set_shader_parameter("dissolve_progress", 0.0)
	
	# Animate dissolve
	var tween := enemy.create_tween()
	tween.tween_property(material, "shader_parameter/dissolve_progress", 1.0, config.nice_fx_duration_sec)
	tween.finished.connect(_on_nice_fx_finished.bind(enemy, sprite, material))
	
	_active_nice_fx_count += 1
	if debug_logs:
		print("[EnemyDeathController] Started nice FX on %s (active: %d)" % [enemy.name, _active_nice_fx_count])

func _start_cheap_fx(enemy: Enemy) -> void:
	var sprite := _get_enemy_sprite(enemy)
	if sprite == null:
		_cleanup_and_release(enemy)
		return
	
	# Animate alpha fade
	var tween := enemy.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, config.cheap_fade_duration_sec)
	tween.finished.connect(_on_cheap_fx_finished.bind(enemy, sprite))

func _on_nice_fx_finished(enemy: Enemy, sprite: Node2D, material: ShaderMaterial) -> void:
	material.set_shader_parameter("dissolve_progress", 0.0)
	sprite.material = null  # Remove shader
	_active_nice_fx_count -= 1
	if debug_logs:
		print("[EnemyDeathController] Nice FX finished on %s (active: %d)" % [enemy.name, _active_nice_fx_count])
	_cleanup_and_release(enemy)

func _on_cheap_fx_finished(enemy: Enemy, sprite: Node2D) -> void:
	sprite.modulate.a = 1.0  # Reset for future reuse
	_cleanup_and_release(enemy)

func _get_enemy_sprite(enemy: Enemy) -> Node2D:
	var anim_sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim_sprite != null:
		return anim_sprite
	var sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
	return sprite

func _set_enemy_dying_state(enemy: Enemy) -> void:
	# Disable AI, movement, collisions
	enemy.set_physics_process(false)
	enemy.set_process(false)
	# Disable collisions (set collision_layer = 0 or disable CollisionShape2D)
	var collision := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		collision.disabled = true

func _trigger_death_events(enemy: Enemy, from: Node) -> void:
	# Trigger existing loot drop, XP, kill counter logic
	# (This should already be handled by existing systems, but can be called here if needed)
	pass

func _cleanup_and_release(enemy: Enemy) -> void:
	# For v1: use queue_free (pooling is optional, Phase 2)
	enemy.queue_free()
```

---

### 5. Set Up Autoload (Optional)

Add `EnemyDeathController` as autoload:

1. Project → Project Settings → Autoload
2. Add `EnemyDeathController` (path: `res://gameplay/enemies/EnemyDeathController.gd`)
3. Set name: `EnemyDeathController`
4. Enable "Singleton"

**Alternative**: Add as child node in main game scene (if autoload not preferred).

---

### 6. Connect to HealthComponent

Modify enemy spawn/ready logic to connect death signal:

**Option A: In Enemy.gd `_ready()`**:
```gdscript
func _ready() -> void:
	# ... existing code ...
	
	var health := get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.died.connect(_on_health_died)

func _on_health_died(from: Node) -> void:
	var controller := get_node_or_null("/root/EnemyDeathController") as EnemyDeathController
	if controller != null:
		controller.handle_enemy_death(self, from)
```

**Option B: In EnemySpawner after spawn**:
```gdscript
func _on_timeout(config_index: int) -> void:
	# ... spawn enemy code ...
	
	var health := e.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		var controller := get_node_or_null("/root/EnemyDeathController") as EnemyDeathController
		if controller != null:
			health.died.connect(controller.handle_enemy_death.bind(e))
```

---

### 7. Configure Controller

If using autoload, set configuration in Project Settings:

1. Project → Project Settings → Autoload → EnemyDeathController
2. Set `config` property to `res://data/config/EnemyDeathConfig.tres`
3. Enable `debug_logs` for testing

**Alternative**: Set in code in `_ready()`:
```gdscript
func _ready() -> void:
	config = preload("res://data/config/EnemyDeathConfig.tres")
```

---

## Testing

### Manual Test: Near Death (Nice FX)

1. Spawn enemy near player (< 500 px)
2. Damage enemy to 0 HP
3. **Expected**: Dissolve shader effect plays (0.6 sec), enemy disappears

### Manual Test: Far Death (Cheap FX)

1. Spawn enemy far from player (> 500 px)
2. Damage enemy to 0 HP
3. **Expected**: Fast alpha fade (0.15 sec), enemy disappears

### Manual Test: FX Cap

1. Spawn 35 enemies near player
2. Kill all simultaneously
3. **Expected**: First 30 get nice FX, remaining 5 get cheap FX

### Performance Test

1. Spawn 50+ enemies
2. Kill all in rapid succession
3. **Expected**: FPS remains stable (60 FPS), no stutter

---

## Troubleshooting

### Shader Not Visible

- Check shader material is loaded: `_shared_shader_material != null`
- Check sprite has material applied: `sprite.material != null`
- Check shader uniform is set: `material.get_shader_parameter("dissolve_progress")`

### FX Cap Not Working

- Check `_active_nice_fx_count` increments/decrements correctly
- Check `max_active_nice_fx` value in config
- Enable `debug_logs` to see active count

### Player Not Found

- Ensure player is in group "player": `player.add_to_group("player")`
- Check `_player` is set in `_ready()`: `_player != null`

### Enemy Not Disappearing

- Check `_cleanup_and_release()` is called after FX
- Check `queue_free()` is called (or pool release if pooling added)
- Check enemy is not referenced elsewhere (prevents cleanup)

---

## Next Steps

- **Phase 2**: Add enemy pooling (optional, future enhancement)
- **Enhancement**: Improve shader (pixelation, color effects, particles)
- **Tuning**: Adjust `near_death_radius_px`, FX durations in config
- **Optimization**: Profile shader performance, optimize if needed

