extends Node

signal save_changed(has_save: bool)

const SAVE_PATH := "user://journey_save.json"
const SAVE_VERSION := 1

var _save_data: Dictionary = {}
var _pending_start_mode := ""


func _ready() -> void:
	_save_data = _read_save_file()


func has_save() -> bool:
	return not _save_data.is_empty()


func get_save_data() -> Dictionary:
	return _save_data.duplicate(true)


func request_continue() -> void:
	_pending_start_mode = "continue"


func request_new_game() -> void:
	clear_save()
	_pending_start_mode = "new"


func request_restart_checkpoint() -> void:
	_pending_start_mode = "restart"


func consume_start_mode() -> String:
	var mode := _pending_start_mode
	_pending_start_mode = ""
	if mode.is_empty():
		return "continue" if has_save() else "new"
	return mode


func create_new_save(
	spawn_position: Vector3,
	yaw: float,
	pitch: float,
	health: float,
	sanity: float
) -> void:
	_save_data = {
		"version": SAVE_VERSION,
		"updated_unix": int(Time.get_unix_time_from_system()),
		"fragments": [],
		"health": health,
		"sanity": sanity,
		"checkpoint": {
			"index": -1,
			"position": _vector3_to_array(spawn_position),
			"yaw": yaw,
			"pitch": pitch,
			"health": health,
			"sanity": sanity,
		},
	}
	_write_save_file()


func save_runtime(fragments: PackedStringArray, health: float, sanity: float) -> void:
	if _save_data.is_empty():
		return
	_save_data["fragments"] = Array(fragments)
	_save_data["health"] = health
	_save_data["sanity"] = sanity
	_save_data["updated_unix"] = int(Time.get_unix_time_from_system())
	_write_save_file()


func save_checkpoint(
	index: int,
	position: Vector3,
	yaw: float,
	pitch: float,
	health: float,
	sanity: float,
	fragments: PackedStringArray
) -> void:
	if _save_data.is_empty():
		create_new_save(position, yaw, pitch, health, sanity)
	_save_data["fragments"] = Array(fragments)
	_save_data["health"] = health
	_save_data["sanity"] = sanity
	_save_data["checkpoint"] = {
		"index": index,
		"position": _vector3_to_array(position),
		"yaw": yaw,
		"pitch": pitch,
		"health": health,
		"sanity": sanity,
	}
	_save_data["updated_unix"] = int(Time.get_unix_time_from_system())
	_write_save_file()


func get_checkpoint_position(data: Dictionary = {}) -> Vector3:
	var source := data if not data.is_empty() else _save_data
	var checkpoint: Dictionary = source.get("checkpoint", {})
	var values: Array = checkpoint.get("position", [])
	if values.size() != 3:
		return Vector3.ZERO
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


func clear_save() -> void:
	_save_data.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	save_changed.emit(false)


func _read_save_file() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var data := parsed as Dictionary
	if int(data.get("version", -1)) != SAVE_VERSION:
		return {}
	if not data.has("checkpoint") or not data.has("fragments"):
		return {}
	return data


func _write_save_file() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write journey save file.")
		return
	file.store_string(JSON.stringify(_save_data, "\t"))
	save_changed.emit(true)


func _vector3_to_array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]
