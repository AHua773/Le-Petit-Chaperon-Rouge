extends Area3D

const SCROLL_SCENE_PATH := "res://assets/collectibles/memory/models/scroll.glb"
const SHIELD_SCENE_PATH := "res://assets/collectibles/memory/models/viking_shield.glb"
const HUNTER_WEAPON_SCENE_PATH := "res://assets/collectibles/memory/models/hunter_weapon.glb"
const WINGED_EYE_SCENE_PATH := "res://assets/collectibles/memory/models/winged_eye/winged_eye_monster.fbx"

enum FragmentStyle {
	RULE_NOTE,
	DELETED_PATH,
	WATCHER,
	HUNTER,
	GRANDMA,
	WOLF
}

@export var fragment_id: String = "memory_01"
@export var fragment_title: String = "Memory Fragment"
@export_multiline var fragment_line: String = ""
@export_enum("Rule Note", "Deleted Path", "Watcher", "Hunter", "Grandma", "Wolf") var fragment_style: int = FragmentStyle.RULE_NOTE
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

var _base_visual_y: float = 0.0
var _base_light_energy: float = 1.0
var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_base_visual_y = visual.position.y
	_base_light_energy = glow_light.light_energy

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
			_build_pink_bow_symbol(glow_color, mark_color)


func _clear_symbol() -> void:
	for child in symbol_root.get_children():
		child.queue_free()


func _build_pink_bow_symbol(glow_color: Color, mark_color: Color) -> void:
	var bow_mat := _make_material(Color(1.0, 0.46, 0.72, 1.0), Color(1.0, 0.18, 0.5, 1.0), 1.55, false)
	var ribbon_shadow_mat := _make_material(Color(0.58, 0.04, 0.22, 1.0), Color(0.9, 0.04, 0.32, 1.0), 0.7, false)

	_add_sphere("BowLeft", 0.22, 0.2, Vector3(-0.22, 0.86, 0.0), Vector3(1.5, 0.7, 0.62), bow_mat, Vector3(0.0, deg_to_rad(-14.0), deg_to_rad(22.0)))
	_add_sphere("BowRight", 0.22, 0.2, Vector3(0.22, 0.86, 0.0), Vector3(1.5, 0.7, 0.62), bow_mat, Vector3(0.0, deg_to_rad(14.0), deg_to_rad(-22.0)))
	_add_sphere("BowKnot", 0.12, 0.17, Vector3(0.0, 0.86, -0.08), Vector3(1.0, 0.86, 0.74), bow_mat)
	_add_box("RibbonLeft", Vector3(0.15, 0.42, 0.085), Vector3(-0.11, 0.59, 0.0), Vector3(0.0, 0.0, deg_to_rad(12.0)), ribbon_shadow_mat)
	_add_box("RibbonRight", Vector3(0.15, 0.42, 0.085), Vector3(0.11, 0.59, 0.0), Vector3(0.0, 0.0, deg_to_rad(-12.0)), ribbon_shadow_mat)
	_add_sphere("WarmMemory", 0.06, 0.085, Vector3(0.0, 0.87, -0.16), Vector3.ONE, _make_material(mark_color, glow_color, 1.8, false))


func _build_deleted_path_symbol(glow_color: Color) -> void:
	var wood_mat := _make_material(Color(0.29, 0.15, 0.07, 1.0), Color(0.08, 0.04, 0.01, 1.0), 0.1, false)
	var board_mat := _make_material(Color(0.42, 0.27, 0.13, 1.0), glow_color, 0.22, false)
	var cut_mat := _make_material(Color(0.15, 0.075, 0.025, 1.0), Color(0.05, 0.02, 0.0, 1.0), 0.05, false)
	var vine_mat := _make_material(Color(0.08, 0.28, 0.11, 1.0), Color(0.02, 0.12, 0.04, 1.0), 0.18, false)
	var leaf_mat := _make_material(Color(0.16, 0.48, 0.2, 1.0), Color(0.04, 0.22, 0.08, 1.0), 0.25, false)
	var thread_mat := _make_material(Color(0.86, 0.02, 0.04, 1.0), Color(1.0, 0.02, 0.02, 1.0), 1.35, false)

	_add_box("Post", Vector3(0.12, 1.18, 0.12), Vector3(0.0, 0.57, 0.05), Vector3(0.0, 0.0, deg_to_rad(-3.0)), wood_mat)
	_add_box("BrokenSignLeft", Vector3(0.62, 0.26, 0.1), Vector3(-0.31, 0.92, 0.0), Vector3(0.0, deg_to_rad(-4.0), deg_to_rad(7.0)), board_mat)
	_add_box("BrokenSignRight", Vector3(0.55, 0.26, 0.1), Vector3(0.31, 0.83, 0.01), Vector3(0.0, deg_to_rad(5.0), deg_to_rad(-13.0)), board_mat)
	_add_box("SplitTop", Vector3(0.08, 0.22, 0.12), Vector3(0.02, 0.89, -0.01), Vector3(0.0, 0.0, deg_to_rad(31.0)), cut_mat)
	_add_box("BrokenTipUpper", Vector3(0.17, 0.13, 0.1), Vector3(0.64, 0.91, 0.01), Vector3(0.0, 0.0, deg_to_rad(25.0)), board_mat)
	_add_box("BrokenTipLower", Vector3(0.13, 0.12, 0.1), Vector3(0.61, 0.77, 0.01), Vector3(0.0, 0.0, deg_to_rad(-24.0)), board_mat)

	# Shallow dark strokes suggest letters that someone deliberately scraped away.
	for i in range(5):
		_add_box("ErasedLetter%d" % i, Vector3(0.12, 0.028, 0.018), Vector3(-0.43 + i * 0.2, 0.91 - i * 0.012, 0.065), Vector3(0.0, 0.0, deg_to_rad(-8.0 + i * 4.0)), cut_mat)
	_add_box("LongScrape", Vector3(0.94, 0.026, 0.02), Vector3(-0.02, 0.88, 0.078), Vector3(0.0, 0.0, deg_to_rad(9.0)), cut_mat)
	_add_box("CrossScrape", Vector3(0.62, 0.024, 0.022), Vector3(0.1, 0.89, 0.084), Vector3(0.0, 0.0, deg_to_rad(-22.0)), cut_mat)

	_add_cylinder("VineStemLeft", 0.018, 0.018, 0.78, Vector3(-0.2, 0.51, 0.09), Vector3(0.0, 0.0, deg_to_rad(-17.0)), vine_mat)
	_add_cylinder("VineStemAcross", 0.016, 0.016, 0.72, Vector3(-0.19, 0.86, 0.09), Vector3(0.0, 0.0, deg_to_rad(75.0)), vine_mat)
	for i in range(6):
		var leaf_position := Vector3(-0.38 + i * 0.14, 0.69 + i * 0.055, 0.12)
		_add_sphere("Leaf%d" % i, 0.095, 0.1, leaf_position, Vector3(1.2, 0.48, 0.38), leaf_mat, Vector3(0.0, 0.0, deg_to_rad(-35.0 + i * 17.0)))
	_add_box("CutThreadLeft", Vector3(0.42, 0.035, 0.035), Vector3(-0.36, 1.13, 0.03), Vector3(0.0, 0.0, deg_to_rad(-24.0)), thread_mat)
	_add_box("CutThreadRight", Vector3(0.42, 0.035, 0.035), Vector3(0.36, 1.13, -0.03), Vector3(0.0, 0.0, deg_to_rad(24.0)), thread_mat)


func _build_watcher_symbol(glow_color: Color) -> void:
	var eye := _add_imported_symbol(
		"WingedWatcher",
		WINGED_EYE_SCENE_PATH,
		Vector3.ONE * 1.38,
		Vector3(0.0, 0.78, -0.06),
		Vector3(0.0, 0.0, deg_to_rad(-3.0)),
		glow_color
	)
	var animation_player := _find_animation_player(eye)
	if animation_player and animation_player.has_animation("Take 001"):
		animation_player.play("Take 001")
		animation_player.speed_scale = 0.72
	var pupil_glow := _make_material(Color(0.03, 0.03, 0.08, 1.0), glow_color, 2.2, false)
	_add_sphere("WatchingPupilGlow", 0.055, 0.065, Vector3(0.0, 0.78, -0.19), Vector3(1.0, 1.0, 0.45), pupil_glow)


func _build_hunter_symbol(glow_color: Color) -> void:
	var badge_mat := _make_material(Color(0.78, 0.52, 0.18, 1.0), glow_color, 0.9, false)

	_add_imported_symbol(
		"HunterWeapon",
		HUNTER_WEAPON_SCENE_PATH,
		Vector3.ONE * 1.12,
		Vector3(0.0, 0.66, 0.0),
		Vector3(0.0, deg_to_rad(-12.0), deg_to_rad(-24.0)),
		glow_color
	)
	_add_box("LateBadgeBar", Vector3(0.5, 0.055, 0.055), Vector3(-0.2, 0.31, -0.22), Vector3(0.0, 0.0, deg_to_rad(12.0)), badge_mat)
	_add_sphere("LateBadge", 0.14, 0.08, Vector3(-0.23, 0.47, 0.0), Vector3(1.0, 0.52, 1.0), badge_mat)


func _build_grandma_symbol(glow_color: Color) -> void:
	var metal_mat := _make_material(Color(0.74, 0.7, 0.82, 1.0), glow_color, 0.85, false)
	var dark_mat := _make_material(Color(0.02, 0.0, 0.04, 1.0), Color(0.1, 0.0, 0.16, 1.0), 0.3, false)

	_add_imported_symbol(
		"DoorDeedScroll",
		SCROLL_SCENE_PATH,
		Vector3.ONE * 1.02,
		Vector3(0.0, 0.7, 0.0),
		Vector3(0.0, deg_to_rad(8.0), deg_to_rad(-6.0)),
		glow_color
	)
	_add_cylinder("KeyShaft", 0.035, 0.035, 0.48, Vector3(0.23, 0.57, 0.2), Vector3(0.0, 0.0, deg_to_rad(-22.0)), metal_mat)
	_add_sphere("KeyRing", 0.13, 0.06, Vector3(0.32, 0.77, 0.2), Vector3(1.0, 1.0, 0.34), metal_mat)
	_add_box("KeyToothLong", Vector3(0.18, 0.055, 0.055), Vector3(0.13, 0.35, 0.2), Vector3(0.0, 0.0, deg_to_rad(-22.0)), dark_mat)
	_add_box("KeyToothShort", Vector3(0.12, 0.055, 0.055), Vector3(0.03, 0.39, 0.2), Vector3(0.0, 0.0, deg_to_rad(68.0)), dark_mat)


func _build_wolf_symbol(glow_color: Color) -> void:
	var red_mat := _make_material(Color(0.8, 0.015, 0.02, 1.0), Color(1.0, 0.02, 0.02, 1.0), 1.45, false)
	var eye_mat := _make_material(Color(1.0, 0.86, 0.78, 1.0), glow_color, 1.4, false)

	_add_imported_symbol(
		"WolfLawShield",
		SHIELD_SCENE_PATH,
		Vector3.ONE * 0.78,
		Vector3(0.0, 0.18, 0.0),
		Vector3(0.0, 0.0, deg_to_rad(4.0)),
		glow_color
	)
	_add_box("RedDivide", Vector3(0.05, 0.5, 0.04), Vector3(0.0, 0.67, 0.2), Vector3(0.0, 0.0, deg_to_rad(8.0)), red_mat)
	_add_sphere("LeftEye", 0.065, 0.06, Vector3(-0.19, 0.72, 0.23), Vector3(1.35, 0.55, 0.45), eye_mat)
	_add_sphere("RightEye", 0.065, 0.06, Vector3(0.19, 0.72, 0.23), Vector3(1.35, 0.55, 0.45), eye_mat)
	_add_box("Mouth", Vector3(0.34, 0.045, 0.04), Vector3(0.0, 0.48, 0.23), Vector3.ZERO, red_mat)


func _add_imported_symbol(part_name: String, scene_path: String, model_scale: Vector3, position: Vector3, rotation: Vector3, glow_color: Color) -> Node3D:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_warning("Memory fragment could not load model: %s" % scene_path)
		return null

	var wrapper := Node3D.new()
	wrapper.name = part_name
	wrapper.position = position
	wrapper.rotation = rotation
	wrapper.scale = model_scale
	symbol_root.add_child(wrapper)

	var model := packed_scene.instantiate() as Node3D
	wrapper.add_child(model)
	var overlay := _make_material(Color(glow_color.r, glow_color.g, glow_color.b, 0.08), glow_color, 0.42, true)
	overlay.metallic = 0.08
	overlay.roughness = 0.34
	for mesh_node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		mesh_instance.material_overlay = overlay
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	return wrapper


func _find_animation_player(root_node: Node) -> AnimationPlayer:
	if root_node == null:
		return null
	if root_node is AnimationPlayer:
		return root_node as AnimationPlayer
	for child in root_node.get_children():
		var animation_player := _find_animation_player(child)
		if animation_player:
			return animation_player
	return null


func _add_box(part_name: String, size: Vector3, position: Vector3, rotation: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(part_name, mesh, position, rotation, Vector3.ONE, material)


func _add_sphere(part_name: String, radius: float, height: float, position: Vector3, scale: Vector3, material: StandardMaterial3D, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 8
	return _add_mesh(part_name, mesh, position, rotation, scale, material)


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


func _get_progress_title() -> String:
	var memory_state := _get_memory_state()
	if not memory_state or not memory_state.has_method("get_collected_count") or not memory_state.has_method("get_total_count"):
		return fragment_title

	return "%s  · Awareness %d/%d" % [
		fragment_title,
		memory_state.get_collected_count(),
		memory_state.get_total_count()
	]


func _get_cleanup_delay() -> float:
	return subtitle_duration


func _get_memory_state() -> Node:
	var nodes := get_tree().get_nodes_in_group("memory_state")
	if nodes.size() == 0:
		return null

	return nodes[0]
