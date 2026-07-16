extends Area3D

@export var hidden_road_windup_time: float = 0.6
@export var message_title: String = "隐藏路"
@export_multiline var message_line: String = "你已经记起了这条路。狼的锁定变慢了，但它们还没有停下。"

var _has_triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	if not _has_all_memories():
		return

	_slow_wolf_fragments()
	if not _has_triggered:
		_has_triggered = true
		_show_message()


func _slow_wolf_fragments() -> void:
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss and boss.has_method("set_hidden_road_windup_time"):
			boss.set_hidden_road_windup_time(hidden_road_windup_time)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy and enemy.has_method("set_hidden_road_windup_time"):
			enemy.set_hidden_road_windup_time(hidden_road_windup_time)


func _has_all_memories() -> bool:
	var nodes := get_tree().get_nodes_in_group("memory_state")
	if nodes.size() == 0:
		return false

	var memory_state := nodes[0]
	return memory_state.has_method("get_collected_count") and memory_state.has_method("get_total_count") and memory_state.get_collected_count() >= memory_state.get_total_count()


func _show_message() -> void:
	var ui_nodes := get_tree().get_nodes_in_group("player_status_ui")
	if ui_nodes.size() == 0:
		return

	var ui := ui_nodes[0]
	if ui and ui.has_method("show_memory_fragment"):
		ui.show_memory_fragment(message_title, message_line, 3.2)
