extends Node

@onready var music_player: AudioStreamPlayer = $BackgroundMusic
@onready var hit_player: AudioStreamPlayer = $HitSound


func _ready() -> void:
	add_to_group("game_audio")
	process_mode = Node.PROCESS_MODE_ALWAYS
	hit_player.stream = _create_hit_sound()
	_configure_music_loop()
	if not music_player.finished.is_connected(_restart_music):
		music_player.finished.connect(_restart_music)
	if not music_player.playing:
		music_player.play()


func _process(_delta: float) -> void:
	if music_player.stream and not music_player.playing:
		music_player.play()


func _configure_music_loop() -> void:
	if not music_player.stream:
		push_error("BackgroundMusic has no assigned audio stream.")
		return
	if music_player.stream is AudioStreamWAV:
		var looped_stream := music_player.stream.duplicate(true) as AudioStreamWAV
		looped_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		looped_stream.loop_begin = 0
		looped_stream.loop_end = roundi(looped_stream.get_length() * looped_stream.mix_rate)
		music_player.stream = looped_stream


func _restart_music() -> void:
	music_player.play()


func play_hit() -> void:
	hit_player.pitch_scale = randf_range(0.92, 1.08)
	hit_player.play()


func _create_hit_sound() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.42
	var frame_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 191227

	for frame in frame_count:
		var time := float(frame) / sample_rate
		var envelope := exp(-time * 11.0)
		var impact := sin(time * TAU * (92.0 - time * 90.0)) * 0.62
		var crack := noise.randf_range(-1.0, 1.0) * 0.38
		var sample := (impact + crack) * envelope
		data.encode_s16(frame * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
