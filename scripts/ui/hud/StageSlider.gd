extends Control
class_name StageSlider

## Stage slider UI component
## Shows 5 stage cards: 2 previous (left, clickable), 1 current (center, with info), 2 next (right, darkened)

signal stage_changed(new_stage: int)

@onready var biome_label: Label = $BiomeLabel
@onready var enemy_counter_label: Label = $EnemyCounterContainer/EnemyCounterLabel
@onready var cards_container: HBoxContainer = $CardsContainer

var current_stage: int = 1
var max_stage_reached: int = 1
var enemies_defeated: int = 0
var total_enemies: int = 10

## Stage card nodes (will be created dynamically)
var stage_cards: Array[Control] = []

func _ready() -> void:
    _create_stage_cards()
    update_display()

func set_current_stage(stage: int, _biome_name: String) -> void:
    current_stage = stage
    # ✅ biome_label removed - info is already shown on the center card
    if biome_label != null:
        biome_label.visible = false  # Hide duplicate label
    _update_stage_cards()  # ✅ Update all cards when stage changes
    update_display()

func set_max_stage_reached(max_stage: int) -> void:
    max_stage_reached = max_stage
    update_display()

func set_enemies_defeated(count: int) -> void:
    enemies_defeated = count
    update_display()

func update_display() -> void:
    if enemy_counter_label != null:
        enemy_counter_label.text = "%d/%d" % [enemies_defeated, total_enemies]
    
    # Update center card with current info
    _update_center_card()
    
    # Update arrows visibility
    # HARD: ARROW VISIBILITY LOGIC - DO NOT CHANGE WITHOUT PERMISSION
    var left_arrow: SliderButton = get_node_or_null("LeftArrow")
    var right_arrow: SliderButton = get_node_or_null("RightArrow")
    
    if left_arrow:
        left_arrow.visible = (current_stage > 1)
        # Ensure it's on top
        left_arrow.move_to_front()
        
    if right_arrow:
        # Show right arrow if we can move forward (current < max)
        right_arrow.visible = (current_stage < max_stage_reached)
        # Ensure it's on top
        right_arrow.move_to_front()

## Create 5 stage cards (2 left, 1 center, 2 right)
func _create_stage_cards() -> void:
    if cards_container == null:
        # print("[StageSlider] ⚠️ cards_container is null!")
        return
    
    # Clear existing cards
    for card in stage_cards:
        if is_instance_valid(card):
            card.queue_free()
    stage_cards.clear()
    
    # Create 5 cards
    for i in range(5):
        var card: Control = _create_stage_card(i)
        cards_container.add_child(card)
        stage_cards.append(card)
    
    _update_stage_cards()

## Create a single stage card
func _create_stage_card(index: int) -> Control:
    # index: 0=left2, 1=left1, 2=center, 3=right1, 4=right2
    var card: Control = Control.new()
    card.custom_minimum_size = Vector2(80, 80)
    card.mouse_filter = Control.MOUSE_FILTER_STOP  # Allow clicks
    
    # Icon
    var icon: TextureRect = TextureRect.new()
    icon.name = "Icon"
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    icon.custom_minimum_size = Vector2(80, 80)
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(icon)
    
    # For center card: add stage number and counter labels
    if index == 2:  # Center card
        var stage_label: Label = Label.new()
        stage_label.name = "StageLabel"
        stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        stage_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
        stage_label.add_theme_font_size_override("font_size", 14)
        stage_label.add_theme_color_override("font_color", Color.WHITE)
        stage_label.position = Vector2(0, 0)
        stage_label.size = Vector2(80, 20)
        card.add_child(stage_label)
        
        # Container for icon + text
        var counter_container: HBoxContainer = HBoxContainer.new()
        counter_container.name = "CounterContainer"
        counter_container.alignment = BoxContainer.ALIGNMENT_CENTER
        counter_container.position = Vector2(0, 110)
        counter_container.size = Vector2(80, 40)
        card.add_child(counter_container)
        
        # Stage Icon (stage.png)
        var stage_icon: TextureRect = TextureRect.new()
        stage_icon.name = "StageIcon"
        # ✅ Correct path found: res://assets/ui/stage_icons/stage.png
        stage_icon.texture = load("res://assets/ui/stage_icons/stage.png") 
        
        stage_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
        stage_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        stage_icon.custom_minimum_size = Vector2(24, 24)
        counter_container.add_child(stage_icon)
        
        var counter_label: Label = Label.new()
        counter_label.name = "CounterLabel"
        counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        # ✅ Font size doubled (was 12, now 24)
        counter_label.add_theme_font_size_override("font_size", 24)
        counter_label.add_theme_color_override("font_color", Color.WHITE)
        counter_label.text = "0/10"
        counter_container.add_child(counter_label)
    
    # Darkening overlay for non-completed stages (right side)
    if index >= 3:  # Right cards
        var dark_overlay: ColorRect = ColorRect.new()
        dark_overlay.name = "DarkOverlay"
        dark_overlay.color = Color(0, 0, 0, 0.5)  # Semi-transparent black
        dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
        dark_overlay.size = Vector2(80, 80)
        card.add_child(dark_overlay)
    
    # Connect click signal
    card.gui_input.connect(_on_stage_card_clicked.bind(index))
    
    return card

## Update all stage cards with correct stage numbers and icons
func _update_stage_cards() -> void:
    if stage_cards.size() != 5:
        return
    
    # Calculate stage numbers for each card
    # index: 0=left2, 1=left1, 2=center, 3=right1, 4=right2
    var stage_numbers: Array[int] = [
        current_stage - 2,  # left2
        current_stage - 1,  # left1
        current_stage,      # center
        current_stage + 1,  # right1
        current_stage + 2   # right2
    ]
    
    for i in range(5):
        var card: Control = stage_cards[i]
        if not is_instance_valid(card):
            continue
        
        var stage_num: int = stage_numbers[i]
        var icon: TextureRect = card.get_node_or_null("Icon")
        
        # Hide card if stage number is invalid (< 1)
        if stage_num < 1:
            card.visible = false
            continue
        
        card.visible = true
        
        # Load icon for this stage
        var icon_path: String = _get_stage_icon_path(stage_num)
        if icon != null and icon_path != "":
            if ResourceLoader.exists(icon_path):
                var texture: Texture2D = load(icon_path)
                if texture != null:
                    icon.texture = texture
                else:
                    icon.texture = null
            else:
                icon.texture = null
        
        # Update center card labels
        if i == 2:  # Center card
            var stage_label: Label = card.get_node_or_null("StageLabel")
            var counter_container: HBoxContainer = card.get_node_or_null("CounterContainer")
            var counter_label: Label = null
            if counter_container:
                counter_label = counter_container.get_node_or_null("CounterLabel")
                
            if stage_label != null:
                if StageCore:
                    stage_label.text = StageCore.get_biome_name(stage_num)
                else:
                    stage_label.text = "Forest %d" % stage_num
            if counter_label != null:
                counter_label.text = "%d/%d" % [enemies_defeated, total_enemies]
        
        # Update dark overlay visibility for right cards (non-completed stages)
        if i >= 3:  # Right cards
            var dark_overlay: ColorRect = card.get_node_or_null("DarkOverlay")
            # ✅ Stage is considered completed if it is <= max_stage_reached
            var is_completed: bool = (stage_num <= max_stage_reached)
            if dark_overlay != null:
                dark_overlay.visible = not is_completed  # Show dark overlay if not completed
        
        # Update clickability: all completed stages are clickable
        if i == 2:  # Center card - not clickable
            card.mouse_filter = Control.MOUSE_FILTER_IGNORE
        else:  # Left and right cards - clickable if completed
            # ✅ Stage is considered completed if it is <= max_stage_reached
            var is_completed: bool = (stage_num <= max_stage_reached and stage_num >= 1)
            card.mouse_filter = Control.MOUSE_FILTER_STOP if is_completed else Control.MOUSE_FILTER_IGNORE

## Update center card with current info
func _update_center_card() -> void:
    if stage_cards.size() < 3:
        return
    
    var center_card: Control = stage_cards[2]
    if not is_instance_valid(center_card):
        return
    
    var counter_container: HBoxContainer = center_card.get_node_or_null("CounterContainer")
    if counter_container:
        var counter_label: Label = counter_container.get_node_or_null("CounterLabel")
        if counter_label != null:
            counter_label.text = "%d/%d" % [enemies_defeated, total_enemies]

## Handle click on stage card
func _on_stage_card_clicked(event: InputEvent, card_index: int) -> void:
    if not event is InputEventMouseButton:
        return
    
    var mouse_event: InputEventMouseButton = event as InputEventMouseButton
    if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
        return
    
    # Only completed stages are clickable (left and right cards, but not center)
    if card_index == 2:
        return
    
    # Calculate stage number for clicked card
    # card_index: 0=left2, 1=left1, 3=right1, 4=right2
    var stage_offset: int = card_index - 2  # left2: -2, left1: -1, right1: +1, right2: +2
    var stage_num: int = current_stage + stage_offset
    
    # ✅ Allow clicking completed stages (stage_num <= max_stage_reached)
    if stage_num > max_stage_reached or stage_num < 1:
        return
    
    # Switch to clicked stage
    # print("[StageSlider] 🎯 Clicked on stage %d (card index %d)" % [stage_num, card_index])
    current_stage = stage_num
    stage_changed.emit(current_stage)
    _update_stage_cards()
    update_display()

## Get icon path for a stage number
func _get_stage_icon_path(stage_num: int) -> String:
    # Check if Crypt biome
    if stage_num >= 81 and stage_num <= 161:
        return "res://assets/ui/stage_icons/crypt_stage.png"
    
    # Forest biome (default)
    return "res://assets/ui/stage_icons/jungle.png"

# Old _load_stage_icon() removed - replaced with _create_stage_cards() and _update_stage_cards()

## Handle left arrow click
# HARD: DO NOT MODIFY THIS FUNCTION WITHOUT USER PERMISSION
# HARD: DO NOT MODIFY THIS FUNCTION WITHOUT USER PERMISSION
func _on_left_arrow_pressed() -> void:
    if current_stage > 1:
        # print("[StageSlider] ⬅️ Left arrow clicked. Going to stage %d" % (current_stage - 1))
        current_stage -= 1
        stage_changed.emit(current_stage)
        _update_stage_cards()
        update_display()

## Handle right arrow click
# HARD: DO NOT MODIFY THIS FUNCTION WITHOUT USER PERMISSION
# HARD: DO NOT MODIFY THIS FUNCTION WITHOUT USER PERMISSION
func _on_right_arrow_pressed() -> void:
    # Ensure max_stage_reached is at least current_stage to prevent getting stuck
    if max_stage_reached < current_stage:
        max_stage_reached = current_stage

    if current_stage < max_stage_reached:
        # print("[StageSlider] ➡️ Right arrow clicked. Going to stage %d" % (current_stage + 1))
        current_stage += 1
        stage_changed.emit(current_stage)
        _update_stage_cards()
        update_display()
