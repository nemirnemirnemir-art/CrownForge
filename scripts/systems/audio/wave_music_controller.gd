extends Node
class_name WaveMusicController

## Manages wave-based music transitions:
## mainTrack (loop) -> waveStarted (one-shot) -> waveFight (loop)
## waveFight -> waveFinish (one-shot) -> mainTrack (fade-in 2s, resume position)

const AudioEventsScript = preload("res://scripts/systems/audio/audio_events.gd")

var _transitioning: bool = false
var _awaiting_finish: bool = false
var _main_track_saved_position: float = 0.0
var _reward_menu_active: bool = false
var _saved_music_volume: float = 1.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    if EventBus:
        EventBus.wave_started.connect(_on_wave_started)
        EventBus.wave_completed.connect(_on_wave_completed)
        print("[WaveMusicController] Connected to EventBus signals")

func _on_wave_started(_wave_number: int) -> void:
    if _transitioning:
        print("[WaveMusicController] Ignoring wave_started (transition in progress)")
        return
    _transitioning = true
    # Save main track position before switching
    _save_main_track_position()
    print("[WaveMusicController] Wave started -> playing wave_start")
    AudioManager.play_music(AudioEventsScript.MUSIC_WAVE_START, 0.2)
    _await_track_finish(func():
        print("[WaveMusicController] wave_start finished -> playing wave_fight")
        AudioManager.play_music(AudioEventsScript.MUSIC_WAVE_FIGHT, 0.5)
        _transitioning = false
    )

func _on_wave_completed(_wave_number: int) -> void:
    if _transitioning:
        print("[WaveMusicController] Ignoring wave_completed (transition in progress)")
        return
    _transitioning = true
    print("[WaveMusicController] Wave completed -> playing wave_finish")
    AudioManager.play_music(AudioEventsScript.MUSIC_WAVE_FINISH, 0.3)
    _await_track_finish(func():
        print("[WaveMusicController] wave_finish finished -> playing main (fade-in 2s, resume position)")
        AudioManager.play_music(AudioEventsScript.MUSIC_MAIN, 2.0)
        # Restore main track position after a frame
        _restore_main_track_position()
        _transitioning = false
    )

func _save_main_track_position() -> void:
    var mp := _get_music_player()
    if mp == null:
        return
    var active := mp.get_active_player()
    if active and active.playing and active.stream:
        var stream_id := str(active.stream.resource_path)
        if stream_id.contains("mainTrack"):
            _main_track_saved_position = active.get_playback_position()
            print("[WaveMusicController] Saved main track position: %.2f" % _main_track_saved_position)

func _restore_main_track_position() -> void:
    if _main_track_saved_position < 0.1:
        return
    var mp := _get_music_player()
    if mp == null:
        return
    var active := mp.get_active_player()
    if active and active.playing:
        var stream_id := str(active.stream.resource_path)
        if stream_id.contains("mainTrack"):
            # Wait one frame for the stream to be ready
            await get_tree().process_frame
            active.seek(_main_track_saved_position)
            print("[WaveMusicController] Restored main track position: %.2f" % _main_track_saved_position)

func connect_to_reward_menu(menu: Control) -> void:
    if menu == null:
        return
    if menu.has_signal("opened"):
        menu.opened.connect(_on_reward_menu_opened)
    if menu.has_signal("closed"):
        menu.closed.connect(_on_reward_menu_closed)
    print("[WaveMusicController] Connected to reward menu signals")

func _on_reward_menu_opened() -> void:
    if _reward_menu_active:
        return
    _reward_menu_active = true
    if not is_inside_tree():
        return
    var am := get_node_or_null("/root/AudioManager")
    if am and am.has_method("get_music_volume") and am.has_method("set_music_volume"):
        _saved_music_volume = float(am.get_music_volume())
        am.set_music_volume(_saved_music_volume * 0.5)
        print("[WaveMusicController] Reward menu opened -> music volume reduced to 50%%")

func _on_reward_menu_closed() -> void:
    if not _reward_menu_active:
        return
    _reward_menu_active = false
    if not is_inside_tree():
        return
    var am := get_node_or_null("/root/AudioManager")
    if am and am.has_method("set_music_volume"):
        am.set_music_volume(_saved_music_volume)
        print("[WaveMusicController] Reward menu closed -> music volume restored")

func _await_track_finish(callback: Callable) -> void:
    if _awaiting_finish:
        return
    var music_player: MusicPlayer = _get_music_player()
    if music_player == null:
        push_warning("[WaveMusicController] MusicPlayer not found")
        callback.call()
        return
    var active: AudioStreamPlayer = music_player.get_active_player()
    if active == null:
        push_warning("[WaveMusicController] No active player")
        callback.call()
        return
    if not active.playing:
        callback.call()
        return
    _awaiting_finish = true
    var conn_err := active.finished.connect(func():
        _awaiting_finish = false
        if callback.is_valid():
            callback.call()
    , CONNECT_ONE_SHOT)
    if conn_err != OK:
        push_warning("[WaveMusicController] Failed to connect finished signal: %d" % conn_err)
        _awaiting_finish = false
        callback.call()

func _get_music_player() -> MusicPlayer:
    if not is_inside_tree():
        return null
    var am := get_node_or_null("/root/AudioManager")
    if am == null:
        return null
    return am.get_node_or_null("MusicPlayer") as MusicPlayer
