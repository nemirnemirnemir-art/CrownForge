extends Node

## Object Pool for Damage Popups
## Reuses popups instead of constant creation/deletion for performance
## Use as autoload singleton: DamagePopupPool.show_damage(position, amount, is_crit)

@export var initial_pool_size: int = 20
@export var max_pool_size: int = 50
@export var max_active_popups: int = 30
@export var debug_logs: bool = true

# Pool of available popups
var _available_pool: Array[Node2D] = []
# Active popups
var _active_popups: Array[Node2D] = []
# Scene for creating new popups
var _popup_scene: PackedScene = null
# Container for all popups
var _popup_container: Node2D = null

# Batching exports — read by DamagePopupBatcher
@export var enable_batching: bool = true
@export var batch_radius_px: float = 25.0
@export var batch_time_window_sec: float = 0.08

var _batcher: DamagePopupBatcher
var _spawner: DamagePopupSpawner


func _ready() -> void:
    # Очищаем пулы при перезагрузке сцены (reset progress)
    reset_pool()
    
    # Load popup scene
    _popup_scene = preload("res://scenes/ui/overlays/DamagePopup.tscn")
    if _popup_scene == null:
        push_error("[DamagePopupPool] Failed to load DamagePopup.tscn")
        return
    
    # Init modules
    _spawner = DamagePopupSpawner.new()
    _spawner.init(self)
    _batcher = DamagePopupBatcher.new()
    _batcher.init(self, _spawner)
    
    # Create container for all popups
    call_deferred("_ensure_container")
    
    # Initialize pool
    call_deferred("_initialize_pool")
    
    if debug_logs:
        print("[DamagePopupPool] Initialized - pool_size=%d max_active=%d" % [initial_pool_size, max_active_popups])

func reset_pool() -> void:
    # Полная очистка при сбросе мира
    for popup in _available_pool:
        if is_instance_valid(popup):
            popup.queue_free()
    _available_pool.clear()

    for popup in _active_popups:
        if is_instance_valid(popup):
            popup.queue_free()
    _active_popups.clear()

    if _batcher != null:
        _batcher.clear()

    # Контейнер тоже удаляем, он пересоздастся
    if is_instance_valid(_popup_container):
        _popup_container.queue_free()
    _popup_container = null

    # Переинициализация если мы не выходим из игры
    if is_inside_tree():
        call_deferred("_ensure_container")
        call_deferred("_initialize_pool")


func _ensure_container() -> void:
    # Проверяем и пересоздаем контейнер, если он освобожден (после reset progress)
    if not is_instance_valid(_popup_container) or not _popup_container.is_inside_tree():
        _popup_container = Node2D.new()
        _popup_container.name = "DamagePopupContainer"
        _popup_container.z_index = 100

        var root := get_tree().current_scene
        if root != null:
            root.add_child(_popup_container)

func _add_container_to_scene() -> void:
    _ensure_container()


func _initialize_pool() -> void:
    for i in range(initial_pool_size):
        var popup := _create_popup()
        if popup != null and is_instance_valid(popup):
            _available_pool.append(popup)

    if debug_logs:
        print("[DamagePopupPool] Pool initialized with %d popups" % _available_pool.size())


func _create_popup() -> Node2D:
    if _popup_scene == null:
        return null

    var popup := _popup_scene.instantiate() as Node2D
    if popup == null:
        return null

    # Проверяем и пересоздаем контейнер, если он освобожден (после reset progress)
    if not is_instance_valid(_popup_container) or not _popup_container.is_inside_tree():
        _ensure_container()

    # Add to container but hide
    if is_instance_valid(_popup_container):
        _popup_container.add_child(popup)
    else:
        popup.queue_free()
        return null
    popup.visible = false
    popup.set_process(false)

    # Disable automatic deletion
    if popup.has_method("set_auto_free"):
        popup.call("set_auto_free", false)

    return popup


## Main method to show damage popup
## position: world position where to show
## amount: damage value
## is_crit: optional critical hit flag
func show_damage(pos: Vector2, amount: int, is_crit: bool = false, tint: Color = Color.WHITE) -> void:
    if amount <= 0:
        return
    if not _is_damage_numbers_enabled():
        return
    if _active_popups.size() >= max_active_popups:
        if debug_logs:
            print("[DamagePopupPool] Max active popups reached (%d), skipping" % max_active_popups)
        return

    if enable_batching:
        _batcher.try_batch(pos, amount, is_crit, tint)
        return

    _spawner.spawn(pos, amount, is_crit, tint)


func _is_damage_numbers_enabled() -> bool:
    if not is_inside_tree():
        return false
    var tree := get_tree()
    if tree == null or tree.root == null:
        return false
    var game_settings := tree.root.get_node_or_null("GameSettings")
    if game_settings == null or not game_settings.has_method("is_damage_numbers_enabled"):
        return false
    return bool(game_settings.is_damage_numbers_enabled())


func _process(_delta: float) -> void:
    if enable_batching and _batcher != null:
        _batcher.process_batches()
    _cleanup_finished_popups()


func _get_or_create_popup() -> Node2D:
    # Try to get from pool (with validity check)
    while _available_pool.size() > 0:
        var popup: Node2D = _available_pool.pop_back()
        if is_instance_valid(popup):
            return popup

    # Pool empty - create new (if limit not exceeded)
    if _available_pool.size() + _active_popups.size() < max_pool_size:
        var popup: Node2D = _create_popup()
        if debug_logs:
            print("[DamagePopupPool] Pool exhausted, created new popup")
        return popup

    # Max reached - skip
    if debug_logs:
        print("[DamagePopupPool] Max pool size reached (%d), skipping popup" % max_pool_size)
    return null


func _return_to_pool(popup: Node2D) -> void:
    if not is_instance_valid(popup):
        return

    # Remove from active
    _active_popups.erase(popup)

    # Hide and stop
    popup.visible = false
    popup.set_process(false)

    # Cleanup children
    for child in popup.get_children():
        if is_instance_valid(child):
            child.queue_free()

    # Return to pool
    if is_instance_valid(popup) and _available_pool.size() < max_pool_size:
        _available_pool.append(popup)
    else:
        if is_instance_valid(popup):
            popup.queue_free()


func _cleanup_finished_popups() -> void:
    # Remove invalid from available pool
    var i := _available_pool.size() - 1
    while i >= 0:
        if not is_instance_valid(_available_pool[i]):
            _available_pool.remove_at(i)
        i -= 1

    # Remove invalid from active
    i = _active_popups.size() - 1
    while i >= 0:
        if not is_instance_valid(_active_popups[i]):
            _active_popups.remove_at(i)
        i -= 1


## Get pool statistics for debugging
func get_pool_stats() -> Dictionary:
    var valid_available: int = 0
    for popup in _available_pool:
        if is_instance_valid(popup):
            valid_available += 1

    var valid_active: int = 0
    for popup in _active_popups:
        if is_instance_valid(popup):
            valid_active += 1

    return {
        "available": valid_available,
        "active": valid_active,
        "total": valid_available + valid_active
    }
