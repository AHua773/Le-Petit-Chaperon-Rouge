extends Node3D

@export var message_title: String = "正门陷阱"
@export_multiline var message_line: String = "门不是安全。它只是在等你主动走进去。"
@export var message_cooldown: float = 2.8

@onready var trigger_area: Area3D = $TriggerArea

var _message_timer: float = 0.0


func _ready() -> void:
	trigger_area.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_message_timer = maxf(_message_timer - delta, 0.0)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or _message_timer > 0.0:
		return

	_message_timer = message_cooldown
	_show_message()
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss and boss.has_method("spawn_pressure_wave"):
			boss.spawn_pressure_wave("false_door")


func _show_message() -> void:
	var ui_nodes := get_tree().get_nodes_in_group("player_status_ui")
	if ui_nodes.size() == 0:
		return

	var ui := ui_nodes[0]
	if ui and ui.has_method("show_memory_fragment"):
		ui.show_memory_fragment(message_title, message_line, 3.4)
