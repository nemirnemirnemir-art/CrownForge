extends TextureButton
class_name SliderButton

## Custom 4-state slider button: Normal, Hover, Pressed, Unhold (0.25s)
## Handles custom PNGs for each state.

# Textures for 4 states
@export var texture_normal_state: Texture2D
@export var texture_hover_state: Texture2D
@export var texture_pressed_state: Texture2D
@export var texture_unhold_state: Texture2D

# Config
@export var unhold_duration: float = 0.25

var _is_pressed: bool = false
var _unhold_timer: Timer

func _ready() -> void:
	# Setup unhold timer
	_unhold_timer = Timer.new()
	_unhold_timer.one_shot = true
	_unhold_timer.wait_time = unhold_duration
	_unhold_timer.timeout.connect(_on_unhold_timeout)
	add_child(_unhold_timer)
	
	# Initial state
	_update_texture(texture_normal_state)
	
	# Connect signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _update_texture(tex: Texture2D) -> void:
	if tex:
		texture_normal = tex
		# We use texture_normal for all visual states by swapping it, 
		# or we could use TextureButton's built-in properties if they mapped 1:1,
		# but "unhold" is custom. So manual swapping is safer for 4 states.

func _on_mouse_entered() -> void:
	if _is_pressed: return # Ignore hover if held down
	if not _unhold_timer.is_stopped(): return # Ignore hover if in unhold state
	
	_update_texture(texture_hover_state)

func _on_mouse_exited() -> void:
	if _is_pressed: return
	if not _unhold_timer.is_stopped(): return
	
	_update_texture(texture_normal_state)

func _on_button_down() -> void:
	_is_pressed = true
	_unhold_timer.stop() # Cancel unhold if clicked again
	_update_texture(texture_pressed_state)

func _on_button_up() -> void:
	_is_pressed = false
	# Enter unhold state
	_update_texture(texture_unhold_state)
	_unhold_timer.start()

func _on_unhold_timeout() -> void:
	# Return to normal or hover depending on mouse position
	if get_global_rect().abs().has_point(get_global_mouse_position()):
		_update_texture(texture_hover_state)
	else:
		_update_texture(texture_normal_state)
