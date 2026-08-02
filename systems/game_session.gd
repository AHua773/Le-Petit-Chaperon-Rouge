extends Node

const AUTOSAVE_INTERVAL := 3.0
const SETTINGS_PATH := "user://app_settings.cfg"

var _player: Node
var _memory_state: Node
var _autosave_elapsed := 0.0
var _initialized := false


func _ready() -> void:
	add_to_group("game_session")
	call_deferred("_initialize_session")


func _process(delta: float) -> void:
	if not _initialized or get_tree().paused:
		return
	_autosave_elapsed += delta
	if _autosave_elapsed >= AUTOSAVE_INTERVAL:
		_autosave_elapsed = 0.0
		save_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		save_now()


func save_now() -> void:
	if not _initialized or not is_instance_valid(_player) or not is_instance_valid(_memory_state):
		return
	if bool(_player.get("is_downed")):
		return
	var state := _player.get_save_state() as Dictionary
	GameSave.save_runtime(
		_memory_state.get_collected_fragment_ids(),
		float(state.get("health", 100.0)),
		float(state.get("sanity", 100.0))
	)


func register_checkpoint(checkpoint_index: int, player_body: Node3D) -> void:
	if not _initialized or player_body != _player:
		return
	var state := _player.get_save_state() as Dictionary
	GameSave.save_checkpoint(
		checkpoint_index,
		player_body.global_position,
		float(state.get("yaw", 0.0)),
		float(state.get("pitch", 0.0)),
		float(state.get("health", 100.0)),
		float(state.get("sanity", 100.0)),
		_memory_state.get_collected_fragment_ids()
	)


func restart_checkpoint() -> void:
	if not GameSave.has_save():
		return
	GameSave.request_restart_checkpoint()
	get_tree().paused = false
	get_tree().reload_current_scene()


func return_to_title() -> void:
	save_now()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://ui/app_launcher.tscn")


func _initialize_session() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_memory_state = get_tree().get_first_node_in_group("memory_state")
	if not is_instance_valid(_player) or not is_instance_valid(_memory_state):
		push_error("GameSession could not find Player or MemoryState.")
		return

	_apply_gameplay_settings()
	var mode := GameSave.consume_start_mode()
	if mode == "new" or not GameSave.has_save():
		_start_new_journey()
	else:
		_restore_journey(mode == "restart")

	if _memory_state.has_signal("fragment_collected"):
		_memory_state.fragment_collected.connect(_on_fragment_collected)
	_initialized = true


func _start_new_journey() -> void:
	var spawn_point := get_node_or_null("SpawnPoint") as Marker3D
	var spawn_position: Vector3 = _player.global_position
	if spawn_point:
		spawn_position = spawn_point.global_position
	var state := _player.get_save_state() as Dictionary
	GameSave.create_new_save(
		spawn_position,
		float(state.get("yaw", 0.0)),
		float(state.get("pitch", 0.0)),
		float(state.get("health", 100.0)),
		float(state.get("sanity", 100.0))
	)


func _restore_journey(use_checkpoint_vitals: bool) -> void:
	var data := GameSave.get_save_data()
	var checkpoint: Dictionary = data.get("checkpoint", {})
	var raw_fragments: Array = data.get("fragments", [])
	var fragment_ids := PackedStringArray()
	for value in raw_fragments:
		fragment_ids.append(str(value))
	_memory_state.restore_fragments(fragment_ids)
	_remove_collected_fragments(fragment_ids)

	var health := float(data.get("health", _player.max_health))
	var sanity := float(data.get("sanity", _player.max_sanity))
	if use_checkpoint_vitals:
		health = float(checkpoint.get("health", health))
		sanity = float(checkpoint.get("sanity", sanity))
	_player.restore_saved_state(
		health,
		sanity,
		GameSave.get_checkpoint_position(data),
		float(checkpoint.get("yaw", 0.0)),
		float(checkpoint.get("pitch", 0.0)),
		int(checkpoint.get("index", -1))
	)


func _remove_collected_fragments(fragment_ids: PackedStringArray) -> void:
	for fragment in get_tree().get_nodes_in_group("memory_fragment"):
		var fragment_id := str(fragment.get("fragment_id"))
		if fragment_id in fragment_ids:
			fragment.queue_free()


func _on_fragment_collected(_fragment_id: String, _collected_count: int) -> void:
	save_now()


func _apply_gameplay_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return
	var look_sensitivity := clampf(
		float(settings.get_value("gameplay", "look_sensitivity", 0.5)),
		0.0,
		1.0
	)
	if _player.has_method("apply_look_sensitivity"):
		_player.apply_look_sensitivity(look_sensitivity)
