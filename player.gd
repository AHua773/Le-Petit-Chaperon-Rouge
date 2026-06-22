extends CharacterBody3D

enum PlayerState {
	IDLE,
	RUN,
	JUMP
}

@export var move_speed: float = 5.0
@export var acceleration: float = 20.0
@export var jump_velocity: float = 7.0
@export var rotation_speed: float = 12.0

@export var idle_anim_speed: float = 1.0
@export var run_anim_speed: float = 1.0
@export var jump_anim_speed: float = 0.8

@onready var idle_model: Node3D = $IdleModel
@onready var run_model: Node3D = $RunModel
@onready var jump_model: Node3D = $JumpModel

@onready var idle_anim: AnimationPlayer = $IdleModel/AnimationPlayer
@onready var run_anim: AnimationPlayer = $RunModel/AnimationPlayer
@onready var jump_anim: AnimationPlayer = $JumpModel/AnimationPlayer

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_facing_y: float = 0.0
var current_state: PlayerState = PlayerState.JUMP


func _ready() -> void:
	current_facing_y = rotation.y

	idle_anim.get_animation("mixamo_com").loop_mode = Animation.LOOP_LINEAR
	run_anim.get_animation("mixamo_com").loop_mode = Animation.LOOP_LINEAR
	jump_anim.get_animation("mixamo_com").loop_mode = Animation.LOOP_NONE

	change_state(PlayerState.IDLE)


func _physics_process(delta: float) -> void:
	handle_jump()
	apply_gravity(delta)
	handle_movement(delta)
	update_state()
	reset_model_local_position()
	move_and_slide()


func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		change_state(PlayerState.JUMP)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0


func handle_movement(delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction := Vector3(input_vector.x, 0.0, input_vector.y)

	if direction.length_squared() > 0.0:
		direction = direction.normalized()

		velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)

		var target_angle := atan2(direction.x, direction.z)
		current_facing_y = lerp_angle(current_facing_y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	apply_facing_to_models()


func update_state() -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	if not is_on_floor():
		change_state(PlayerState.JUMP)
	elif horizontal_speed > 0.1:
		change_state(PlayerState.RUN)
	else:
		change_state(PlayerState.IDLE)


func change_state(new_state: PlayerState) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	idle_model.visible = false
	run_model.visible = false
	jump_model.visible = false

	match current_state:
		PlayerState.IDLE:
			idle_model.visible = true
			if idle_anim:
				idle_anim.play("mixamo_com", -1.0, idle_anim_speed)

		PlayerState.RUN:
			run_model.visible = true
			if run_anim:
				run_anim.play("mixamo_com", -1.0, run_anim_speed)

		PlayerState.JUMP:
			jump_model.visible = true
			if jump_anim:
				jump_anim.stop()
				jump_anim.play("mixamo_com", -1.0, jump_anim_speed)

	apply_facing_to_models()


func apply_facing_to_models() -> void:
	idle_model.rotation.y = current_facing_y
	run_model.rotation.y = current_facing_y
	jump_model.rotation.y = current_facing_y


func reset_model_local_position() -> void:
	idle_model.position = Vector3.ZERO
	run_model.position = Vector3.ZERO
	jump_model.position = Vector3.ZERO
