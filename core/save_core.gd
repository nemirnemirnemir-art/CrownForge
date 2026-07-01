extends Node
## SaveCore autoload singleton - no class_name needed

const API_VERSION := 1
const SAVE_FILE_PATH: String = "user://save.json"
const SAVE_MESSAGE_INTERVAL: float = 60.0  # Show message no more than once per minute

var _last_save_message_time: float = -999.0  # Time of last message

const _SaveManager = preload("res://core/save_manager.gd")
const SaveRegistryFlowScript := preload("res://core/save/SaveRegistryFlow.gd")
const SaveAutosaveFlowScript := preload("res://core/save/SaveAutosaveFlow.gd")
const SaveResetFlowScript := preload("res://core/save/SaveResetFlow.gd")
const SaveIOFlowScript := preload("res://core/save/SaveIOFlow.gd")

const AUTOSAVE_DEBOUNCE_SEC: float = 1.0

var _save_modules: Dictionary = {}
var _save_requested: bool = false
var _save_due_time: float = 0.0
var _is_loading: bool = false
var _can_save: bool = false
var _registry_flow = null
var _autosave_flow = null
var _reset_flow = null
var _io_flow = null

func _ready() -> void:
    _registry_flow = SaveRegistryFlowScript.new()
    _autosave_flow = SaveAutosaveFlowScript.new()
    _reset_flow = SaveResetFlowScript.new()
    _io_flow = SaveIOFlowScript.new()
    # We defer loading slightly to ensure all other autoloads are ready
    set_process(false)
    call_deferred("_bootstrap")

func _exit_tree() -> void:
    save_game()

func _bootstrap() -> void:
    _auto_register_autoload_modules()
    load_game()
    _can_save = true

func _auto_register_autoload_modules() -> void:
    var autoloads = ProjectSettings.get_setting("autoload")
    if autoloads == null or not (autoloads is Dictionary):
        return

    for autoload_name in (autoloads as Dictionary).keys():
        var node := get_node_or_null("/root/%s" % str(autoload_name))
        if node == null:
            continue
        if node == self:
            continue
        _try_register_save_target(str(autoload_name), node)

func _try_register_save_target(autoload_name: String, obj: Object) -> void:
    if _registry_flow:
        _registry_flow.try_register_save_target(_save_modules, autoload_name, obj)

func _derive_save_key(autoload_name: String) -> String:
    return _registry_flow.derive_save_key(autoload_name) if _registry_flow else ""

func register_module(save_key: String, module: Object) -> void:
    if _registry_flow:
        _registry_flow.register_module(_save_modules, save_key, module)

func request_save() -> void:
    if _autosave_flow:
        _autosave_flow.request_save({"save_requested": _save_requested, "save_due_time": _save_due_time}, _is_loading, Time.get_ticks_msec() / 1000.0, AUTOSAVE_DEBOUNCE_SEC)
        _save_requested = true
        _save_due_time = (Time.get_ticks_msec() / 1000.0) + AUTOSAVE_DEBOUNCE_SEC
    set_process(true)

func _process(_delta: float) -> void:
    if not _save_requested:
        set_process(false)
        return
    var now := Time.get_ticks_msec() / 1000.0
    if _autosave_flow and not _autosave_flow.process_tick({"save_requested": _save_requested, "save_due_time": _save_due_time}, now, Callable(self, "save_game")):
        return
    _save_requested = false
    set_process(false)

func _notification(what: int) -> void:
    # ✅ Save on game exit
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        save_game()

func save_game() -> void:
    var current_stage: int = StageCore.get_current_stage() if StageCore else 0
    var has_critical_modules: bool = HeroCore != null and StageCore != null
    if _io_flow and _io_flow.save_game(_SaveManager, SAVE_FILE_PATH, _can_save, _is_loading, current_stage, has_critical_modules, _save_modules):
        EventBus.game_saved.emit()
        
        # Message throttling - show no more than once per minute
        var current_time = Time.get_ticks_msec() / 1000.0
        if current_time - _last_save_message_time >= SAVE_MESSAGE_INTERVAL:
            # print("[SaveCore] Game saved successfully.")
            _last_save_message_time = current_time
    else:
        # print("[SaveCore] Failed to open save file for writing.")
        pass

func load_game() -> bool:
    _is_loading = true
    var ok: bool = _io_flow.load_game(_SaveManager, SAVE_FILE_PATH, _save_modules, EventBus.game_loaded.emit if EventBus else Callable()) if _io_flow else false
    _is_loading = false
    return ok

func reset_progress() -> void:
    var artifact_core := get_node_or_null("/root/ArtifactCore")
    if _reset_flow:
        _reset_flow.reset_progress(
            StageCore,
            EconomyCore,
            HeroCore,
            TownCore,
            PlayerInventory,
            ResourceCore,
            GazeCore,
            artifact_core,
            ForgeCore,
            MineCore,
            DamagePopupPool,
            TownCore._buildings if TownCore and "_buildings" in TownCore else null,
            TownCore._potions if TownCore and "_potions" in TownCore else null,
            TownCore._perks if TownCore and "_perks" in TownCore else null,
            TownCore._hospital if TownCore and "_hospital" in TownCore else null,
            TownCore._bonuses if TownCore and "_bonuses" in TownCore else null,
            _SaveManager,
            SAVE_FILE_PATH,
            Callable(self, "save_game")
        )
