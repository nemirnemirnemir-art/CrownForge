extends CanvasLayer

## Debug menu for spawning heroes and mobs for testing combat.
## Toggle with F10. Delegates all logic to focused sub-modules.

const DebugHeroTabScript = preload("res://scripts/ui/debug/modules/DebugHeroTab.gd")
const DebugMobTabScript = preload("res://scripts/ui/debug/modules/DebugMobTab.gd")
const DebugItemTabScript = preload("res://scripts/ui/debug/modules/DebugItemTab.gd")
const DebugProphecyTabScript = preload("res://scripts/ui/debug/modules/DebugProphecyTab.gd")
const DebugHeroItemsTabScript = preload("res://scripts/ui/debug/modules/DebugHeroItemsTab.gd")
const CatalogScript = preload("res://scripts/ui/debug/modules/DebugSpawnMenuCatalog.gd")
const HeroIdResolverScript = preload("res://scripts/ui/debug/modules/DebugHeroIdResolver.gd")
const SpawnActionsScript = preload("res://scripts/ui/debug/modules/DebugSpawnActions.gd")

var _panel: PanelContainer
var _hero_tab: DebugHeroTab
var _mob_tab: DebugMobTab
var _item_tab: DebugItemTab
var _prophecy_tab = null
var _hero_items_tab: DebugHeroItemsTab
var _actions: DebugSpawnActions

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _title_bar: Control

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process_input(true)
    layer = 100

    _hero_tab = DebugHeroTabScript.new()
    _mob_tab = DebugMobTabScript.new()
    _item_tab = DebugItemTabScript.new()
    _prophecy_tab = DebugProphecyTabScript.new()
    _hero_items_tab = DebugHeroItemsTabScript.new()
    _actions = SpawnActionsScript.new()
    _actions.setup(self)

    _build_ui()
    visible = false
    _setup_qa_panel()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_F10:
            visible = not visible
            if visible:
                _actions.find_game_scene()
        elif event.keycode == KEY_F5:
            _actions.find_game_scene()
            if _actions.game_scene and _actions.game_scene.has_method("open_reward_menu_prophecy"):
                _actions.game_scene.open_reward_menu_prophecy()
        elif event.keycode == KEY_F9:
            _actions.on_open_artifact_debug_grid()
            return

    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                if _title_bar and _is_point_in_title_bar(event.position):
                    _dragging = true
                    _drag_offset = _panel.position - event.position
            else:
                _dragging = false

    if event is InputEventMouseMotion and _dragging:
        _panel.position = event.position + _drag_offset

func _is_point_in_title_bar(point: Vector2) -> bool:
    if not _title_bar:
        return false
    var rect := Rect2(_panel.global_position, Vector2(_panel.size.x, 40))
    return rect.has_point(point)

func _build_ui() -> void:
    _panel = PanelContainer.new()
    _panel.custom_minimum_size = Vector2(520, 760)
    _panel.anchor_left = 1.0
    _panel.anchor_top = 0.0
    _panel.anchor_right = 1.0
    _panel.anchor_bottom = 0.0
    _panel.offset_left = -530
    _panel.offset_top = 10
    _panel.offset_right = -10
    _panel.offset_bottom = 770
    add_child(_panel)

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
    style.border_color = Color(0.4, 0.4, 0.5)
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    _panel.add_theme_stylebox_override("panel", style)

    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _panel.add_child(scroll)

    var main_vbox := VBoxContainer.new()
    main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(main_vbox)

    _title_bar = PanelContainer.new()
    var title_style := StyleBoxFlat.new()
    title_style.bg_color = Color(0.2, 0.2, 0.3, 1.0)
    title_style.set_corner_radius_all(4)
    _title_bar.add_theme_stylebox_override("panel", title_style)
    main_vbox.add_child(_title_bar)

    var title := Label.new()
    title.text = "DEBUG SPAWN (drag to move)"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 20)
    _title_bar.add_child(title)

    main_vbox.add_child(HSeparator.new())

    var resolver := HeroIdResolverScript.new()
    var hero_ids: Array[String] = resolver.get_hero_ids(
        CatalogScript.DEBUG_BARRACKS_DIRS,
        CatalogScript.DEBUG_EXTRA_HERO_IDS
    )
    _actions.hero_scene_map = resolver.build_hero_scene_map(hero_ids)

    _build_collapsible_section(main_vbox, "Keybindings", func(vbox: VBoxContainer) -> void:
        _build_keybinds_section(vbox)
    , true)

    _build_collapsible_section(main_vbox, "Heroes", func(vbox: VBoxContainer) -> void:
        _hero_tab.build_ui(
            vbox,
            hero_ids,
            Callable(_actions, "on_spawn_hero"),
            Callable(_actions, "on_spawn_25_crossbowmen"),
            Callable(_actions, "on_spawn_smallbones")
        )
    , false)

    _build_collapsible_section(main_vbox, "Hero Debug", func(vbox: VBoxContainer) -> void:
        _build_hero_debug_section(vbox)
    , true)

    _build_collapsible_section(main_vbox, "HeroItems", func(vbox: VBoxContainer) -> void:
        _hero_items_tab.build_ui(
            vbox,
            Callable(_actions, "on_equip_debug_item"),
            Callable(_actions, "on_strip_all_items")
        )
    , false)

    _build_collapsible_section(main_vbox, "Mobs", func(vbox: VBoxContainer) -> void:
        _mob_tab.build_ui(
            vbox,
            CatalogScript.MOB_SCENES,
            Callable(_actions, "on_spawn_homeseeker_boss"),
            Callable(_actions, "on_spawn_minotaur_boss"),
            Callable(_actions, "on_spawn_dragon"),
            Callable(_actions, "on_spawn_mob"),
            Callable(_actions, "on_clear_mobs")
        )
    , false)

    _build_collapsible_section(main_vbox, "Spells", func(vbox: VBoxContainer) -> void:
        _item_tab.build_spells_ui(
            vbox,
            CatalogScript.SPELL_CONFIGS,
            Callable(_actions, "on_add_spell")
        )
    , false)

    _build_collapsible_section(main_vbox, "Buildings", func(vbox: VBoxContainer) -> void:
        _item_tab.build_buildings_ui(
            vbox,
            Callable(_actions, "on_open_base_production_rewards"),
            Callable(_actions, "on_open_levy_barracks_rewards"),
            Callable(_actions, "on_open_artifact_rewards"),
            Callable(_actions, "on_open_artifact_debug_grid"),
            Callable(),  # on_open_troop_bonus_rewards - removed
            Callable(_actions, "on_open_building_upgrade_rewards"),
            Callable(_actions, "on_open_resource_rewards"),
            Callable(_actions, "on_open_spells_rewards"),
            Callable(_actions, "on_open_legendary_spells_rewards")
        )
    , false)

    _build_collapsible_section(main_vbox, "Prophecy", func(vbox: VBoxContainer) -> void:
        _prophecy_tab.build_ui(vbox)
    , false)

    _build_collapsible_section(main_vbox, "Wave Control", func(vbox: VBoxContainer) -> void:
        _build_wave_control_section(vbox)
    , true)

    # _build_collapsible_section(main_vbox, "Troop Bonuses", func(vbox: VBoxContainer) -> void:
    #     _item_tab.build_troop_bonuses_ui(
    #         vbox,
    #         Callable(_actions, "on_add_troop_bonus"),
    #         Callable(_actions, "on_add_all_resources"),
    #         Callable(_actions, "on_add_denarii"),
    #         Callable(_actions, "on_add_morale"),
    #         Callable(_actions, "on_reset_morale"),
    #         Callable(_actions, "get_unit_class_name")
    #     )
    # , true)

    var close_btn := Button.new()
    close_btn.text = "Close (F10)"
    close_btn.pressed.connect(func(): visible = false)
    main_vbox.add_child(close_btn)

func _build_keybinds_section(parent: VBoxContainer) -> void:
    var keybinds_label := Label.new()
    keybinds_label.text = "KEYBINDS"
    keybinds_label.add_theme_font_size_override("font_size", 28)
    parent.add_child(keybinds_label)

    var keybinds: Array = [
        ["E", "Unlock all AVAILABLE upgrades"],
        ["R", "Unlock ALL upgrades in game (~193)"],
        ["DEL", "Kill selected hero"],
        ["X", "Tavern buff + gold/resources"],
        ["N", "Deal 1 damage to castle (DEBUG)"],
        ["Q", "Cast Meteorite spell at mouse (test damage)"],
        ["Z", "Test buff + all resources"],
        ["K", "Spawn Homeseeker Boss"],
        ["L", "Spawn Minotaur Boss"],
        ["B", "Spawn Goblin Bandit"],
        ["P", "Open Base Production reward"],
        ["T", "Open Trader menu"],
        ["G", "Open Town menu"],
        ["F9", "Open Artifact Debug Grid"],
        ["F10", "Toggle Debug Spawn Menu"],
        ["F11", "Toggle Building Upgrade QA Panel"],
        ["F5", "Open Prophecy reward"],
    ]
    for kb in keybinds:
        var hbox := HBoxContainer.new()
        hbox.custom_minimum_size = Vector2(0, 40)
        var key_label := Label.new()
        key_label.text = "[%s]" % kb[0]
        key_label.custom_minimum_size = Vector2(96, 0)
        key_label.add_theme_font_size_override("font_size", 24)
        key_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
        hbox.add_child(key_label)
        var desc_label := Label.new()
        desc_label.text = kb[1]
        desc_label.add_theme_font_size_override("font_size", 24)
        desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hbox.add_child(desc_label)
        parent.add_child(hbox)

    parent.add_child(HSeparator.new())

func _build_wave_control_section(parent: VBoxContainer) -> void:
    var buttons := [
        ["Jump to P1", Callable(_actions, "on_jump_to_prophecy_1")],
        ["Jump to P2", Callable(_actions, "on_jump_to_prophecy_2")],
        ["Jump to P3", Callable(_actions, "on_jump_to_prophecy_3")],
        ["Jump to P4 (Boss)", Callable(_actions, "on_jump_to_prophecy_4")],
        ["Force Boss Now", Callable(_actions, "on_force_boss_wave")],
        ["Skip to Next Level", Callable(_actions, "on_skip_to_next_prophecy")],
    ]
    for btn_data in buttons:
        var btn := Button.new()
        btn.text = btn_data[0]
        btn.pressed.connect(func(): btn_data[1].call())
        parent.add_child(btn)

func _build_hero_debug_section(parent: VBoxContainer) -> void:
    var buttons := [
        ["+1 XP", Callable(_actions, "on_hero_add_xp").bind(1)],
        ["+5 XP", Callable(_actions, "on_hero_add_xp").bind(5)],
        ["Kill Hero", Callable(_actions, "on_hero_kill")],
        ["Level Up", Callable(_actions, "on_hero_level_up")],
    ]
    for btn_data in buttons:
        var btn := Button.new()
        btn.text = btn_data[0]
        btn.pressed.connect(func(): btn_data[1].call())
        parent.add_child(btn)

func _setup_qa_panel() -> void:
    var qa_panel_script = load("res://scripts/ui/debug/BuildingUpgradeQaPanel.gd")
    if qa_panel_script:
        var qa_panel = qa_panel_script.new()
        get_parent().add_child(qa_panel)
        print("[DebugSpawnMenu] QA Panel added (F11 to toggle)")

func _build_collapsible_section(parent_vbox: VBoxContainer, title: String, build_fn: Callable, starts_open: bool) -> void:
    var header_btn := Button.new()
    header_btn.text = ("v " if starts_open else "> ") + title
    header_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
    header_btn.flat = true
    parent_vbox.add_child(header_btn)

    var content_vbox := VBoxContainer.new()
    content_vbox.visible = starts_open
    parent_vbox.add_child(content_vbox)

    build_fn.call(content_vbox)

    header_btn.pressed.connect(func() -> void:
        content_vbox.visible = not content_vbox.visible
        header_btn.text = ("v " if content_vbox.visible else "> ") + title
    )
