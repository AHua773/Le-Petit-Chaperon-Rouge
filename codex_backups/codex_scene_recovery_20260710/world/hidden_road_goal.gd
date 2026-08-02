extends Area3D

@export var completion_title: String = "隐藏道路"
@export_multiline var completion_line: String = "真正的侧门出现了。你不是被带到这里，是自己看见了这里。"

var _completed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _completed or not body.is_in_group("player"):
		return

	if not _has_all_memories():
		_show_message("道路尚未完整", "最后一段路仍在雾里。你还没有完整地理解狼。")
		for boss in get_tree().get_nodes_in_group("boss"):
			if boss and boss.has_method("spawn_pressure_wave"):
				boss.spawn_pressure_wave("unfinished_goal")
		return

	_completed = true
	_show_message(completion_title, completion_line)
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss and boss.has_method("complete_encounter"):
			boss.complete_encounter()


func _has_all_memories() -> bool:
	var nodes := get_tree().get_nodes_in_group("memory_state")
	if nodes.size() == 0:
		return false

	var memory_state := nodes[0]
	return memory_state.has_method("get_collected_count") and memory_state.has_method("get_total_count") and memory_state.get_collected_count() >= memory_state.get_total_count()


func _show_message(title: String, line: String) -> void:
	var ui_nodes := get_tree().get_nodes_in_group("player_status_ui")
	if ui_nodes.size() == 0:
		return

	var ui := ui_nodes[0]
	if ui and ui.has_method("show_memory_fragment"):
		ui.show_memory_fragment(title, line, 4.0)
