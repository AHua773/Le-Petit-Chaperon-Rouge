extends CharacterBody3D

@export var move_speed: float = 5.0
@export var acceleration: float = 20.0
@export var jump_velocity: float = 7.0
@export var rotation_speed: float = 12.0

@onready var idle_model: Node3D = $IdleModel
@onready var run_model: Node3D = $RunModel

@onready var idle_anim: AnimationPlayer = $IdleModel/AnimationPlayer
@onready var run_anim: AnimationPlayer = $RunModel/AnimationPlayer

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	idle_model.visible = true
	run_model.visible = false
	idle_anim.play("mixamo_com")


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	update_model_and_animation()
	move_and_slide()


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
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

	var direction := Vector3(input_vector.x, 0.0, input_vector.y)

	if direction.length_squared() > 0.0:
		direction = direction.normalized()

		velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)

		var target_angle := atan2(direction.x, direction.z)

		idle_model.rotation.y = lerp_angle(idle_model.rotation.y, target_angle, rotation_speed * delta)
		run_model.rotation.y = idle_model.rotation.y
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)


func update_model_and_animation() -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	if horizontal_speed > 0.1:
		idle_model.visible = false
		run_model.visible = true

		if run_anim.current_animation != "mixamo_com":
			run_anim.play("mixamo_com")
	else:
		idle_model.visible = true
		run_model.visible = false

		if idle_anim.current_animation != "mixamo_com":
			idle_anim.play("mixamo_com")
