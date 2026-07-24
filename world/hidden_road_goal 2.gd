extends Area3D

@export var completion_title: String = "Hidden Path"
@export_multiline var completion_line: String = "You followed the concealed path to the door. Now you can face what is truly inside the house."
@export var incomplete_title: String = "Yellow Light at the Door"
@export_multiline var incomplete_line: String = "This is the end of the hidden path, but the road is not fully remembered. Collect every memory fragment."
@export var require_hidden_route: bool = true
@export var required_route_checkpoint: int = 3
@export var route_locked_title: String = "The Yellow Light Is Out of Reach"
@export_multiline var route_locked_line: String = "You can see the yellow light, but you have not walked the hidden path. Return to the broken signpost and follow the red light."

var _completed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


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
