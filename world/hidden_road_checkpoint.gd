extends Area3D

@export var checkpoint_index: int = 0
@export var required_previous_index: int = -1
@export var announce_once: bool = false
@export var message_title: String = "Hidden Path"
@export_multiline var message_line: String = "You are walking a path that was hidden."

var _has_announced: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		_try_mark_checkpoint(body)


func _on_body_entered(body: Node3D) -> void:
	_try_mark_checkpoint(body)


func _try_mark_checkpoint(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	var current_index := int(body.get_meta("hidden_road_checkpoint", -1))
	if current_index >= checkpoint_index:
		return
	if current_index < required_previous_index:
		return

	body.set_meta("hidden_road_checkpoint", checkpoint_index)

	if not _has_announced:
		_has_announced = true
		_show_progress()


func _show_progress() -> void:
	var ui_nodes := get_tree().get_nodes_in_group("player_status_ui")
	if ui_nodes.size() == 0:
		return

	var ui := ui_nodes[0]
	var checkpoint_count := clampi(checkpoint_index + 1, 0, 4)
	if ui and ui.has_method("show_memory_fragment"):
		ui.show_memory_fragment(
			"HIDDEN ROAD",
			"Follow the Red Thread — Checkpoint %d/4." % checkpoint_count,
			3.0
		)
	if ui and ui.has_method("set_objective"):
		ui.set_objective(
			"FOLLOW THE RED THREAD",
			"Hidden-road checkpoints: %d/4" % checkpoint_count
		)
