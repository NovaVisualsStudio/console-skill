extends Node
class_name NovaAudioFX

var ambience_player: AudioStreamPlayer
var one_shot_players: Array[AudioStreamPlayer] = []
var _player_cursor := 0
var _rng := RandomNumberGenerator.new()
var _swing_light: AudioStreamWAV
var _swing_heavy: AudioStreamWAV
var _impact_light: AudioStreamWAV
var _impact_heavy: AudioStreamWAV
var _parry: AudioStreamWAV
var _dodge: AudioStreamWAV
var _telegraph: AudioStreamWAV
var _phase_burst: AudioStreamWAV

func _ready() -> void:
    _rng.randomize()
    _swing_light = _make_one_shot(340.0, 155.0, 0.22, 0.18, 0.22)
    _swing_heavy = _make_one_shot(175.0, 62.0, 0.48, 0.34, 0.42)
    _impact_light = _make_one_shot(128.0, 72.0, 0.52, 0.30, 0.20)
    _impact_heavy = _make_one_shot(78.0, 34.0, 0.66, 0.42, 0.48)
    _parry = _make_one_shot(920.0, 410.0, 0.36, 0.10, 0.35)
    _dodge = _make_one_shot(520.0, 170.0, 0.28, 0.62, 0.22)
    _telegraph = _make_one_shot(72.0, 42.0, 0.72, 0.58, 0.25)
    _phase_burst = _make_one_shot(48.0, 28.0, 0.90, 0.54, 0.62)

    ambience_player = AudioStreamPlayer.new()
    ambience_player.name = "AshenAtmosphere"
    ambience_player.stream = _make_ambience()
    ambience_player.volume_db = -21.0
    add_child(ambience_player)

    for index in range(5):
        var player := AudioStreamPlayer.new()
        player.name = "CombatVoice_%d" % index
        player.volume_db = -7.0
        add_child(player)
        one_shot_players.append(player)

func start_ambience() -> void:
    if is_instance_valid(ambience_player) and not ambience_player.playing:
        ambience_player.play()

func play_swing(heavy: bool = false) -> void:
    _play(_swing_heavy if heavy else _swing_light)

func play_hit(heavy: bool = false) -> void:
    _play(_impact_heavy if heavy else _impact_light)

func play_parry() -> void:
    _play(_parry)

func play_dodge() -> void:
    _play(_dodge)

func play_telegraph(boss: bool = false) -> void:
    _play(_phase_burst if boss else _telegraph)

func play_boss_phase() -> void:
    _play(_phase_burst)

func _play(stream: AudioStreamWAV) -> void:
    if one_shot_players.is_empty() or stream == null:
        return
    var player := one_shot_players[_player_cursor]
    _player_cursor = (_player_cursor + 1) % one_shot_players.size()
    player.stop()
    player.stream = stream
    player.play()

func _make_ambience() -> AudioStreamWAV:
    var rate := 22050
    var duration := 7.0
    var samples := int(rate * duration)
    var bytes := PackedByteArray()
    bytes.resize(samples * 2)
    for index in range(samples):
        var time := float(index) / float(rate)
        var slow_waver := 0.82 + 0.12 * sin(TAU * 0.16 * time)
        var drone := sin(TAU * 55.0 * time) * 0.042
        drone += sin(TAU * 82.4 * time) * 0.026
        drone += sin(TAU * 110.0 * time) * 0.012
        var wind := _rng.randf_range(-1.0, 1.0) * 0.0045
        var sample := clampf((drone + wind) * slow_waver, -0.95, 0.95)
        bytes.encode_s16(index * 2, int(sample * 32767.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.stereo = false
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = samples
    stream.data = bytes
    return stream

func _make_one_shot(start_frequency: float, end_frequency: float, duration: float,
        noise_mix: float, gain: float) -> AudioStreamWAV:
    var rate := 22050
    var samples := maxi(1, int(rate * duration))
    var bytes := PackedByteArray()
    bytes.resize(samples * 2)
    for index in range(samples):
        var progress := float(index) / float(samples)
        var time := float(index) / float(rate)
        var frequency := lerpf(start_frequency, end_frequency, progress)
        var tone := sin(TAU * frequency * time)
        var noise := _rng.randf_range(-1.0, 1.0)
        var envelope := pow(1.0 - progress, 2.25)
        var wave := lerpf(tone, noise, noise_mix) * envelope * gain
        var sample := clampf(wave, -0.95, 0.95)
        bytes.encode_s16(index * 2, int(sample * 32767.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.stereo = false
    stream.data = bytes
    return stream
