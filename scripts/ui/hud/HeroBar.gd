extends Control

## Hero bar UI panel - Controller
## Координирует модули для отображения героев с пагинацией

signal hero_selected(hero_id: String)

# ===========================================
# MODULE PRELOADS
# ===========================================
const HeroBarSlots = preload("res://scripts/hero/bar/HeroBarSlots.gd")
const HeroBarPortraits = preload("res://scripts/hero/bar/HeroBarPortraits.gd")
const HeroBarDisplay = preload("res://scripts/hero/bar/HeroBarDisplay.gd")
const HeroBarEvents = preload("res://scripts/hero/bar/HeroBarEvents.gd")

# ===========================================
# NODE REFERENCES
# ===========================================
@onready var slots_grid: GridContainer = $NavigationContainer/SlotsGrid
@onready var prev_button: SliderButton = $NavigationContainer/PrevButton
@onready var next_button: SliderButton = $NavigationContainer/NextButtonWrapper/NextButton
@onready var hp_bar_template: Control = get_node_or_null("HPBarTemplate")

@export_group("HeroBar Layout")
@export var slot_h_separation: int = 5
@export var slot_v_separation: int = 0

@export_group("HeroBar HP Bar")
@export var hero_slot_hpbar_offset: Vector2 = Vector2(0, 84)
@export var hero_slot_hpbar_size: Vector2 = Vector2(100, 10)

# ===========================================
# MODULE INSTANCES
# ===========================================
var _slots: Node
var _portraits: Node
var _display: Node
var _events: Node

# ===========================================
# STATE
# ===========================================
const HEROES_PER_PAGE: int = 5
var current_page: int = 0

func _get_hero_core() -> Node:
    var tree := get_tree()
    if tree == null:
        return null
    return tree.root.get_node_or_null("HeroCore")

func _get_event_bus() -> Node:
    var tree := get_tree()
    if tree == null:
        return null
    return tree.root.get_node_or_null("EventBus")

# ===========================================
# INITIALIZATION
# ===========================================
func _ready() -> void:
    add_to_group("hero_bar")
    
    _initialize_modules()
    _setup_ui()
    _configure_hp_bar_from_template()
    _connect_signals()
    
    update_display()

func _configure_hp_bar_from_template() -> void:
    if hp_bar_template == null:
        return

    # Read transform from editor-draggable node
    hero_slot_hpbar_offset = hp_bar_template.position
    hero_slot_hpbar_size = hp_bar_template.size
    if hero_slot_hpbar_size == Vector2.ZERO:
        hero_slot_hpbar_size = hp_bar_template.custom_minimum_size

    # Hide template in game; keep it only as an editor handle
    hp_bar_template.visible = false
    hp_bar_template.process_mode = PROCESS_MODE_DISABLED

    if _display and _display.has_method("configure_hp_bar"):
        _display.configure_hp_bar(hero_slot_hpbar_offset, hero_slot_hpbar_size)

func _initialize_modules() -> void:
    _slots = HeroBarSlots.new()
    _slots.initialize(slots_grid)
    
    _portraits = HeroBarPortraits.new()
    
    _display = HeroBarDisplay.new()
    _display.initialize(_slots.get_slots(), _portraits)
    if _display.has_method("configure_hp_bar"):
        _display.configure_hp_bar(hero_slot_hpbar_offset, hero_slot_hpbar_size)
    
    _events = HeroBarEvents.new()
    _events.initialize(self, _slots.get_slots())
    
    # Connect slot clicks
    for i in range(HEROES_PER_PAGE):
        _slots.connect_slot_clicked(i, _on_slot_clicked.bind(i))

func _setup_ui() -> void:
    # Removed hardcoded position/size to respect Editor layout
    
    if slots_grid:
        slots_grid.add_theme_constant_override("h_separation", slot_h_separation)
        slots_grid.add_theme_constant_override("v_separation", slot_v_separation)

func _connect_signals() -> void:
    if prev_button != null:
        prev_button.pressed.connect(_on_prev_button_pressed)
    if next_button != null:
        next_button.pressed.connect(_on_next_button_pressed)
    
    var hero_core := _get_hero_core()
    if hero_core != null:
        hero_core.hero_created.connect(_on_hero_created)
        hero_core.hero_updated.connect(_on_hero_updated)
        hero_core.squad_changed.connect(_on_squad_changed)
        hero_core.heroes_cleared.connect(_on_heroes_cleared)
    
    var event_bus := _get_event_bus()
    if event_bus:
        if not event_bus.hero_healed_by_hospital.is_connected(_on_hero_healed_by_hospital):
            event_bus.hero_healed_by_hospital.connect(_on_hero_healed_by_hospital)
        if event_bus.has_signal("hero_selected_for_ui"):
            if not event_bus.hero_selected_for_ui.is_connected(_on_hero_selected_for_ui):
                event_bus.hero_selected_for_ui.connect(_on_hero_selected_for_ui)

func _on_hero_selected_for_ui(hero_id: String) -> void:
    var hero_core := _get_hero_core()
    if hero_core == null:
        return
    if hero_id == "":
        return
    if hero_core.query.is_hero_dead(hero_id) or not hero_core.query.is_hero_hired(hero_id):
        return

    var all_hero_ids: Array = []
    for h_id in hero_core.query.get_all_hero_ids():
        if not hero_core.query.is_hero_dead(h_id) and hero_core.query.is_hero_hired(h_id):
            all_hero_ids.append(h_id)
    all_hero_ids.sort()

    var idx := all_hero_ids.find(hero_id)
    if idx >= 0:
        current_page = int(floor(float(idx) / float(HEROES_PER_PAGE)))

        _display.set_selected_hero_id(hero_id)
        _events.set_current_page(current_page)
        _display.set_current_page(current_page)
        _display.update_display(prev_button, next_button)

# ===========================================
# PUBLIC API
# ===========================================
func update_display() -> void:
    # Ensure current page is valid (e.g. after deleting heroes)
    var visible_count = _get_visible_hero_count()
    var total_pages = ceil(float(visible_count) / float(HEROES_PER_PAGE))
    if total_pages == 0: total_pages = 1
    
    if current_page >= total_pages:
        current_page = max(0, total_pages - 1)

    _display.set_current_page(current_page)
    _events.set_current_page(current_page)
    _display.update_display(prev_button, next_button)

# ===========================================
# EVENT HANDLERS
# ===========================================
func _on_prev_button_pressed() -> void:
    if current_page > 0:
        current_page -= 1
        update_display()

func _on_next_button_pressed() -> void:
    if _get_hero_core() == null:
        return
        
    var visible_count = _get_visible_hero_count()
    var total_pages: int = ceil(float(visible_count) / float(HEROES_PER_PAGE))
    
    if current_page < total_pages - 1:
        current_page += 1
        update_display()

func _get_visible_hero_count() -> int:
    var hero_core := _get_hero_core()
    if hero_core == null:
        return 0
    var count = 0
    for hero_id in hero_core.query.get_all_hero_ids():
        if not hero_core.query.is_hero_dead(hero_id) and hero_core.query.is_hero_hired(hero_id):
            count += 1
    return count

func _on_slot_clicked(slot_index: int) -> void:
    _events.handle_slot_clicked(slot_index, _on_hero_selected_internal)

func _on_hero_selected_internal(hero_id: String) -> void:
    _display.set_selected_hero_id(hero_id)
    hero_selected.emit(hero_id)
    var event_bus := _get_event_bus()
    if event_bus and event_bus.has_signal("hero_selected_for_ui"):
        event_bus.hero_selected_for_ui.emit(hero_id)
    update_display()

func _on_hero_created(_hero_id: String, _hero_data: Dictionary) -> void:
    update_display()

func _on_hero_updated(_hero_id: String, _hero_data: Dictionary) -> void:
    update_display()

func _on_squad_changed() -> void:
    update_display()

func _on_heroes_cleared() -> void:
    current_page = 0
    update_display()

func _on_hero_healed_by_hospital(hero_id: String, amount: int) -> void:
    _events.handle_hero_healed_by_hospital(hero_id, amount)
