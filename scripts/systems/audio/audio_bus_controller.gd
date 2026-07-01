extends Node
class_name AudioBusController

func ensure_buses(bus_names: Array[StringName]) -> void:
    for bn in bus_names:
        _ensure_bus(bn)

func _ensure_bus(bus_name: StringName) -> int:
    var idx := AudioServer.get_bus_index(String(bus_name))
    if idx != -1:
        return idx

    AudioServer.add_bus(AudioServer.bus_count)
    var new_idx := AudioServer.bus_count - 1
    AudioServer.set_bus_name(new_idx, String(bus_name))

    if String(bus_name) != "Master":
        var master_idx := AudioServer.get_bus_index("Master")
        if master_idx != -1:
            AudioServer.set_bus_send(new_idx, "Master")

    return new_idx

func set_bus_volume_linear(bus_name: StringName, linear: float) -> void:
    var idx := _ensure_bus(bus_name)
    var l := clampf(linear, 0.0, 1.0)
    AudioServer.set_bus_volume_db(idx, linear_to_db(l))

func set_bus_muted(bus_name: StringName, muted: bool) -> void:
    var idx := _ensure_bus(bus_name)
    AudioServer.set_bus_mute(idx, muted)

func get_bus_volume_linear(bus_name: StringName) -> float:
    var idx := AudioServer.get_bus_index(String(bus_name))
    if idx == -1:
        return 1.0
    return db_to_linear(AudioServer.get_bus_volume_db(idx))
