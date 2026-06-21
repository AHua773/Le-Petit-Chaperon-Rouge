
extends CharacterBody3D

@export var move_speed: float = 5.0
@export var acceleration: float = 20.0
@export var jump_velocity: float = 7.0
@export var rotation_speed: float = 12.0

var gravity: float = ProjectSettings.get_setting(
	"physics/3d/default_gravity"
)


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	move_and_slide()


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# 防止角色落地后积累向下速度
		if velocity.y < 0.0:
			velocity.y = 0.0


func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity


func handle_movement(delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction := Vector3(
		input_vector.x,
		0.0,
		input_vector.y
	)

	if direction.length_squared() > 0.0:
		direction = direction.normalized()

		velocity.x = move_toward(
			velocity.x,
			direction.x * move_speed,
			acceleration * delta
		)

		velocity.z = move_toward(
			velocity.z,
			direction.z * move_speed,
			acceleration * delta
		)

		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(
			rotation.y,
			target_angle,
			rotation_speed * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			acceleration * delta
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			acceleration * delta
		)
