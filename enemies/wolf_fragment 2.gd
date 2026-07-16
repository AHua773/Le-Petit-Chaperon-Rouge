extends CharacterBody3D

enum State {
	WANDER,
	WINDUP,
	LUNGE,
	RECOVER
}

@export var detection_range: float = 7.0
@export var wander_radius: float = 2.5
@export var wander_speed: float = 1.15
@export var acceleration: float = 18.0
@export var windup_time: float = 0.3
@export var lunge_speed: float = 11.0
@export var lunge_time: float = 0.42
@export var recovery_time: float = 1.2
@export var knockback_force: float = 7.5
@export var damage: float = 18.0
@export var sanity_damage: float = 8.0
@export_flags_3d_physics var line_of_sight_mask: int = 1
@export var eye_height: float = 0.58
@export var player_target_height: float = 0.95

@onready var windup_marker: MeshInstance3D = $Visual/WindupMarker
@onready var hitbox: Area3D = $Hitbox

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var state: int = State.WANDER
var state_timer: float = 0.0
var home_position: Vector3
var wander_target: Vector3
var wander_timer: float = 0.0
var lunge_direction: Vector3 = Vector3.FORWARD
var has_hit_player: bool = false
var pacified_for_hidden_road: bool = false
var player: Node3D


func _ready() -> void:
	home_position = global_position
	_pick_wander_target()
	windup_marker.visible = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)


func reset_home_position() -> void:
	home_position = global_position
	_pick_wander_target()


func pacify_for_hidden_road() -> void:
	pacified_for_hidden_road = true
	state = State.RECOVER
	state_timer = 0.0
	damage = 0.0
	sanity_damage = 0.0
	detection_range = 0.0
	lunge_speed = 0.0
	wander_speed = 0.0
	has_hit_player = true
	windup_marker.visible = false
	hitbox.monitoring = false
	velocity.x = 0.0
	velocity.z = 0.0


func set_hidden_road_windup_time(value: float) -> void:
	windup_time = value
	if state == State.WINDUP:
		state_timer = maxf(state_timer, windup_time)


func _physics_process(delta: float) -> void:
	_refresh_player()
	_apply_gravity(delta)

	if pacified_for_hidden_road:
		_stop_horizontal(delta)
		windup_marker.visible = false
		move_and_slide()
		return

	match state:
		State.WANDER:
			_process_wander(delta)
		State.WINDUP:
			_process_windup(delta)
		State.LUNGE:
			_process_lunge(delta)
		State.RECOVER:
			_process_recover(delta)

	move_and_slide()

	if state == State.LUNGE:
		_stop_lunge_on_obstacle_collision()
		_check_lunge_hits()


func _process_wander(delta: float) -> void:
	windup_marker.visible = false
	wander_timer -= delta

	var to_wander_target := wander_target - global_position
	to_wander_target.y = 0.0

	if to_wander_target.length() < 0.25 or wander_timer <= 0.0:
		_pick_wander_target()
		to_wander_target = wander_target - global_position
		to_wander_target.y = 0.0

	if to_wander_target.length_squared() > 0.001:
		var wander_direction := to_wander_target.normalized()
		_set_horizontal_velocity(wander_direction * wander_speed, delta)
		_face_direction(wander_direction)
	else:
		_stop_horizontal(delta)

	if _can_see_player():
		_enter_windup()


func _process_windup(delta: float) -> void:
	state_timer -= delta
	_stop_horizontal(delta)
	windup_marker.visible = true

	var direction_to_player := _direction_to_player()
	if direction_to_player.length_squared() > 0.001:
		lunge_direction = direction_to_player.normalized()
		_face_direction(lunge_direction)

	if state_timer <= 0.0:
		_enter_lunge()


func _process_lunge(delta: float) -> void:
	state_timer -= delta
	windup_marker.visible = false
	_set_horizontal_velocity(lunge_direction * lunge_speed, delta)

	if state_timer <= 0.0:
		_enter_recover()


func _process_recover(delta: float) -> void:
	state_timer -= delta
	windup_marker.visible = false
	_stop_horizontal(delta)

	if state_timer <= 0.0:
		_pick_wander_target()
		state = State.WANDER


func _enter_windup() -> void:
	state = State.WINDUP
	state_timer = windup_time
	lunge_direction = _direction_to_player().normalized()
	has_hit_player = false
	windup_marker.visible = true


func _enter_lunge() -> void:
	state = State.LUNGE
	state_timer = lunge_time
	has_hit_player = false

	if lunge_direction.length_squared() <= 0.001:
		lunge_direction = -global_transform.basis.z
		lunge_direction.y = 0.0
		lunge_direction = lunge_direction.normalized()


func _enter_recover() -> void:
	state = State.RECOVER
	state_timer = recovery_time
	has_hit_player = true


func _refresh_player() -> void:
	if is_instance_valid(player):
		return

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node3D


func _can_see_player() -> bool:
	if not is_instance_valid(player):
		return false

	return (
		global_position.distance_to(player.global_position) <= detection_range
		and _has_clear_line_to(player)
	)


func _direction_to_player() -> Vector3:
	if not is_instance_valid(player):
		return Vector3.ZERO

	var direction := player.global_position - global_position
	direction.y = 0.0
	return direction


func _pick_wander_target() -> void:
	var angle := randf() * TAU
	var distance := randf_range(wander_radius * 0.35, wander_radius)
	wander_target = home_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
	wander_timer = randf_range(1.2, 2.8)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0


func _set_horizontal_velocity(target_velocity: Vector3, delta: float) -> void:
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)


func _stop_horizontal(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)


func _face_direction(direction: Vector3) -> void:
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		return

	look_at(global_position + direction.normalized(), Vector3.UP)


func _check_lunge_hits() -> void:
	if has_hit_player:
		return

	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and _has_clear_line_to(body):
			_hit_player(body)
			return


func _on_hitbox_body_entered(body: Node3D) -> void:
	if state == State.LUNGE and body.is_in_group("player") and _has_clear_line_to(body):
		_hit_player(body)


func _hit_player(body: Node3D) -> void:
	if has_hit_player:
		return

	has_hit_player = true

	if body.has_method("apply_enemy_hit"):
		body.apply_enemy_hit(global_position, knockback_force, damage, sanity_damage)

	_enter_recover()


func _has_clear_line_to(target: Node3D) -> bool:
	if not is_instance_valid(target):
		return false

	var origin := global_position + Vector3.UP * eye_height
	var target_position := target.global_position + Vector3.UP * player_target_height
	var query := PhysicsRayQueryParameters3D.create(origin, target_position, line_of_sight_mask, [get_rid()])
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return true

	var collider := result.get("collider") as Node
	if collider == target:
		return true

	return collider != null and collider.is_in_group("player") and target.is_in_group("player")


func _stop_lunge_on_obstacle_collision() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		if not collision:
			continue

		if collision.get_normal().y > 0.55:
			continue

		var collider := collision.get_collider() as Node
		if collider and collider.is_in_group("player"):
			continue

		velocity.x = 0.0
		velocity.z = 0.0
		_enter_recover()
		return
