extends Area3D

enum FragmentStyle {
	RULE_NOTE,
	DELETED_PATH,
	WATCHER,
	HUNTER,
	GRANDMA,
	WOLF
}

@export var fragment_id: String = "memory_01"
@export var fragment_title: String = "记忆碎片"
@export_multiline var fragment_line: String = ""
@export_enum("Rule Note", "Deleted Path", "Watcher", "Hunter", "Grandma", "Wolf") var fragment_style: int = FragmentStyle.RULE_NOTE
@export var voice_clip: AudioStream
@export var subtitle_duration: float = 4.2
@export var bob_speed: float = 2.1
@export var bob_height: float = 0.09
@export var spin_speed: float = 0.85
@export var pulse_speed: float = 2.8

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visual: Node3D = $Visual
@onready var shard: MeshInstance3D = $Visual/Shard
@onready var core: MeshInstance3D = $Visual/Core
@onready var mark: MeshInstance3D = $Visual/Mark
@onready var glow_ring: MeshInstance3D = $Visual/GlowRing
@onready var glow_light: OmniLight3D = $GlowLight
@onready var voice_player: AudioStreamPlayer = $VoicePlayer

var _base_visual_y: float = 0.0
var _base_light_energy: float = 1.0
var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_base_visual_y = visual.position.y
	_base_light_energy = glow_light.light_energy

	if voice_clip:
		voice_player.stream = voice_clip

	_apply_visual_style()


func _process(delta: float) -> void:
	if _collected:
		return

	_time += delta
	visual.position.y = _base_visual_y + sin(_time * bob_speed) * bob_height
	visual.rotation.y += spin_speed * delta

	var pulse := 0.72 + (sin(_time * pulse_speed) + 1.0) * 0.24
	glow_light.light_energy = _base_light_energy * pulse


func _apply_visual_style() -> void:
	var shard_color := Color(0.96, 0.82, 0.42, 0.88)
	var glow_color := Color(1.0, 0.72, 0.22, 1.0)
	var mark_color := Color(1.0, 0.94, 0.72, 1.0)
	var visual_scale := Vector3.ONE

	match fragment_style:
		FragmentStyle.DELETED_PATH:
			shard_color = Color(0.22, 0.84, 0.68, 0.88)
			glow_color = Color(0.06, 0.95, 0.78, 1.0)
			mark_color = Color(0.84, 1.0, 0.94, 1.0)
		FragmentStyle.WATCHER:
			shard_color = Color(0.55, 0.68, 1.0, 0.86)
			glow_color = Color(0.32, 0.48, 1.0, 1.0)
			mark_color = Color(0.9, 0.94, 1.0, 1.0)
		FragmentStyle.HUNTER:
			shard_color = Color(0.74, 0.58, 0.4, 0.88)
			glow_color = Color(0.96, 0.52, 0.16, 1.0)
			mark_color = Color(1.0, 0.84, 0.62, 1.0)
			visual_scale = Vector3(1.08, 1.0, 1.08)
		FragmentStyle.GRANDMA:
			shard_color = Color(0.8, 0.5, 1.0, 0.86)
			glow_color = Color(0.84, 0.32, 1.0, 1.0)
			mark_color = Color(0.98, 0.82, 1.0, 1.0)
		FragmentStyle.WOLF:
			shard_color = Color(0.95, 0.08, 0.1, 0.88)
			glow_color = Color(1.0, 0.02, 0.04, 1.0)
			mark_color = Color(1.0, 0.86, 0.86, 1.0)
			visual_scale = Vector3(1.16, 1.16, 1.16)

	visual.scale = visual_scale
	shard.set_surface_override_material(0, _make_material(shard_color, glow_color, 0.85, true))
	core.set_surface_override_material(0, _make_material(mark_color, glow_color, 1.65, false))
	mark.set_surface_override_material(0, _make_material(mark_color, glow_color, 1.25, false))
	glow_ring.set_surface_override_material(0, _make_material(glow_color, glow_color, 1.15, true))
	glow_light.light_color = glow_color


func _make_material(albedo: Color, emission: Color, emission_energy: float, transparent: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.48
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = emission_energy
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return

	_collected = true
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	visual.visible = false
	glow_light.visible = false

	_show_memory_message()
	_play_voice()
	await get_tree().create_timer(_get_cleanup_delay()).timeout
	queue_free()


func _show_memory_message() -> void:
	var ui_nodes := get_tree().get_nodes_in_group("player_status_ui")
	if ui_nodes.size() == 0:
		return

	var ui := ui_nodes[0]
	if ui and ui.has_method("show_memory_fragment"):
		ui.show_memory_fragment(fragment_title, fragment_line, subtitle_duration)


func _play_voice() -> void:
	if voice_player.stream:
		voice_player.play()


func _get_cleanup_delay() -> float:
	var cleanup_delay := subtitle_duration
	if voice_player.stream and voice_player.stream.get_length() > 0.0:
		cleanup_delay = maxf(cleanup_delay, voice_player.stream.get_length() + 0.15)

	return cleanup_delay
