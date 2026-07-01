extends Node

const AudioEvents = preload("res://scripts/systems/audio/audio_events.gd")

const AudioBusController = preload("res://scripts/systems/audio/audio_bus_controller.gd")
const MusicPlayer = preload("res://scripts/systems/audio/music_player.gd")
const SfxPool = preload("res://scripts/systems/audio/sfx_pool.gd")
const AmbientController = preload("res://scripts/systems/audio/ambient_controller.gd")
const VoicePlayer = preload("res://scripts/systems/audio/voice_player.gd")

const SoundDataScript = preload("res://scripts/systems/audio/resources/sound_data.gd")
const MusicDataScript = preload("res://scripts/systems/audio/resources/music_data.gd")

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var voice_volume: float = 1.0
var ambient_volume: float = 1.0
var is_muted: bool = false

var _bus: AudioBusController
var _music: MusicPlayer
var _sfx: SfxPool
var _ambient: AmbientController
var _voice: VoicePlayer

var _music_registry: Dictionary = {} # StringName -> Resource (MusicData)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    _bus = AudioBusController.new()
    _bus.name = "AudioBusController"
    add_child(_bus)

    _music = MusicPlayer.new()
    _music.name = "MusicPlayer"
    add_child(_music)

    _sfx = SfxPool.new()
    _sfx.name = "SfxPool"
    add_child(_sfx)

    _ambient = AmbientController.new()
    _ambient.name = "AmbientController"
    add_child(_ambient)

    _voice = VoicePlayer.new()
    _voice.name = "VoicePlayer"
    add_child(_voice)

    _bus.ensure_buses([
        AudioEvents.BUS_MASTER,
        AudioEvents.BUS_MUSIC,
        AudioEvents.BUS_SFX,
        AudioEvents.BUS_VOICE,
        AudioEvents.BUS_AMBIENT,
    ])

    _scan_resource_dir("res://resources/audio/sfx")
    _scan_resource_dir("res://resources/audio/music")

    _apply_settings()

func play_music(id: StringName, crossfade_sec: float = 1.0) -> void:
    var data = _music_registry.get(id)
    if data == null:
        push_warning("[AudioManager] Missing MusicData for id='%s'" % String(id))
        return
    _music.play(data, crossfade_sec)

func stop_music(fade_out_sec: float = 1.0) -> void:
    _music.stop(fade_out_sec)

func play_sfx(id: StringName, position: Variant = null) -> void:
    _sfx.play(id, position)

func set_master_volume(v: float) -> void:
    master_volume = clampf(v, 0.0, 1.0)
    _bus.set_bus_volume_linear(AudioEvents.BUS_MASTER, master_volume)
    _request_save()

func set_music_volume(v: float) -> void:
    music_volume = clampf(v, 0.0, 1.0)
    _bus.set_bus_volume_linear(AudioEvents.BUS_MUSIC, music_volume)

func get_music_volume() -> float:
    return music_volume

func set_sfx_volume(v: float) -> void:
    sfx_volume = clampf(v, 0.0, 1.0)
    _bus.set_bus_volume_linear(AudioEvents.BUS_SFX, sfx_volume)
    _request_save()

func set_voice_volume(v: float) -> void:
    voice_volume = clampf(v, 0.0, 1.0)
    _bus.set_bus_volume_linear(AudioEvents.BUS_VOICE, voice_volume)
    _request_save()

func set_ambient_volume(v: float) -> void:
    ambient_volume = clampf(v, 0.0, 1.0)
    _bus.set_bus_volume_linear(AudioEvents.BUS_AMBIENT, ambient_volume)
    _request_save()

func set_muted(muted: bool) -> void:
    is_muted = muted
    _bus.set_bus_muted(AudioEvents.BUS_MASTER, is_muted)
    _request_save()

func _apply_settings() -> void:
    _bus.set_bus_volume_linear(AudioEvents.BUS_MASTER, master_volume)
    _bus.set_bus_volume_linear(AudioEvents.BUS_MUSIC, music_volume)
    _bus.set_bus_volume_linear(AudioEvents.BUS_SFX, sfx_volume)
    _bus.set_bus_volume_linear(AudioEvents.BUS_VOICE, voice_volume)
    _bus.set_bus_volume_linear(AudioEvents.BUS_AMBIENT, ambient_volume)
    _bus.set_bus_muted(AudioEvents.BUS_MASTER, is_muted)

func _request_save() -> void:
    if SaveCore and SaveCore.has_method("request_save"):
        SaveCore.request_save()

func get_save_data() -> Dictionary:
    return {
        "master_volume": master_volume,
        "music_volume": music_volume,
        "sfx_volume": sfx_volume,
        "voice_volume": voice_volume,
        "ambient_volume": ambient_volume,
        "is_muted": is_muted,
    }

func load_save_data(data: Dictionary) -> void:
    master_volume = float(data.get("master_volume", master_volume))
    music_volume = float(data.get("music_volume", music_volume))
    sfx_volume = float(data.get("sfx_volume", sfx_volume))
    voice_volume = float(data.get("voice_volume", voice_volume))
    ambient_volume = float(data.get("ambient_volume", ambient_volume))
    is_muted = bool(data.get("is_muted", is_muted))
    _apply_settings()

func _scan_resource_dir(dir_path: String) -> void:
    if not DirAccess.dir_exists_absolute(dir_path):
        return

    var dir := DirAccess.open(dir_path)
    if dir == null:
        return

    dir.list_dir_begin()
    while true:
        var entry_name := dir.get_next()
        if entry_name == "":
            break
        if dir.current_is_dir():
            continue
        if not entry_name.ends_with(".tres"):
            continue

        var res_path := dir_path.path_join(entry_name)
        var res := ResourceLoader.load(res_path)
        if res == null:
            continue

        if res.get_script() == SoundDataScript:
            _sfx.register_sound(res)
        elif res.get_script() == MusicDataScript:
            if "id" in res and res.id != &"":
                _music_registry[res.id] = res

    dir.list_dir_end()
