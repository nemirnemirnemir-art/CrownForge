extends Node
class_name MusicPlayer

var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _active_is_a: bool = true
var _task_id: int = 0
var _task: Dictionary = {}

var _layer_players: Dictionary = {} # StringName -> AudioStreamPlayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    _a = AudioStreamPlayer.new()
    _a.name = "MusicA"
    _a.bus = "Music"
    _a.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_a)

    _b = AudioStreamPlayer.new()
    _b.name = "MusicB"
    _b.bus = "Music"
    _b.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_b)

func _process(_delta: float) -> void:
    if _task.is_empty():
        return

    var now: float = Time.get_ticks_msec() / 1000.0
    var start_t: float = float(_task.get("start_t", now))
    var duration: float = maxf(0.001, float(_task.get("duration", 0.001)))
    var t: float = clampf((now - start_t) / duration, 0.0, 1.0)

    var mode: String = String(_task.get("mode", ""))
    if mode == "crossfade":
        var from_players: Array = _task.get("from_players", [])
        var to_players: Array = _task.get("to_players", [])
        var from_db0s: Array = _task.get("from_db0s", [])
        var to_db1s: Array = _task.get("to_db1s", [])
        var cleanup: Array = _task.get("cleanup", [])

        for i in range(to_players.size()):
            var p_to: AudioStreamPlayer = to_players[i]
            if p_to == null:
                continue
            var v1: float = 0.0
            if i < to_db1s.size():
                v1 = float(to_db1s[i])
            p_to.volume_db = lerpf(-80.0, v1, t)

        for i in range(from_players.size()):
            var p_from: AudioStreamPlayer = from_players[i]
            if p_from == null:
                continue
            var v0: float = p_from.volume_db
            if i < from_db0s.size():
                v0 = float(from_db0s[i])
            p_from.volume_db = lerpf(v0, -80.0, t)

        if t >= 1.0:
            for p_from in from_players:
                if p_from and p_from.playing:
                    p_from.stop()
            for n in cleanup:
                if n and is_instance_valid(n):
                    n.queue_free()
            _task.clear()
        return

    if mode == "fade_out":
        var players: Array = _task.get("players", [])
        var from_db0s: Array = _task.get("from_db0s", [])
        var cleanup: Array = _task.get("cleanup", [])

        for i in range(players.size()):
            var p: AudioStreamPlayer = players[i]
            if p == null:
                continue
            var v0: float = p.volume_db
            if i < from_db0s.size():
                v0 = float(from_db0s[i])
            p.volume_db = lerpf(v0, -80.0, t)

        if t >= 1.0:
            for p in players:
                if p and p.playing:
                    p.stop()
            for n in cleanup:
                if n and is_instance_valid(n):
                    n.queue_free()
            _task.clear()
        return

    _task.clear()

func play(data, crossfade_sec: float = 1.0) -> void:
    if data == null:
        return
    if not ("stream" in data):
        return
    if data.stream == null:
        return

    var fade := maxf(0.0, crossfade_sec)
    var from := _get_active()
    var to := _get_inactive()

    _task_id += 1
    _task.clear()

    to.stop()
    to.stream = data.stream
    to.bus = String(data.bus) if ("bus" in data and data.bus != &"") else "Music"
    to.volume_db = -80.0
    to.play()

    var old_layers := _layer_players
    _layer_players = {}
    var new_layers: Array = _spawn_layers_from_data(data)

    if fade <= 0.0 or (not from.playing):
        if from.playing:
            from.stop()
        to.volume_db = float(data.volume_db) if ("volume_db" in data) else 0.0
        _finish_layers_immediate(old_layers, new_layers)
        _active_is_a = (to == _a)
        return

    _task = {
        "id": _task_id,
        "mode": "crossfade",
        "start_t": Time.get_ticks_msec() / 1000.0,
        "duration": fade,
        "from_players": _make_from_players(from, old_layers),
        "to_players": _make_to_players(to, new_layers),
        "from_db0s": _make_from_db0s(from, old_layers),
        "to_db1s": _make_to_db1s(data, new_layers),
        "cleanup": _layers_to_cleanup(old_layers),
    }
    _active_is_a = (to == _a)

func stop(fade_out_sec: float = 1.0) -> void:
    var p := _get_active()
    if p == null or not p.playing:
        return

    var fade := maxf(0.0, fade_out_sec)
    if fade <= 0.0:
        p.stop()
        _free_layers_now(_layer_players)
        _layer_players.clear()
        return

    _task_id += 1
    _task = {
        "id": _task_id,
        "mode": "fade_out",
        "start_t": Time.get_ticks_msec() / 1000.0,
        "duration": fade,
        "players": _make_stop_players(p, _layer_players),
        "from_db0s": _make_stop_db0s(p, _layer_players),
        "cleanup": _layers_to_cleanup(_layer_players),
    }

    _layer_players = {}

func _get_active() -> AudioStreamPlayer:
    return _a if _active_is_a else _b

func _get_inactive() -> AudioStreamPlayer:
    return _b if _active_is_a else _a

func get_active_player() -> AudioStreamPlayer:
    return _get_active()

func set_layer_enabled(layer_id: StringName, enabled: bool, fade_sec: float = 0.5) -> void:
    var p: AudioStreamPlayer = _layer_players.get(layer_id)
    if p == null:
        return
    if not enabled:
        _fade_out_single_layer(layer_id, p, fade_sec)
        return
    # Enabling an already-playing layer: just restore its configured volume if present.
    var v: Variant = p.get_meta("target_db")
    if v == null:
        return
    _fade_in_single_layer(p, float(v), fade_sec)

func _spawn_layers_from_data(data) -> Array:
    var created: Array = []
    if data == null:
        return created
    if not ("layers" in data):
        return created
    if data.layers == null:
        return created

    for layer in data.layers:
        if layer == null:
            continue
        if not ("id" in layer and "stream" in layer):
            continue
        if layer.id == &"" or layer.stream == null:
            continue

        var lp := AudioStreamPlayer.new()
        lp.name = "Layer_%s" % String(layer.id)
        lp.bus = "Music"
        lp.process_mode = Node.PROCESS_MODE_ALWAYS
        lp.stream = layer.stream
        lp.volume_db = -80.0
        lp.set_meta("target_db", float(layer.volume_db) if ("volume_db" in layer) else 0.0)
        add_child(lp)
        lp.play()

        _layer_players[layer.id] = lp
        created.append(lp)

    return created

func _finish_layers_immediate(old_layers: Dictionary, new_layers: Array) -> void:
    for k in old_layers.keys():
        var p_old: AudioStreamPlayer = old_layers[k]
        if p_old and is_instance_valid(p_old):
            p_old.stop()
            p_old.queue_free()
    for p_new in new_layers:
        if p_new == null:
            continue
        var v_meta: Variant = p_new.get_meta("target_db")
        if v_meta != null:
            p_new.volume_db = float(v_meta)

func _layers_to_cleanup(layers: Dictionary) -> Array:
    var out: Array = []
    for k in layers.keys():
        var p: AudioStreamPlayer = layers[k]
        if p and is_instance_valid(p):
            out.append(p)
    return out

func _make_from_players(from: AudioStreamPlayer, old_layers: Dictionary) -> Array:
    var out: Array = [from]
    for k in old_layers.keys():
        var p: AudioStreamPlayer = old_layers[k]
        if p and is_instance_valid(p):
            out.append(p)
    return out

func _make_to_players(to: AudioStreamPlayer, new_layers: Array) -> Array:
    var out: Array = [to]
    for p in new_layers:
        if p and is_instance_valid(p):
            out.append(p)
    return out

func _make_from_db0s(from: AudioStreamPlayer, old_layers: Dictionary) -> Array:
    var out: Array = [from.volume_db]
    for k in old_layers.keys():
        var p: AudioStreamPlayer = old_layers[k]
        if p and is_instance_valid(p):
            out.append(p.volume_db)
    return out

func _make_to_db1s(data, new_layers: Array) -> Array:
    var initial_db: float = 0.0
    if "volume_db" in data:
        initial_db = float(data.volume_db)
    var out: Array = [initial_db]
    for p in new_layers:
        if p == null:
            continue
        var v_meta: Variant = p.get_meta("target_db")
        out.append(float(v_meta) if v_meta != null else 0.0)
    return out

func _make_stop_players(active: AudioStreamPlayer, layers: Dictionary) -> Array:
    var out: Array = [active]
    for k in layers.keys():
        var p: AudioStreamPlayer = layers[k]
        if p and is_instance_valid(p):
            out.append(p)
    return out

func _make_stop_db0s(active: AudioStreamPlayer, layers: Dictionary) -> Array:
    var out: Array = [active.volume_db]
    for k in layers.keys():
        var p: AudioStreamPlayer = layers[k]
        if p and is_instance_valid(p):
            out.append(p.volume_db)
    return out

func _free_layers_now(layers: Dictionary) -> void:
    for k in layers.keys():
        var p: AudioStreamPlayer = layers[k]
        if p and is_instance_valid(p):
            p.stop()
            p.queue_free()

func _fade_out_single_layer(layer_id: StringName, p: AudioStreamPlayer, fade_sec: float) -> void:
    if p == null:
        return
    _task_id += 1
    _task = {
        "id": _task_id,
        "mode": "fade_out",
        "start_t": Time.get_ticks_msec() / 1000.0,
        "duration": maxf(0.0, fade_sec),
        "players": [p],
        "from_db0s": [p.volume_db],
        "cleanup": [p],
    }
    _layer_players.erase(layer_id)

func _fade_in_single_layer(p: AudioStreamPlayer, target_db: float, fade_sec: float) -> void:
    if p == null:
        return
    _task_id += 1
    _task = {
        "id": _task_id,
        "mode": "crossfade",
        "start_t": Time.get_ticks_msec() / 1000.0,
        "duration": maxf(0.0, fade_sec),
        "from_players": [],
        "to_players": [p],
        "from_db0s": [],
        "to_db1s": [target_db],
        "cleanup": [],
    }
