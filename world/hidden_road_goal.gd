extends Area3D

@export var completion_title: String = "Safety Reached"
@export_multiline var completion_line: String = "You reached the end of the hidden path. The wolves have stopped. Nothing here can hurt you for now."
@export var incomplete_title: String = "Yellow Light at the Door"
@export_multiline var incomplete_line: String = "This is the end of the hidden path, but the road is not fully remembered. Collect every memory fragment."
@export var require_hidden_route: bool = true
@export var required_route_checkpoint: int = 3
@export var route_locked_title: String = "The Yellow Light Is Out of Reach"
@export_multiline var route_locked_line: String = "You can see the yellow light, but you have not walked the hidden path. Return to the broken signpost and follow the red light."

@onready var marker: MeshInstance3D = $Marker
@onready var beacon_beam: MeshInstance3D = $BeaconBeam
@onready var beacon_core: MeshInstance3D = $BeaconCore
@onready var completion_wave: MeshInstance3D = $CompletionWave
@onready var goal_light: OmniLight3D = $GoalLight
@onready var safety_overlay: CanvasLayer = $SafetyOverlay
@onready var safety_filter: ColorRect = $SafetyOverlay/Filter
@onready var safety_message: Control = $SafetyOverlay/SafetyMessage

var _completed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	safety_overlay.visible = false
	completion_wave.visible = false


func _physics_process(_delta: float) -> void:
	if _completed:
		return

	for body in get_overlapping_bodies():
		if body.is_in_group("player") and _can_complete(body):
			_complete_encounter()
			return


func _on_body_entered(body: Node3D) -> void:
	if _completed or not body.is_in_group("player"):
		return

	if require_hidden_route and not _has_walked_hidden_route(body):
		_show_message(route_locked_title, route_locked_line)
		for boss in get_tree().get_nodes_in_group("boss"):
			if boss and boss.has_method("spawn_pressure_wave"):
				boss.spawn_pressure_wave("shortcut_goal")
		return

	if not _has_all_memories():
		_show_message(incomplete_title, incomplete_line)
		for boss in get_tree().get_nodes_in_group("boss"):
			if boss and boss.has_method("spawn_pressure_wave"):
				boss.spawn_pressure_wave("unfinished_goal")
		return

	_complete_encounter()


func _complete_encounter() -> void:
	if _completed:
		return

	_completed = true
	_show_message(completion_title, completion_line)
	_terminate_enemy_actions()
	_play_completion_effects()


func _play_completion_effects() -> void:
	safety_overlay.visible = true
	safety_message.modulate.a = 0.0
	completion_wave.visible = true
	completion_wave.scale = Vector3(0.45, 1.0, 0.45)
	completion_wave.transparency = 0.0

	var filter_material := safety_filter.material as ShaderMaterial
	if filter_material:
		filter_material = filter_material.duplicate()
		safety_filter.material = filter_material
		filter_material.set_shader_parameter("intensity", 0.0)

	var effect_tween := create_tween()
	effect_tween.set_parallel(true)
	effect_tween.set_trans(Tween.TRANS_QUAD)
	effect_tween.set_ease(Tween.EASE_OUT)
	effect_tween.tween_property(completion_wave, "scale", Vector3(4.8, 1.0, 4.8), 1.6)
	effect_tween.tween_property(completion_wave, "transparency", 1.0, 1.6)
	effect_tween.tween_property(goal_light, "light_energy", 4.2, 0.45)
	effect_tween.tween_property(marker, "scale", Vector3(1.35, 1.0, 1.35), 0.7)
	effect_tween.tween_property(beacon_beam, "scale", Vector3(1.8, 1.25, 1.8), 0.7)
	effect_tween.tween_property(beacon_core, "scale", Vector3(1.8, 1.8, 1.8), 0.7)
	effect_tween.tween_property(safety_message, "modulate:a", 1.0, 0.9).set_delay(0.35)
	if filter_material:
		effect_tween.tween_method(_set_filter_intensity.bind(filter_material), 0.0, 0.62, 1.8)

	var settle_tween := create_tween()
	settle_tween.set_trans(Tween.TRANS_SINE)
	settle_tween.set_ease(Tween.EASE_IN_OUT)
	settle_tween.tween_interval(0.55)
	settle_tween.tween_property(goal_light, "light_energy", 2.15, 1.25)
	settle_tween.parallel().tween_property(beacon_core, "scale", Vector3(1.25, 1.25, 1.25), 1.25)
	settle_tween.parallel().tween_property(beacon_beam, "scale", Vector3(1.25, 1.08, 1.25), 1.25)


func _set_filter_intensity(value: float, material: ShaderMaterial) -> void:
	material.set_shader_parameter("intensity", value)


func _terminate_enemy_actions() -> void:
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss and boss.has_method("complete_encounter"):
			boss.complete_encounter()

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy and enemy.has_method("pacify_for_hidden_road"):
			enemy.pacify_for_hidden_road()


func _has_all_memories() -> bool:
	var nodes := get_tree().get_nodes_in_group("memory_state")
	if nodes.size() == 0:
		return false

	var memory_state := nodes[0]
	return memory_state.has_method("get_collected_count") and memory_state.has_method("get_total_count") and memory_state.get_collected_count() >= memory_state.get_total_count()


func _has_walked_hidden_route(body: Node3D) -> bool:
	return int(body.get_meta("hidden_road_checkpoint", -1)) >= required_route_checkpoint


func _can_complete(body: Node3D) -> bool:
	if require_hidden_route and not _has_walked_hidden_route(body):
		return false

	return _has_all_memories()


func _show_message(title: String, line: String) -> void:
	var ui_nodes := get_tree().get_nodes_in_group("player_status_ui")
	if ui_nodes.size() == 0:
		return

	var ui := ui_nodes[0]
	if ui and ui.has_method("show_memory_fragment"):
		ui.show_memory_fragment(title, line, 4.0)
