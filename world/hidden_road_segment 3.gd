extends Node3D

@export var required_fragments_csv: String = ""
@export var segment_title: String = "The Path Is Still Incomplete"
@export_multiline var locked_message: String = "You still cannot remember this path."
@export var path_size: Vector3 = Vector3(3.0, 0.08, 4.0)
@export var unlocked_color: Color = Color(0.9, 0.96, 1.0, 0.92)
@export var preview_color: Color = Color(0.95, 0.08, 0.08, 0.28)
@export var locked_color: Color = Color(0.12, 0.02, 0.025, 0.45)
@export var message_cooldown: float = 2.4
@export var path_collision_enabled: bool = false
@export var always_show_preview: bool = true
@export var preview_min_alpha: float = 0.38

@onready var path_visual: MeshInstance3D = $PathVisual
@onready var path_body: StaticBody3D = $PathBody
@onready var path_collision: CollisionShape3D = $PathBody/CollisionShape3D
@onready var lock_wall: StaticBody3D = $LockWall
@onready var lock_wall_visual: MeshInstance3D = $LockWall/WallVisual
@onready var lock_wall_collision: CollisionShape3D = $LockWall/CollisionShape3D
@onready var trigger_area: Area3D = $TriggerArea
@onready var trigger_collision: CollisionShape3D = $TriggerArea/CollisionShape3D
@onready var light: OmniLight3D = $GuideLight

var required_fragments := PackedStringArray()
var memory_state: Node
var is_unlocked: bool = false
var _message_timer: float = 0.0
var _has_announced_unlock: bool = false


func _ready() -> void:
	required_fragments = _parse_required_fragments()
	trigger_area.body_entered.connect(_on_trigger_body_entered)
	_resolve_memory_state()
	_configure_geometry()
	_update_state()


func _process(delta: float) -> void:
	_message_timer = maxf(_message_timer - delta, 0.0)
	if not is_instance_valid(memory_state):
		_resolve_memory_state()
	_update_state()


func _parse_required_fragments() -> PackedStringArray:
	var fragments := PackedStringArray()
	for raw_id in required_fragments_csv.split(",", false):
		var fragment_id := raw_id.strip_edges()
		if not fragment_id.is_empty():
			fragments.append(fragment_id)

	return fragments


func _resolve_memory_state() -> void:
	var nodes := get_tree().get_nodes_in_group("memory_state")
	if nodes.size() == 0:
		return

	memory_state = nodes[0]
	if memory_state.has_signal("fragment_collected") and not memory_state.fragment_collected.is_connected(_on_fragment_collected):
		memory_state.fragment_collected.connect(_on_fragment_collected)


func _configure_geometry() -> void:
	path_visual.mesh = path_visual.mesh.duplicate()
	path_collision.shape = path_collision.shape.duplicate()
	lock_wall_visual.mesh = lock_wall_visual.mesh.duplicate()
	lock_wall_collision.shape = lock_wall_collision.shape.duplicate()
	trigger_collision.shape = trigger_collision.shape.duplicate()

	var path_mesh := path_visual.mesh as BoxMesh
	if path_mesh:
		path_mesh.size = path_size

	var path_shape := path_collision.shape as BoxShape3D
	if path_shape:
		path_shape.size = path_size
	path_collision.disabled = not path_collision_enabled

	lock_wall.position = Vector3(0.0, 1.0, -path_size.z * 0.42)
	var wall_size := Vector3(path_size.x + 0.7, 2.0, 0.22)
	var wall_mesh := lock_wall_visual.mesh as BoxMesh
	if wall_mesh:
		wall_mesh.size = wall_size

	var wall_shape := lock_wall_collision.shape as BoxShape3D
	if wall_shape:
		wall_shape.size = wall_size

	trigger_area.position = lock_wall.position
	var trigger_shape := trigger_collision.shape as BoxShape3D
	if trigger_shape:
		trigger_shape.size = Vector3(path_size.x + 1.2, 2.4, 1.0)

	light.position = Vector3(0.0, 0.8, 0.0)


func _update_state() -> void:
	var progress := _get_progress_ratio()
	var new_unlocked := required_fragments.is_empty()
	if memory_state and memory_state.has_method("has_fragments"):
		new_unlocked = memory_state.has_fragments(required_fragments)

	var was_unlocked := is_unlocked
	if new_unlocked != is_unlocked:
		is_unlocked = new_unlocked
		if is_unlocked and not was_unlocked and not _has_announced_unlock:
			_has_announced_unlock = true
			_show_path_message(segment_title, "This section is complete. Follow the red light and stone trail.", 3.2)

	lock_wall.visible = not is_unlocked
	path_collision.set_deferred("disabled", not path_collision_enabled)
	lock_wall_collision.set_deferred("disabled", is_unlocked)
	trigger_area.set_deferred("monitoring", not is_unlocked)

	if is_unlocked:
		path_visual.visible = true
		path_visual.set_surface_override_material(0, _make_material(unlocked_color))
		light.light_color = Color(0.82, 0.95, 1.0, 1.0)
		light.light_energy = 1.2
	else:
		var alpha := lerpf(preview_min_alpha, preview_color.a, progress)
		var color := preview_color
		color.a = alpha
		path_visual.visible = always_show_preview or progress > 0.0
		path_visual.set_surface_override_material(0, _make_material(color))
		lock_wall_visual.set_surface_override_material(0, _make_material(locked_color))
		light.light_color = Color(1.0, 0.08, 0.08, 1.0)
		light.light_energy = lerpf(0.42, 0.95, progress)


func _get_progress_ratio() -> float:
	if required_fragments.size() == 0:
		return 1.0
	if not memory_state or not memory_state.has_method("count_matching"):
		return 0.0

	return float(memory_state.count_matching(required_fragments)) / float(required_fragments.size())


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0)
	material.emission_energy_multiplier = 1.25
	material.roughness = 0.7
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _on_trigger_body_entered(body: Node3D) -> void:
	if is_unlocked or not body.is_in_group("player") or _message_timer > 0.0:
		return

	_message_timer = message_cooldown
	_show_locked_message()
	_notify_boss_pressure()


func _show_locked_message() -> void:
	_show_path_message(segment_title, locked_message, 3.4)


func _show_path_message(title: String, line: String, duration: float) -> void:
	var ui_nodes := get_tree().get_nodes_in_group("player_status_ui")
	if ui_nodes.size() == 0:
		return

	var ui := ui_nodes[0]
	if ui and ui.has_method("show_memory_fragment"):
		ui.show_memory_fragment(title, line, duration)


func _notify_boss_pressure() -> void:
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss and boss.has_method("spawn_pressure_wave"):
			boss.spawn_pressure_wave("hidden_road_denied")


func _on_fragment_collected(_fragment_id: String, _collected_count: int) -> void:
	_update_state()
