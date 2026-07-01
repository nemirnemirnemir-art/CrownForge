extends RefCounted
class_name SmithUIBuilder

## Handles UI building and updates for the SmithCraftPanel

const TownAlchemyCraftScript := preload("res://core/town/TownAlchemyCraft.gd")
const FactorUiTexture: Texture2D = preload("res://assets/ui/craft_panel/factor_ui.png")
const ThaleahFont := preload("res://assets/ui/fonts/ThaleahFat.ttf")

const _FONT_OUTLINE_COLOR := Color(0, 0, 0, 1)
const _FONT_OUTLINE_SIZE := 2
const _REQ_ICON_SIZE: float = 32.0

func apply_thaleah_font(label: Label, size_multiplier: float = 1.0) -> void:
    if not label:
        return
    label.add_theme_font_override("font", ThaleahFont)
    var base_size: int
    if label.has_meta("_thaleah_base_font_size"):
        base_size = int(label.get_meta("_thaleah_base_font_size"))
    else:
        var had_override := label.has_theme_font_size_override("font_size")
        if had_override:
            label.remove_theme_font_size_override("font_size")
        base_size = label.get_theme_font_size("font_size")
        if base_size <= 0:
            base_size = 12
        label.set_meta("_thaleah_base_font_size", base_size)
    var final_size: int = max(1, int(base_size * size_multiplier * 1.15))
    label.add_theme_font_size_override("font_size", final_size)
    label.add_theme_color_override("font_outline_color", _FONT_OUTLINE_COLOR)
    label.add_theme_constant_override("outline_size", _FONT_OUTLINE_SIZE)

func rebuild_recipe_rows(recipes_list: VBoxContainer, recipes_visible_rows: int, press_callable: Callable) -> void:
    if not recipes_list:
        return
    var children := recipes_list.get_children()
    for i in range(min(children.size(), recipes_visible_rows)):
        var row := children[i]
        if not (row is HBoxContainer):
            continue
        var icon_btn: TextureButton = row.get_node_or_null("IconButton")
        if icon_btn:
            # We must disconnect old ones if rebuild is called multiple times, but here it's called once in _ready
            if not icon_btn.pressed.is_connected(press_callable.bind(i)):
                icon_btn.pressed.connect(press_callable.bind(i))
        var name_lbl: Label = row.get_node_or_null("Name")
        apply_thaleah_font(name_lbl, 0.825)

func refresh_recipe_rows(recipes_list: VBoxContainer, recipes_visible_rows: int, recipes_scroll: int, selected_recipe_index: int, recipes: Array) -> void:
    if not recipes_list:
        return
    var children := recipes_list.get_children()
    for i in range(min(children.size(), recipes_visible_rows)):
        var idx := recipes_scroll + i
        var row := children[i]
        var icon_btn: TextureButton = row.get_node_or_null("IconButton")
        var name_lbl: Label = row.get_node_or_null("Name")
        if idx < recipes.size():
            var r: Dictionary = recipes[idx]
            if name_lbl:
                name_lbl.text = str(r.get("display_name", ""))
            if icon_btn:
                var icon_path: String = str(r.get("icon_recipe", ""))
                if icon_path != "" and ResourceLoader.exists(icon_path):
                    icon_btn.texture_normal = load(icon_path)
                else:
                    icon_btn.texture_normal = null
                icon_btn.disabled = false
                icon_btn.button_pressed = (idx == selected_recipe_index)
        else:
            if name_lbl:
                name_lbl.text = ""
            if icon_btn:
                icon_btn.texture_normal = null
                icon_btn.disabled = true
                icon_btn.button_pressed = false

func refresh_slot_ui(slot_buttons: Array, slot_status_nodes: Array, slot_state: Array, recipes: Array) -> void:
    for i in range(slot_buttons.size()):
        var b: TextureButton = null
        if i < slot_buttons.size():
            b = slot_buttons[i]
        if not b:
            continue

        var cancel: Button = b.get_node_or_null("Cancel")
        var craft_icon: TextureRect = b.get_node_or_null("CraftIcon")
        var status_node: Control = null
        if i < slot_status_nodes.size():
            status_node = slot_status_nodes[i]
        var status_ribbon: TextureRect = null
        var status_timer: Label = null
        var status_queue: Label = null
        if status_node:
            status_ribbon = status_node.get_node_or_null("Ribbon")
            status_timer = status_node.get_node_or_null("Timer")
            status_queue = status_node.get_node_or_null("Queue")

        var st: Dictionary = slot_state[i]
        var qty_total: int = int(st.get("qty_total", 0))
        var qty_left: int = int(st.get("qty_left", 0))
        var sec_left: int = int(st.get("sec_left", 0))
        var is_crafting: bool = bool(st.get("is_crafting", false)) and qty_left > 0
        var recipe_index: int = int(st.get("recipe_index", -1))
        var custom_icon_path: String = str(st.get("craft_icon_path", ""))

        if cancel:
            cancel.visible = is_crafting
        if craft_icon:
            craft_icon.visible = is_crafting
            if is_crafting:
                var icon_path: String = custom_icon_path
                if icon_path == "" and recipe_index >= 0 and recipe_index < recipes.size():
                    icon_path = str(recipes[recipe_index].get("icon_recipe", ""))
                if icon_path != "" and ResourceLoader.exists(icon_path):
                    craft_icon.texture = load(icon_path)
            else:
                craft_icon.texture = null

        if status_node:
            status_node.visible = true
        if status_ribbon:
            status_ribbon.modulate = Color(1, 1, 1, 1) if is_crafting else Color(1, 1, 1, 0.45)
        if status_timer:
            apply_thaleah_font(status_timer)
            if is_crafting:
                var m: int = int(floor(float(sec_left) / 60.0))
                var s: int = sec_left % 60
                status_timer.text = "%02d:%02d" % [m, s]
            else:
                status_timer.text = "--:--"
        if status_queue:
            apply_thaleah_font(status_queue)
            if is_crafting:
                status_queue.text = "%d/%d" % [qty_left, max(qty_total, qty_left)]
            else:
                status_queue.text = "0/0"

func refresh_ingredient_rows(ingredients_rows: VBoxContainer, ingredient_row_nodes: Array, ingredients: Array) -> Array:
    if not ingredients_rows:
        return ingredient_row_nodes

    for n in ingredient_row_nodes:
        if is_instance_valid(n):
            n.queue_free()
    ingredient_row_nodes.clear()

    var row: HBoxContainer = null
    var in_row: int = 0

    for ing in ingredients:
        if row == null or in_row >= 2:
            row = HBoxContainer.new()
            row.add_theme_constant_override("separation", 24)
            ingredients_rows.add_child(row)
            ingredient_row_nodes.append(row)
            in_row = 0

        var id: String = str(ing.get("id", ""))
        var need: int = int(ing.get("qty", 0))
        var icon_path_override: String = str(ing.get("icon", ""))

        var block := HBoxContainer.new()
        block.add_theme_constant_override("separation", 4)

        var icon := TextureRect.new()
        icon.custom_minimum_size = Vector2(_REQ_ICON_SIZE, _REQ_ICON_SIZE)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var icon_path: String = icon_path_override
        if icon_path == "":
            icon_path = str(TownAlchemyCraftScript.INGREDIENT_ICONS.get(id, ""))
        if icon_path != "" and ResourceLoader.exists(icon_path):
            icon.texture = load(icon_path)
        block.add_child(icon)

        var mul := TextureRect.new()
        mul.custom_minimum_size = Vector2(_REQ_ICON_SIZE, _REQ_ICON_SIZE)
        mul.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        mul.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        mul.texture = FactorUiTexture
        block.add_child(mul)

        var qty := Label.new()
        qty.text = str(need)
        apply_thaleah_font(qty, 2.0)
        block.add_child(qty)

        row.add_child(block)
        ingredient_row_nodes.append(block)
        in_row += 1
        
    return ingredient_row_nodes
