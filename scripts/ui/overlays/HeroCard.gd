extends Control

## Hero card UI panel displaying selected hero stats and test buttons
## Controller coordinating all HeroCard modules

## Modules are globally accessible via class_name

## UI References
@onready var prev_button: SliderButton = $MainContainer/RightPanel/HeaderContainer/PrevButton
@onready var next_button: SliderButton = $MainContainer/RightPanel/HeaderContainer/NextButton
@onready var name_label: Label = $MainContainer/RightPanel/HeaderContainer/NameLabel
@onready var hp_label: Label = $MainContainer/RightPanel/StatsPanel/StatsContainer/HPLabel
@onready var damage_label: Label = $MainContainer/RightPanel/StatsPanel/StatsContainer/DamageLabel
@onready var level_label: Label = $MainContainer/RightPanel/StatsPanel/StatsContainer/LevelLabel
@onready var xp_label: Label = $MainContainer/RightPanel/StatsPanel/StatsContainer/XPLabel
@onready var equipment_container: GridContainer = $MainContainer/RightPanel/ItemsBackgroundContainer/EquipmentContainer
@onready var buff_grid: GridContainer = $BuffGrid/BuffGrid

@onready var close_button: TextureButton = $MainContainer/RightPanel/HeaderContainer/CloseButton

## Module instances
var _display: HeroCardDisplay
var _equipment: HeroCardEquipment
var _buffs: HeroCardBuffs
var _perks: HeroCardPerks
var _buttons: HeroCardButtons
var _signals: HeroCardSignals

## State
var selected_hero_id: String = ""

func _ready() -> void:
    # Добавляем в группу для поиска
    add_to_group("hero_card")

    if EventBus and EventBus.has_signal("hero_selected_for_ui"):
        if not EventBus.hero_selected_for_ui.is_connected(_on_hero_selected):
            EventBus.hero_selected_for_ui.connect(_on_hero_selected)
    
    if HeroCore:
        HeroCore.hero_updated.connect(_on_hero_updated)
        HeroCore.hero_hp_changed.connect(_on_hero_hp_changed)
    
    _initialize_modules()
    
    _connect_buttons()
    
    # Не вызываем update_display() здесь, так как selected_hero_id еще пуст
    hide()

func _on_hero_updated(hero_id: String, _data: Dictionary) -> void:
    if visible and selected_hero_id == hero_id:
        update_display()

func _on_hero_hp_changed(hero_id: String, _new_hp: float, _max_hp: float) -> void:
    if visible and selected_hero_id == hero_id:
        # Можно обновлять только HP бар для оптимизации, но пока обновим всё
        update_display()

func _initialize_modules() -> void:
    _display = HeroCardDisplay.new()
    _display.initialize(self, name_label, hp_label, damage_label, level_label, xp_label)
    
    _equipment = HeroCardEquipment.new()
    _equipment.initialize(equipment_container)
    
    _buffs = HeroCardBuffs.new()
    _buffs.initialize(buff_grid)
    
    _perks = HeroCardPerks.new()
    _perks.initialize(self)
    
    _buttons = HeroCardButtons.new()
    _buttons.initialize()
    _buttons.set_selected_hero_id(selected_hero_id)
    
    _signals = HeroCardSignals.new()
    _signals.initialize(self, _on_hero_updated_signal, update_display, Callable(), Callable(), Callable(), Callable())
    _signals.set_selected_hero_id(selected_hero_id)
    
    # print("[HeroCard] ✅ All modules initialized")

func _connect_buttons() -> void:
    if prev_button:
        prev_button.pressed.connect(_on_prev_pressed)
    if next_button:
        next_button.pressed.connect(_on_next_pressed)

    if close_button:
        close_button.pressed.connect(_on_close_pressed)
        close_button.focus_mode = Control.FOCUS_NONE

func _on_close_pressed() -> void:
    selected_hero_id = ""
    hide()

func _on_prev_pressed() -> void:
    _buttons.on_prev_hero_pressed()
    update_display()

func _on_next_pressed() -> void:
    _buttons.on_next_hero_pressed()
    update_display()

func update_display() -> void:
    _display.update_display(selected_hero_id)
    
    if selected_hero_id != "" and HeroCore != null and HeroCore.query.has_hero(selected_hero_id):
        _equipment.update_equipment(selected_hero_id)
        _buffs.update_buff_slots(selected_hero_id)

    if selected_hero_id != "" and HeroCore != null and HeroCore.heroes.has(selected_hero_id):
        var hero = HeroCore.heroes[selected_hero_id]
        _perks.update_perks(hero)

func select_hero(hero_id: String) -> void:
    selected_hero_id = hero_id
    _buttons.set_selected_hero_id(hero_id)
    _signals.set_selected_hero_id(hero_id)
    update_display()
    
    if selected_hero_id != "":
        show()
    else:
        hide()

func _on_hero_selected(hero_id: String) -> void:
    select_hero(hero_id)

## === BUTTON HANDLERS ===

## === SIGNAL HANDLERS ===

func _on_hero_updated_signal() -> void:
    update_display()
