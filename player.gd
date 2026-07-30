extends CharacterBody3D

enum PlayerState {
	IDLE,
	RUN,
	JUMP
}

@export var move_speed: float = 5.0
@export var acceleration: float = 20.0
@export var jump_velocity: float = 7.0
@export var mouse_sensitivity: float = 0.0025
@export var touch_look_sensitivity: float = 0.004
@export var min_pitch: float = -75.0
@export var max_pitch: float = 75.0
@export var show_first_person_body: bool = false
@export var hit_stun_time: float = 0.25
@export var hit_knockback_lift: float = 2.0
@export var max_health: float = 100.0
@export var max_sanity: float = 100.0
@export var low_health_sanity_threshold: float = 0.35
@export var low_health_sanity_drain_rate: float = 7.0
@export var damage_camera_shake_strength: float = 0.28
@export var damage_camera_shake_time: float = 0.45
@export var low_sanity_camera_noise: float = 0.035

@export var idle_anim_speed: float = 1.0
@export var run_anim_speed: float = 1.0
@export var jump_anim_speed: float = 0.8

@onready var camera: Camera3D = $Camera3D
@onready var body_collision: CollisionShape3D = $CollisionShape3D
@onready var idle_model: Node3D = $IdleModel
@onready var run_model: Node3D = $RunModel
@onready var jump_model: Node3D = $JumpModel

@onready var idle_anim: AnimationPlayer = $IdleModel/AnimationPlayer
@onready var run_anim: AnimationPlayer = $RunModel/AnimationPlayer
@onready var jump_anim: AnimationPlayer = $JumpModel/AnimationPlayer

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_facing_y: float = 0.0
var camera_pitch: float = 0.0
var current_state: PlayerState = PlayerState.JUMP
var hit_stun_timer: float = 0.0
var current_health: float = 0.0
var current_sanity: float = 0.0
var has_shown_enemy_damage_hint: bool = false
var camera_base_position: Vector3
var camera_shake_timer: float = 0.0
var camera_shake_duration: float = 0.0
var camera_shake_strength: float = 0.0
var is_downed: bool = false
var status_ui: Node
var virtual_joystick: Node
var _look_touch_index := -1


func _ready() -> void:
	current_facing_y = rotation.y
	current_health = max_health
	current_sanity = max_sanity
	camera_base_position = camera.position
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	idle_anim.get_animation("mixamo_com").loop_mode = Animation.LOOP_LINEAR
	run_anim.get_animation("mixamo_com").loop_mode = Animation.LOOP_LINEAR
	jump_anim.get_animation("mixamo_com").loop_mode = Animation.LOOP_NONE

	change_state(PlayerState.IDLE)
	call_deferred("_connect_virtual_joystick")
	call_deferred("_update_status_ui")


func _process(delta: float) -> void:
	_update_sanity(delta)
	_update_camera_feedback(delta)
	_update_status_ui()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _look_touch_index == -1 and event.position.x > get_viewport().get_visible_rect().size.x * 0.5:
			_look_touch_index = event.index
		elif not event.pressed and event.index == _look_touch_index:
			_look_touch_index = -1
	elif event is InputEventScreenDrag and event.index == _look_touch_index:
		_rotate_view(event.relative.x * touch_look_sensitivity, event.relative.y * touch_look_sensitivity)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative.x * mouse_sensitivity, event.relative.y * mouse_sensitivity)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _rotate_view(yaw_delta: float, pitch_delta: float) -> void:
	current_facing_y -= yaw_delta
	camera_pitch = clamp(
		camera_pitch - pitch_delta,
		deg_to_rad(min_pitch),
		deg_to_rad(max_pitch)
	)
	apply_view_rotation()


func _physics_process(delta: float) -> void:
	if is_downed:
		apply_gravity(delta)
		_stop_after_down(delta)
		move_and_slide()
		return

	handle_jump()
	apply_gravity(delta)
	hit_stun_timer = maxf(hit_stun_timer - delta, 0.0)
	handle_movement(delta)
	update_state()
	reset_model_local_position()
	move_and_slide()


func handle_jump() -> void:
	if is_downed:
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		change_state(PlayerState.JUMP)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0


func handle_movement(delta: float) -> void:
	if is_downed:
		_stop_after_down(delta)
		return

	if hit_stun_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * 0.35 * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * 0.35 * delta)
		apply_view_rotation()
		return

	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)
	if not is_instance_valid(virtual_joystick):
		_connect_virtual_joystick()
	if is_instance_valid(virtual_joystick) and virtual_joystick.value.length_squared() > input_vector.length_squared():
		input_vector = virtual_joystick.value

	var forward := -global_transform.basis.z
	var right := global_transform.basis.x

	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var direction := right * input_vector.x + forward * -input_vector.y

	if direction.length_squared() > 0.0:
		direction = direction.normalized()

		velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	apply_view_rotation()


func _connect_virtual_joystick() -> void:
	virtual_joystick = get_tree().get_first_node_in_group("virtual_joystick")


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
			idle_model.visible = show_first_person_body
			if idle_anim:
				idle_anim.play("mixamo_com", -1.0, idle_anim_speed)

		PlayerState.RUN:
			run_model.visible = show_first_person_body
			if run_anim:
				run_anim.play("mixamo_com", -1.0, run_anim_speed)

		PlayerState.JUMP:
			jump_model.visible = show_first_person_body
			if jump_anim:
				jump_anim.stop()
				jump_anim.play("mixamo_com", -1.0, jump_anim_speed)

	apply_view_rotation()


func apply_view_rotation() -> void:
	rotation.y = current_facing_y
	camera.rotation.x = camera_pitch


func set_inventory_open(_is_open: bool) -> void:
	_look_touch_index = -1


func apply_enemy_hit(source_position: Vector3, force: float, damage: float = 12.0, sanity_damage: float = 6.0) -> void:
	if is_downed:
		return

	var knockback_direction := get_enemy_target_position() - source_position
	knockback_direction.y = 0.0

	if knockback_direction.length_squared() <= 0.001:
		knockback_direction = global_transform.basis.z

	knockback_direction = knockback_direction.normalized()
	velocity.x = knockback_direction.x * force
	velocity.z = knockback_direction.z * force
	velocity.y = maxf(velocity.y, hit_knockback_lift)
	hit_stun_timer = hit_stun_time
	current_health = clampf(current_health - damage, 0.0, max_health)
	current_sanity = clampf(current_sanity - sanity_damage, 0.0, max_sanity)

	_start_camera_shake(damage_camera_shake_strength, damage_camera_shake_time)
	_show_damage_feedback()
	_play_hit_sound()
	_update_status_ui()
	_show_enemy_damage_hint(damage, sanity_damage)

	if current_health <= 0.0:
		_enter_downed_state()


func get_enemy_target_position(height_offset: float = 0.0) -> Vector3:
	var target_position := global_position
	if body_collision:
		target_position.x = body_collision.global_position.x
		target_position.z = body_collision.global_position.z

	target_position.y = global_position.y + height_offset
	return target_position


func heal(amount: float) -> void:
	if amount <= 0.0:
		return

	current_health = clampf(current_health + amount, 0.0, max_health)
	if current_health > 0.0:
		is_downed = false
	_update_status_ui()


func restore_sanity(amount: float) -> void:
	if amount <= 0.0:
		return

	current_sanity = clampf(current_sanity + amount, 0.0, max_sanity)
	_update_status_ui()


func apply_medicine(health_amount: float, sanity_amount: float) -> void:
	if health_amount != 0.0:
		current_health = clampf(current_health + health_amount, 0.0, max_health)

	if sanity_amount != 0.0:
		current_sanity = clampf(current_sanity + sanity_amount, 0.0, max_sanity)

	if current_health > 0.0:
		is_downed = false

	if current_health <= 0.0:
		_enter_downed_state()
	elif sanity_amount < 0.0:
		_start_camera_shake(damage_camera_shake_strength * 0.45, damage_camera_shake_time * 0.45)

	_update_status_ui()


func _update_sanity(delta: float) -> void:
	if is_downed:
		return

	var health_ratio := current_health / max_health if max_health > 0.0 else 0.0
	if health_ratio < low_health_sanity_threshold:
		var low_health_pressure := 1.0 - health_ratio / low_health_sanity_threshold
		current_sanity = clampf(
			current_sanity - low_health_sanity_drain_rate * low_health_pressure * delta,
			0.0,
			max_sanity
		)


func _update_camera_feedback(delta: float) -> void:
	var shake_amount := 0.0

	if camera_shake_timer > 0.0:
		camera_shake_timer = maxf(camera_shake_timer - delta, 0.0)
		var shake_fade := camera_shake_timer / maxf(camera_shake_duration, 0.001)
		shake_amount += camera_shake_strength * shake_fade
	else:
		camera_shake_strength = 0.0

	var sanity_ratio := current_sanity / max_sanity if max_sanity > 0.0 else 0.0
	shake_amount += (1.0 - sanity_ratio) * low_sanity_camera_noise

	if shake_amount <= 0.001:
		camera.position = camera_base_position
		return

	camera.position = camera_base_position + Vector3(
		randf_range(-shake_amount, shake_amount),
		randf_range(-shake_amount, shake_amount),
		0.0
	)


func _start_camera_shake(strength: float, duration: float) -> void:
	camera_shake_strength = maxf(camera_shake_strength, strength)
	camera_shake_duration = maxf(camera_shake_duration, duration)
	camera_shake_timer = maxf(camera_shake_timer, duration)


func _show_damage_feedback() -> void:
	var ui := _get_status_ui()
	if ui and ui.has_method("show_damage_feedback"):
		ui.show_damage_feedback()


func _show_enemy_damage_hint(damage: float, sanity_damage: float) -> void:
	if has_shown_enemy_damage_hint or (damage <= 0.0 and sanity_damage <= 0.0):
		return

	has_shown_enemy_damage_hint = true
	var ui := _get_status_ui()
	if ui and ui.has_method("show_memory_fragment"):
		ui.show_memory_fragment(
			"THE WOLF STRIKES TWICE",
			"Its teeth wound the body. Its presence follows you into the mind.\nEvery hit drains both HEALTH and SAN.",
			5.2
		)


func _play_hit_sound() -> void:
	var audio := get_tree().get_first_node_in_group("game_audio")
	if audio and audio.has_method("play_hit"):
		audio.play_hit()


func _update_status_ui() -> void:
	var ui := _get_status_ui()
	if ui and ui.has_method("set_status"):
		ui.set_status(current_health, max_health, current_sanity, max_sanity)


func _get_status_ui() -> Node:
	if is_instance_valid(status_ui):
		return status_ui

	var ui_nodes := get_tree().get_nodes_in_group("player_status_ui")
	if ui_nodes.size() > 0:
		status_ui = ui_nodes[0]

	return status_ui


func _enter_downed_state() -> void:
	is_downed = true
	current_health = 0.0
	hit_stun_timer = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	_start_camera_shake(damage_camera_shake_strength * 1.5, damage_camera_shake_time * 1.4)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _stop_after_down(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)


func reset_model_local_position() -> void:
	idle_model.position = Vector3.ZERO
	run_model.position = Vector3.ZERO
	jump_model.position = Vector3.ZERO
