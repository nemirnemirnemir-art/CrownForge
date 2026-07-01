extends SceneTree

const MapSlotPopupControllerScript := preload("res://scripts/map_slot/MapSlotPopupController.gd")


class FakeSpecialHandler:
    extends RefCounted

    var ready: bool = true
    var mode: int = 2
    var options: Array = ["gold", "spells"]

    func is_ready() -> bool:
        return ready

    func get_mode() -> int:
        return mode

    func get_ui_options() -> Array:
        return options.duplicate(true)


class FakePopup:
    extends Control

    var setup_calls: Array = []
    var title_calls: Array[String] = []

    func setup(value) -> void:
        setup_calls.append(value)

    func setup_options(options: Array, mode: int) -> void:
        setup_calls.append({"options": options.duplicate(true), "mode": mode})

    func set_title(value: String) -> void:
        title_calls.append(value)

    func enable_overlay_mode() -> void:
        top_level = true
        z_as_relative = false
        z_index = 3000


class FakeVzor:
    extends Node2D

    var cancel_calls: int = 0

    func cancel_drag() -> void:
        cancel_calls += 1


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var controller = MapSlotPopupControllerScript.new()
    if controller == null:
        push_error("[test_mapslot_popup_controller] failed to instantiate controller")
        quit(1)
        return

    var root := Node2D.new()
    get_root().add_child(root)

    var vzor := FakeVzor.new()
    root.add_child(vzor)
    vzor.add_to_group("vzor_zone")

    var market_popup := Control.new()
    market_popup.visible = true
    root.add_child(market_popup)
    market_popup.add_to_group("map_slot_special_popup")

    var basic_popup := FakePopup.new()
    basic_popup.custom_minimum_size = Vector2(120.0, 90.0)
    basic_popup.visible = false
    root.add_child(basic_popup)
    basic_popup.add_to_group("map_slot_special_popup")

    var research_popup := FakePopup.new()
    research_popup.custom_minimum_size = Vector2(180.0, 110.0)
    research_popup.visible = false
    root.add_child(research_popup)
    research_popup.add_to_group("map_slot_special_popup")

    var foreign_popup := Control.new()
    foreign_popup.visible = true
    root.add_child(foreign_popup)
    foreign_popup.add_to_group("map_slot_special_popup")

    var handler := FakeSpecialHandler.new()
    var viewport_rect := Rect2(Vector2.ZERO, Vector2(300.0, 200.0))

    var opened_basic: bool = controller.toggle_basic_construction_ui(
        basic_popup,
        market_popup,
        research_popup,
        handler,
        Vector2(40.0, 140.0),
        viewport_rect,
        true
    )
    if not opened_basic or not basic_popup.visible:
        push_error("[test_mapslot_popup_controller] basic popup should open when handler is ready")
        quit(1)
        return
    if market_popup.visible:
        push_error("[test_mapslot_popup_controller] opening basic popup must hide market popup")
        quit(1)
        return
    if foreign_popup.visible:
        push_error("[test_mapslot_popup_controller] opening basic popup must hide foreign special popups from other slots")
        quit(1)
        return
    if basic_popup.setup_calls.is_empty():
        push_error("[test_mapslot_popup_controller] basic popup setup was not called")
        quit(1)
        return
    if vzor.cancel_calls != 1:
        push_error("[test_mapslot_popup_controller] opening special popup must cancel active vzor drag")
        quit(1)
        return

    handler.ready = false
    controller.toggle_basic_construction_ui(basic_popup, market_popup, research_popup, handler, Vector2(40.0, 140.0), viewport_rect, true)
    if basic_popup.visible:
        push_error("[test_mapslot_popup_controller] basic popup must close when handler is not ready")
        quit(1)
        return

    handler.ready = true
    var opened_research: bool = controller.toggle_research_table_ui(
        research_popup,
        market_popup,
        basic_popup,
        handler,
        "research_laboratory",
        Vector2(260.0, 140.0),
        viewport_rect,
        true
    )
    if not opened_research or not research_popup.visible:
        push_error("[test_mapslot_popup_controller] research popup should open")
        quit(1)
        return
    if basic_popup.visible:
        push_error("[test_mapslot_popup_controller] opening research popup must hide basic popup")
        quit(1)
        return
    if vzor.cancel_calls != 2:
        push_error("[test_mapslot_popup_controller] research popup opening must cancel vzor drag each time")
        quit(1)
        return
    if research_popup.title_calls.is_empty() or research_popup.title_calls[-1] != "Research Laboratory":
        push_error("[test_mapslot_popup_controller] research popup title mismatch")
        quit(1)
        return
    if absf(research_popup.global_position.x - 68.0) > 0.01:
        push_error("[test_mapslot_popup_controller] top-level popup must position from slot global X, expected 68 got %.2f" % research_popup.global_position.x)
        quit(1)
        return
    if absf(research_popup.global_position.y - 22.0) > 0.01:
        push_error("[test_mapslot_popup_controller] top-level popup must position from slot global Y, expected 22 got %.2f" % research_popup.global_position.y)
        quit(1)
        return
    if not research_popup.top_level or research_popup.z_index < 3000:
        push_error("[test_mapslot_popup_controller] popup controller must force overlay mode for selector popups")
        quit(1)
        return

    print("[test_mapslot_popup_controller] PASS")
    quit(0)
