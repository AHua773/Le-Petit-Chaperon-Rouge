extends Node3D

@export var tree_radius: float = 0.46
@export var tree_height: float = 1.85
@export var rock_radius: float = 0.48
@export var rock_height: float = 0.72
@export var post_radius: float = 0.24
@export var post_height: float = 1.25
@export var log_size: Vector3 = Vector3(1.9, 0.55, 0.7)
@export var grave_size: Vector3 = Vector3(0.6, 0.9, 0.26)
@export var fence_size: Vector3 = Vector3(2.0, 0.85, 0.24)
@export_flags_3d_physics var obstacle_collision_layer: int = 1
@export_flags_3d_physics var obstacle_collision_mask: int = 1

var obstacle_root: Node3D


func _ready() -> void:
	_build_obstacle_proxies()


func _build_obstacle_proxies() -> void:
	obstacle_root = Node3D.new()
	obstacle_root.name = "GeneratedObstacleProxies"
	add_child(obstacle_root)

	var source_nodes := get_children()
	for source in source_nodes:
		if source == obstacle_root or not (source is Node3D):
			continue

		_add_proxy_for(source as Node3D)


func _add_proxy_for(source: Node3D) -> void:
	var lower_name := source.name.to_lower()
	if lower_name.contains("tree"):
		var shape := CylinderShape3D.new()
		shape.radius = tree_radius
		shape.height = tree_height
		_add_proxy_body(source, shape, Vector3(0.0, tree_height * 0.5, 0.0), false)
	elif lower_name.contains("fallen_log"):
		var shape := BoxShape3D.new()
		shape.size = log_size
		_add_proxy_body(source, shape, Vector3(0.0, log_size.y * 0.5, 0.0), true)
	elif lower_name.contains("rock"):
		var shape := CylinderShape3D.new()
		shape.radius = rock_radius
		shape.height = rock_height
		_add_proxy_body(source, shape, Vector3(0.0, rock_height * 0.5, 0.0), false)
	elif lower_name.contains("gravemarker") or lower_name.contains("grave"):
		var shape := BoxShape3D.new()
		shape.size = grave_size
		_add_proxy_body(source, shape, Vector3(0.0, grave_size.y * 0.5, 0.0), true)
	elif lower_name.contains("fence"):
		var shape := BoxShape3D.new()
		shape.size = fence_size
		_add_proxy_body(source, shape, Vector3(0.0, fence_size.y * 0.5, 0.0), true)
	elif lower_name.contains("postlantern"):
		var shape := CylinderShape3D.new()
		shape.radius = post_radius
		shape.height = post_height
		_add_proxy_body(source, shape, Vector3(0.0, post_height * 0.5, 0.0), false)


func _add_proxy_body(source: Node3D, shape: Shape3D, shape_offset: Vector3, use_source_yaw: bool) -> void:
	var body := StaticBody3D.new()
	body.name = "%s_Obstacle" % source.name
	body.collision_layer = obstacle_collision_layer
	body.collision_mask = obstacle_collision_mask
	obstacle_root.add_child(body)
	body.global_position = source.global_position

	if use_source_yaw:
		body.global_rotation = Vector3(0.0, source.global_rotation.y, 0.0)

	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = shape_offset
	body.add_child(collision)
