extends Node3D

@export var wolf_fragment_scene: PackedScene
@export var activation_range: float = 17.0
@export var spawn_interval: float = 6.0
@export var pressure_wave_cooldown: float = 3.0
@export var max_active_minions: int = 4
@export var regular_spawn_count: int = 1
@export var pressure_spawn_count: int = 2

@onready var visual: Node3D = $Visual
@onready var summon_root: Node3D = $Summons
@onready var summon_points: Node3D = $SummonPoints

var player: Node3D
var memory_state: Node
var active: bool = false
var encounter_completed: bool = false
var hidden_road_suppressed: bool = false
var hidden_road_windup_override: float = -1.0
var spawn_timer: float = 0.0
var pressure_timer: float = 0.0
var taunt_timer: float = 0.0


func _ready() -> void:
	spawn_timer = spawn_interval * 0.5
	visual.visible = true
	_resolve_memory_state()


func _process(delta: float) -> void:
	if encounter_completed or hidden_road_suppressed:
		return

	_refresh_player()
	_resolve_memory_state()
	pressure_timer = maxf(pressure_timer - delta, 0.0)
	taunt_timer = maxf(taunt_timer - delta, 0.0)

	if not is_instance_valid(player):
		return

	active = global_position.distance_to(player.global_position) <= activation_range
	if not active:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = _get_spawn_interval()
		_spawn_minions(regular_spawn_count)
		_show_taunt("Wolf: The road has already been laid for you. Why keep looking behind the trees?")


func spawn_pressure_wave(_reason: String = "") -> void:
	if encounter_completed or hidden_road_suppressed:
		return

	if pressure_timer > 0.0:
		return

	pressure_timer = pressure_wave_cooldown
	active = true
	_spawn_minions(pressure_spawn_count)
	_show_taunt("Wolf: There is no path there. You simply remembered it wrong again.")


func complete_encounter() -> void:
	encounter_completed = true
	active = false
	visual.visible = false
	for child in summon_root.get_children():
		if is_instance_valid(child):
			child.queue_free()


func suppress_for_hidden_road() -> void:
	hidden_road_suppressed = true
	active = false
	visual.visible = false
	for child in summon_root.get_children():
		if is_instance_valid(child):
			child.queue_free()


func set_hidden_road_windup_time(value: float) -> void:
	hidden_road_windup_override = value
	for child in summon_root.get_children():
		if is_instance_valid(child) and child.has_method("set_hidden_road_windup_time"):
			child.set_hidden_road_windup_time(hidden_road_windup_override)


func _spawn_minions(count: int) -> void:
	if not wolf_fragment_scene:
		return

	var available_slots := max_active_minions - _get_active_minion_count()
	var spawn_count := mini(count, available_slots)
	if spawn_count <= 0:
		return

	var points := summon_points.get_children()
	if points.is_empty():
		return

	for i in range(spawn_count):
		var point := points[(randi() + i) % points.size()] as Node3D
		if not point:
			continue

		var minion := wolf_fragment_scene.instantiate() as Node3D
		summon_root.add_child(minion)
		minion.global_position = point.global_position
		minion.global_rotation = point.global_rotation
		minion.set("detection_range", 8.5)
		minion.set("wander_radius", 1.4)
		if hidden_road_windup_override > 0.0:
			minion.set("windup_time", hidden_road_windup_override)

		if minion.has_method("reset_home_position"):
			minion.reset_home_position()


func _get_active_minion_count() -> int:
	var count := 0
	for child in summon_root.get_children():
		if is_instance_valid(child):
			count += 1

	return count


func _get_spawn_interval() -> float:
	var memory_count := 0
	if memory_state and memory_state.has_method("get_collected_count"):
		memory_count = memory_state.get_collected_count()

	return maxf(spawn_interval - float(memory_count) * 0.35, 3.6)


func _show_taunt(line: String) -> void:
	if taunt_timer > 0.0:
		return

	taunt_timer = 4.0
	var ui_nodes := get_tree().get_nodes_in_group("player_status_ui")
	if ui_nodes.size() == 0:
		return

	var ui := ui_nodes[0]
	if ui and ui.has_method("show_memory_fragment"):
		ui.show_memory_fragment("Defining the Wolf", line, 3.0)


func _refresh_player() -> void:
	if is_instance_valid(player):
		return

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node3D


func _resolve_memory_state() -> void:
	if is_instance_valid(memory_state):
		return

	var nodes := get_tree().get_nodes_in_group("memory_state")
	if nodes.size() > 0:
		memory_state = nodes[0]
