extends Node

@onready var music_player: AudioStreamPlayer = $BackgroundMusic
@onready var hit_player: AudioStreamPlayer = $HitSound


func _ready() -> void:
	add_to_group("game_audio")
	music_player.stream = _create_background_music()
	hit_player.stream = _create_hit_sound()
	music_player.play()


func play_hit() -> void:
	hit_player.pitch_scale = randf_range(0.92, 1.08)
	hit_player.play()


func _create_background_music() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 16.0
	var frame_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 4)
	var chords := [
		[55.0, 65.41, 82.41],
		[49.0, 58.27, 73.42],
		[43.65, 55.0, 65.41],
		[46.25, 55.0, 69.30]
	]

	for frame in frame_count:
		var time := float(frame) / sample_rate
		var chord: Array = chords[int(time / 4.0) % chords.size()]
		var pulse := 0.72 + sin(time * TAU * 0.125) * 0.18
		var left := 0.0
		var right := 0.0
		for tone_index in chord.size():
			var frequency: float = chord[tone_index]
			var phase := time * TAU * frequency
			var level := 0.07 / float(tone_index + 1)
			left += sin(phase + tone_index * 0.25) * level
			right += sin(phase - tone_index * 0.2) * level
		var distant_note := sin(time * TAU * (chord[1] * 2.0)) * 0.012
		left = (left * pulse + distant_note) * 0.75
		right = (right * pulse - distant_note) * 0.75
		data.encode_s16(frame * 4, int(clampf(left, -1.0, 1.0) * 32767.0))
		data.encode_s16(frame * 4 + 2, int(clampf(right, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	stream.data = data
	return stream


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
