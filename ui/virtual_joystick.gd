extends Control

@export var dead_zone: float = 0.16
@export var knob_radius_ratio: float = 0.38
@export var joystick_radius: float = 92.0
@export var edge_margin: float = 26.0
@export var base_color := Color(0.08, 0.08, 0.12, 0.48)
@export var rim_color := Color(0.92, 0.92, 1.0, 0.62)
@export var knob_color := Color(0.86, 0.9, 1.0, 0.78)

var value := Vector2.ZERO
var base_position := Vector2.ZERO
var _touch_index := -1
var _mouse_active := false
var _active := false


func _ready() -> void:
	add_to_group("virtual_joystick")
	# Listen at viewport level. On iOS, gameplay viewports can consume a touch
	# before Control._gui_input receives it.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and _is_in_activation_area(event.position):
			_touch_index = event.index
			_begin_at(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_value(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_in_activation_area(event.position):
			_mouse_active = true
			_begin_at(get_local_mouse_position())
		elif not event.pressed and _mouse_active:
			_mouse_active = false
			_reset()
	elif event is InputEventMouseMotion and _mouse_active:
		_update_value(get_local_mouse_position())


func _is_in_activation_area(viewport_position: Vector2) -> bool:
	return viewport_position.x <= get_viewport_rect().size.x * 0.5


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if not _active:
		return

	var radius := _base_radius()
	draw_circle(base_position, radius, base_color)
	draw_arc(base_position, radius - 2.0, 0.0, TAU, 64, rim_color, 4.0, true)
	draw_circle(base_position + value * radius, radius * knob_radius_ratio, knob_color)


func _update_value(local_position: Vector2) -> void:
	var offset := (local_position - base_position) / _base_radius()
	value = offset.limit_length(1.0)
	if value.length() < dead_zone:
		value = Vector2.ZERO
	queue_redraw()


func _reset() -> void:
	value = Vector2.ZERO
	_active = false
	queue_redraw()


func _base_radius() -> float:
	return maxf(joystick_radius, 1.0)


func _begin_at(local_position: Vector2) -> void:
	var radius := _base_radius()
	var canvas_size := get_viewport().get_visible_rect().size
	base_position = Vector2(
		clampf(local_position.x, radius + edge_margin, canvas_size.x * 0.5 - radius - edge_margin),
		clampf(local_position.y, radius + edge_margin, canvas_size.y - radius - edge_margin)
	)
	_active = true
	_update_value(local_position)
