extends Node3D

const GRASS_MATERIAL_NAME := "grass_green"

@export_range(0.25, 1.0, 0.05) var cell_size: float = 0.5
@export_range(1, 32, 1) var grass_sample_stride: int = 8
@export_range(0.25, 1.5, 0.05) var grass_detection_radius: float = 0.65
@export_range(0.05, 0.6, 0.01) var grass_height_threshold: float = 0.18

var _grass_cells: Dictionary = {}


func _ready() -> void:
	add_to_group("terrain_surface_detector")
	_collect_grass_cells(self)


func is_position_on_road(world_position: Vector3) -> bool:
	var center_cell := _to_cell(world_position)
	var cell_radius := ceili(grass_detection_radius / cell_size)

	for cell_x in range(center_cell.x - cell_radius, center_cell.x + cell_radius + 1):
		for cell_z in range(center_cell.y - cell_radius, center_cell.y + cell_radius + 1):
			var grass_cell := Vector2i(cell_x, cell_z)
			if not _grass_cells.has(grass_cell):
				continue
			if float(_grass_cells[grass_cell]) < grass_height_threshold:
				continue

			var cell_center := Vector2(
				(cell_x + 0.5) * cell_size,
				(cell_z + 0.5) * cell_size
			)
			if cell_center.distance_to(Vector2(world_position.x, world_position.z)) <= grass_detection_radius:
				return false

	return true


func _collect_grass_cells(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			_collect_grass_from_mesh(child)
		_collect_grass_cells(child)


func _collect_grass_from_mesh(mesh_instance: MeshInstance3D) -> void:
	var source_mesh := mesh_instance.mesh
	if source_mesh == null:
		return

	for surface_index in source_mesh.get_surface_count():
		var material := source_mesh.surface_get_material(surface_index)
		if material == null or not material.resource_name.to_lower().contains(GRASS_MATERIAL_NAME):
			continue

		var arrays := source_mesh.surface_get_arrays(surface_index)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for vertex_index in range(0, vertices.size(), grass_sample_stride):
			var world_vertex := mesh_instance.global_transform * vertices[vertex_index]
			var cell := _to_cell(world_vertex)
			var previous_height := float(_grass_cells.get(cell, -INF))
			_grass_cells[cell] = maxf(previous_height, world_vertex.y)


func _to_cell(world_position: Vector3) -> Vector2i:
	return Vector2i(
		floori(world_position.x / cell_size),
		floori(world_position.z / cell_size)
	)
