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
@onready var symbol_root: Node3D = $Visual/Symbol
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
	shard.visible = false
	core.visible = false
	mark.visible = false
	glow_ring.set_surface_override_material(0, _make_material(glow_color, glow_color, 1.15, true))
	glow_light.light_color = glow_color
	_build_symbol(glow_color, mark_color)


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


func _build_symbol(glow_color: Color, mark_color: Color) -> void:
	_clear_symbol()

	match fragment_style:
		FragmentStyle.DELETED_PATH:
			_build_deleted_path_symbol(glow_color)
		FragmentStyle.WATCHER:
			_build_watcher_symbol(glow_color)
		FragmentStyle.HUNTER:
			_build_hunter_symbol(glow_color)
		FragmentStyle.GRANDMA:
			_build_grandma_symbol(glow_color)
		FragmentStyle.WOLF:
			_build_wolf_symbol(glow_color)
		_:
			_build_red_shoe_symbol(glow_color, mark_color)


func _clear_symbol() -> void:
	for child in symbol_root.get_children():
		child.queue_free()


func _build_red_shoe_symbol(glow_color: Color, mark_color: Color) -> void:
	var shoe_mat := _make_material(Color(0.82, 0.02, 0.04, 1.0), glow_color, 1.15, false)
	var sole_mat := _make_material(Color(0.09, 0.01, 0.012, 1.0), Color(0.25, 0.0, 0.0, 1.0), 0.25, false)
	var bow_mat := _make_material(Color(1.0, 0.46, 0.72, 1.0), Color(1.0, 0.18, 0.5, 1.0), 1.55, false)

	_add_box("ShoeSole", Vector3(0.66, 0.1, 0.24), Vector3(0.02, 0.49, 0.0), Vector3(0.0, 0.0, deg_to_rad(-8.0)), sole_mat)
	_add_sphere("ShoeToe", 0.24, 0.22, Vector3(0.28, 0.56, 0.0), Vector3(1.55, 0.48, 0.86), shoe_mat)
	_add_box("ShoeArch", Vector3(0.32, 0.12, 0.22), Vector3(-0.08, 0.57, 0.0), Vector3(0.0, 0.0, deg_to_rad(9.0)), shoe_mat)
	_add_box("Heel", Vector3(0.07, 0.43, 0.07), Vector3(-0.34, 0.27, 0.0), Vector3(0.0, 0.0, deg_to_rad(-12.0)), shoe_mat)
	_add_box("BowLeft", Vector3(0.18, 0.08, 0.12), Vector3(0.12, 0.77, -0.07), Vector3(0.0, 0.0, deg_to_rad(22.0)), bow_mat)
	_add_box("BowRight", Vector3(0.18, 0.08, 0.12), Vector3(0.3, 0.77, 0.07), Vector3(0.0, 0.0, deg_to_rad(-22.0)), bow_mat)
	_add_sphere("BowKnot", 0.055, 0.08, Vector3(0.21, 0.77, 0.0), Vector3.ONE, bow_mat)


func _build_deleted_path_symbol(glow_color: Color) -> void:
	var wood_mat := _make_material(Color(0.36, 0.22, 0.12, 1.0), Color(0.08, 0.04, 0.01, 1.0), 0.1, false)
	var board_mat := _make_material(Color(0.2, 0.18, 0.14, 1.0), glow_color, 0.35, false)
	var thread_mat := _make_material(Color(0.86, 0.02, 0.04, 1.0), Color(1.0, 0.02, 0.02, 1.0), 1.35, false)

	_add_box("Post", Vector3(0.08, 0.72, 0.08), Vector3(0.0, 0.5, 0.0), Vector3.ZERO, wood_mat)
	_add_box("BrokenSignLeft", Vector3(0.34, 0.16, 0.06), Vector3(-0.21, 0.82, 0.0), Vector3(0.0, 0.0, deg_to_rad(8.0)), board_mat)
	_add_box("BrokenSignRight", Vector3(0.34, 0.16, 0.06), Vector3(0.23, 0.75, 0.0), Vector3(0.0, 0.0, deg_to_rad(-16.0)), board_mat)
	_add_box("CutThreadLeft", Vector3(0.32, 0.035, 0.035), Vector3(-0.27, 1.0, 0.04), Vector3(0.0, 0.0, deg_to_rad(-24.0)), thread_mat)
	_add_box("CutThreadRight", Vector3(0.32, 0.035, 0.035), Vector3(0.27, 1.0, -0.04), Vector3(0.0, 0.0, deg_to_rad(24.0)), thread_mat)


func _build_watcher_symbol(glow_color: Color) -> void:
	var eye_mat := _make_material(Color(0.86, 0.9, 1.0, 1.0), glow_color, 1.1, false)
	var pupil_mat := _make_material(Color(0.02, 0.025, 0.05, 1.0), Color(0.14, 0.28, 1.0, 1.0), 1.6, false)
	var lash_mat := _make_material(Color(0.06, 0.07, 0.12, 1.0), glow_color, 0.75, false)

	_add_sphere("EyeWhite", 0.34, 0.3, Vector3(0.0, 0.74, 0.0), Vector3(1.45, 0.42, 0.8), eye_mat)
	_add_sphere("Pupil", 0.11, 0.12, Vector3(0.0, 0.76, -0.23), Vector3(1.0, 1.0, 0.55), pupil_mat)
	for i in range(5):
		var x := -0.36 + i * 0.18
		_add_box("WatcherRay%d" % i, Vector3(0.035, 0.22, 0.035), Vector3(x, 1.0, 0.0), Vector3(0.0, 0.0, deg_to_rad(-28.0 + i * 14.0)), lash_mat)
	_add_sphere("SmallEyeLeft", 0.08, 0.08, Vector3(-0.46, 0.55, 0.0), Vector3(1.2, 0.45, 0.7), eye_mat)
	_add_sphere("SmallEyeRight", 0.08, 0.08, Vector3(0.46, 0.55, 0.0), Vector3(1.2, 0.45, 0.7), eye_mat)


func _build_hunter_symbol(glow_color: Color) -> void:
	var handle_mat := _make_material(Color(0.34, 0.2, 0.12, 1.0), Color(0.1, 0.045, 0.02, 1.0), 0.1, false)
	var metal_mat := _make_material(Color(0.52, 0.54, 0.52, 1.0), glow_color, 0.75, false)
	var badge_mat := _make_material(Color(0.78, 0.52, 0.18, 1.0), glow_color, 0.9, false)

	_add_box("AxeHandle", Vector3(0.08, 0.92, 0.08), Vector3(0.0, 0.57, 0.0), Vector3(0.0, 0.0, deg_to_rad(-24.0)), handle_mat)
	_add_box("AxeBlade", Vector3(0.36, 0.2, 0.05), Vector3(0.24, 0.94, 0.0), Vector3(0.0, 0.0, deg_to_rad(-24.0)), metal_mat)
	_add_box("BadgeBar", Vector3(0.46, 0.055, 0.055), Vector3(-0.18, 0.36, 0.0), Vector3(0.0, 0.0, deg_to_rad(12.0)), badge_mat)
	_add_sphere("LateBadge", 0.14, 0.08, Vector3(-0.23, 0.47, 0.0), Vector3(1.0, 0.52, 1.0), badge_mat)


func _build_grandma_symbol(glow_color: Color) -> void:
	var lock_mat := _make_material(Color(0.42, 0.28, 0.58, 1.0), glow_color, 1.0, false)
	var metal_mat := _make_material(Color(0.74, 0.7, 0.82, 1.0), glow_color, 0.85, false)
	var dark_mat := _make_material(Color(0.02, 0.0, 0.04, 1.0), Color(0.1, 0.0, 0.16, 1.0), 0.3, false)

	_add_box("LockBody", Vector3(0.46, 0.36, 0.16), Vector3(0.0, 0.52, 0.0), Vector3.ZERO, lock_mat)
	_add_cylinder("ShackleLeft", 0.035, 0.035, 0.34, Vector3(-0.16, 0.84, 0.0), Vector3.ZERO, metal_mat)
	_add_cylinder("ShackleRight", 0.035, 0.035, 0.34, Vector3(0.16, 0.84, 0.0), Vector3.ZERO, metal_mat)
	_add_cylinder("ShackleTop", 0.035, 0.035, 0.32, Vector3(0.0, 1.01, 0.0), Vector3(0.0, 0.0, deg_to_rad(90.0)), metal_mat)
	_add_box("Keyhole", Vector3(0.07, 0.17, 0.035), Vector3(0.0, 0.5, -0.09), Vector3.ZERO, dark_mat)
	_add_box("DoorChain", Vector3(0.56, 0.045, 0.045), Vector3(0.0, 0.28, 0.02), Vector3(0.0, 0.0, deg_to_rad(-12.0)), metal_mat)


func _build_wolf_symbol(glow_color: Color) -> void:
	var mask_mat := _make_material(Color(0.05, 0.045, 0.055, 1.0), glow_color, 0.9, false)
	var red_mat := _make_material(Color(0.8, 0.015, 0.02, 1.0), Color(1.0, 0.02, 0.02, 1.0), 1.45, false)
	var eye_mat := _make_material(Color(1.0, 0.86, 0.78, 1.0), glow_color, 1.4, false)

	_add_sphere("MaskFace", 0.31, 0.42, Vector3(0.0, 0.72, 0.0), Vector3(1.05, 1.15, 0.62), mask_mat)
	_add_box("LeftEar", Vector3(0.14, 0.28, 0.08), Vector3(-0.2, 1.02, 0.0), Vector3(0.0, 0.0, deg_to_rad(-32.0)), mask_mat)
	_add_box("RightEar", Vector3(0.14, 0.28, 0.08), Vector3(0.2, 1.02, 0.0), Vector3(0.0, 0.0, deg_to_rad(32.0)), mask_mat)
	_add_box("RedDivide", Vector3(0.055, 0.54, 0.035), Vector3(0.0, 0.72, -0.22), Vector3(0.0, 0.0, deg_to_rad(8.0)), red_mat)
	_add_sphere("LeftEye", 0.055, 0.055, Vector3(-0.12, 0.79, -0.24), Vector3(1.2, 0.5, 0.5), eye_mat)
	_add_sphere("RightEye", 0.055, 0.055, Vector3(0.12, 0.79, -0.24), Vector3(1.2, 0.5, 0.5), eye_mat)
	_add_box("Mouth", Vector3(0.24, 0.04, 0.035), Vector3(0.0, 0.59, -0.25), Vector3.ZERO, red_mat)


func _add_box(part_name: String, size: Vector3, position: Vector3, rotation: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(part_name, mesh, position, rotation, Vector3.ONE, material)


func _add_sphere(part_name: String, radius: float, height: float, position: Vector3, scale: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 8
	return _add_mesh(part_name, mesh, position, Vector3.ZERO, scale, material)


func _add_cylinder(part_name: String, top_radius: float, bottom_radius: float, height: float, position: Vector3, rotation: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 12
	return _add_mesh(part_name, mesh, position, rotation, Vector3.ONE, material)


func _add_mesh(part_name: String, mesh: Mesh, position: Vector3, rotation: Vector3, scale: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.scale = scale
	instance.set_surface_override_material(0, material)
	symbol_root.add_child(instance)
	return instance


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return

	_collected = true
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	visual.visible = false
	glow_light.visible = false

	_record_memory_progress()
	_show_memory_message()
	_play_voice()
	await get_tree().create_timer(_get_cleanup_delay()).timeout
	queue_free()


func _record_memory_progress() -> void:
	var memory_state := _get_memory_state()
	if memory_state and memory_state.has_method("collect_fragment"):
		memory_state.collect_fragment(fragment_id)


func _show_memory_message() -> void:
	var ui_nodes := get_tree().get_nodes_in_group("player_status_ui")
	if ui_nodes.size() == 0:
		return

	var ui := ui_nodes[0]
	if ui and ui.has_method("show_memory_fragment"):
		ui.show_memory_fragment(_get_progress_title(), fragment_line, subtitle_duration)


func _play_voice() -> void:
	if voice_player.stream:
		voice_player.play()


func _get_progress_title() -> String:
	var memory_state := _get_memory_state()
	if not memory_state or not memory_state.has_method("get_collected_count") or not memory_state.has_method("get_total_count"):
		return fragment_title

	return "%s  · 觉察 %d/%d" % [
		fragment_title,
		memory_state.get_collected_count(),
		memory_state.get_total_count()
	]


func _get_cleanup_delay() -> float:
	var cleanup_delay := subtitle_duration
	if voice_player.stream and voice_player.stream.get_length() > 0.0:
		cleanup_delay = maxf(cleanup_delay, voice_player.stream.get_length() + 0.15)

	return cleanup_delay


func _get_memory_state() -> Node:
	var nodes := get_tree().get_nodes_in_group("memory_state")
	if nodes.size() == 0:
		return null

	return nodes[0]
