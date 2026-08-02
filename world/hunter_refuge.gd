extends Area3D

@export var required_fragment_id: String = "memory_04"
@export var protection_radius: float = 3.2

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visual: MeshInstance3D = $Visual
@onready var refuge_light: OmniLight3D = $RefugeLight

var _active: bool = false
var _memory_state: Node


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_configure_radius()
	_set_active(false)
	_resolve_memory_state()


func _resolve_memory_state() -> void:
	var nodes := get_tree().get_nodes_in_group("memory_state")
	if nodes.is_empty():
		return

	_memory_state = nodes[0]
	if _memory_state.has_signal("fragment_collected") and not _memory_state.fragment_collected.is_connected(_on_fragment_collected):
		_memory_state.fragment_collected.connect(_on_fragment_collected)

	if _memory_state.has_method("has_fragment") and _memory_state.has_fragment(required_fragment_id):
		_activate()


func _configure_radius() -> void:
	var shape := collision_shape.shape as CylinderShape3D
	if shape:
		shape = shape.duplicate()
		shape.radius = protection_radius
		collision_shape.shape = shape

	var mesh := visual.mesh as CylinderMesh
	if mesh:
		mesh = mesh.duplicate()
		mesh.top_radius = protection_radius
		mesh.bottom_radius = protection_radius
		visual.mesh = mesh

	refuge_light.omni_range = protection_radius + 0.8


func _on_fragment_collected(fragment_id: String, _collected_count: int) -> void:
	if fragment_id == required_fragment_id:
		_activate()


func _activate() -> void:
	if _active:
		return

	_active = true
	_set_active(true)
	call_deferred("_clear_nearby_enemies")


func _set_active(value: bool) -> void:
	visual.visible = value
	refuge_light.visible = value
	set_deferred("monitoring", value)


func _clear_nearby_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy is Node3D:
			continue

		var enemy_3d := enemy as Node3D
		var offset := enemy_3d.global_position - global_position
		offset.y = 0.0
		if offset.length() <= protection_radius:
			enemy_3d.queue_free()


func _on_body_entered(body: Node3D) -> void:
	if _active and body.is_in_group("enemy"):
		body.queue_free()
