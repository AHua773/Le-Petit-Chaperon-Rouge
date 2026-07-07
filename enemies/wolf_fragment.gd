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
var player: Node3D


func _ready() -> void:
	home_position = global_position
	_pick_wander_target()
	windup_marker.visible = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)


func _physics_process(delta: float) -> void:
	_refresh_player()
	_apply_gravity(delta)

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

	return global_position.distance_to(player.global_position) <= detection_range


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
		if body.is_in_group("player"):
			_hit_player(body)
			return


func _on_hitbox_body_entered(body: Node3D) -> void:
	if state == State.LUNGE and body.is_in_group("player"):
		_hit_player(body)


func _hit_player(body: Node3D) -> void:
	if has_hit_player:
		return

	has_hit_player = true

	if body.has_method("apply_enemy_hit"):
		body.apply_enemy_hit(global_position, knockback_force, damage, sanity_damage)

	_enter_recover()
