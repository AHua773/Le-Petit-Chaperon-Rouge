extends CanvasLayer

const SETTINGS_PATH := "user://app_settings.cfg"

@onready var safe_area: Control = %SafeArea
@onready var pause_button: Button = %PauseButton
@onready var overlay: Control = %PauseOverlay
@onready var main_menu: VBoxContainer = %MainMenu
@onready var settings_menu: VBoxContainer = %SettingsMenu
@onready var restart_confirm: VBoxContainer = %RestartConfirm
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var look_slider: HSlider = %LookSlider
@onready var look_value: Label = %LookValue


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")
	pause_button.pressed.connect(open_pause)
	%ResumeButton.pressed.connect(resume_game)
	%SettingsButton.pressed.connect(_open_settings)
	%RestartButton.pressed.connect(_open_restart_confirm)
	%ReturnTitleButton.pressed.connect(_return_to_title)
	%SettingsBackButton.pressed.connect(_show_main_menu)
	%RestartCancelButton.pressed.connect(_show_main_menu)
	%RestartConfirmButton.pressed.connect(_restart_checkpoint)
	volume_slider.value_changed.connect(_on_volume_changed)
	look_slider.value_changed.connect(_on_look_changed)
	get_viewport().size_changed.connect(_apply_safe_area)
	_load_settings()
	_apply_safe_area()
	overlay.visible = false


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _is_game_over_active():
		return
	if overlay.visible:
		if settings_menu.visible or restart_confirm.visible:
			_show_main_menu()
		else:
			resume_game()
	else:
		open_pause()
	get_viewport().set_input_as_handled()


func open_pause() -> void:
	if overlay.visible or _is_game_over_active():
		return
	var inventory := get_tree().current_scene.get_node_or_null("MemoryInventory")
	if inventory and inventory.has_method("close_inventory"):
		inventory.close_inventory()
	get_tree().call_group("game_session", "save_now")
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_button.visible = false
	overlay.visible = true
	_show_main_menu()
	%ResumeButton.grab_focus()


func resume_game() -> void:
	overlay.visible = false
	pause_button.visible = true
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _open_settings() -> void:
	main_menu.visible = false
	restart_confirm.visible = false
	settings_menu.visible = true
	volume_slider.grab_focus()


func _open_restart_confirm() -> void:
	main_menu.visible = false
	settings_menu.visible = false
	restart_confirm.visible = true
	%RestartCancelButton.grab_focus()


func _show_main_menu() -> void:
	main_menu.visible = true
	settings_menu.visible = false
	restart_confirm.visible = false


func _restart_checkpoint() -> void:
	overlay.visible = false
	get_tree().call_group("game_session", "restart_checkpoint")


func _return_to_title() -> void:
	overlay.visible = false
	get_tree().call_group("game_session", "return_to_title")


func _load_settings() -> void:
	var settings := ConfigFile.new()
	var volume := 0.82
	var look := 0.5
	if settings.load(SETTINGS_PATH) == OK:
		volume = clampf(float(settings.get_value("audio", "master_volume", volume)), 0.0, 1.0)
		look = clampf(float(settings.get_value("gameplay", "look_sensitivity", look)), 0.0, 1.0)
	volume_slider.set_value_no_signal(volume * 100.0)
	look_slider.set_value_no_signal(look * 100.0)
	_apply_volume(volume)
	_apply_look(look)


func _on_volume_changed(value: float) -> void:
	var normalized := value / 100.0
	_apply_volume(normalized)
	_save_setting("audio", "master_volume", normalized)


func _on_look_changed(value: float) -> void:
	var normalized := value / 100.0
	_apply_look(normalized)
	_save_setting("gameplay", "look_sensitivity", normalized)


func _apply_volume(value: float) -> void:
	var normalized := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(0, normalized <= 0.001)
	if normalized > 0.001:
		AudioServer.set_bus_volume_db(0, linear_to_db(normalized))
	volume_value.text = "%d%%" % roundi(normalized * 100.0)


func _apply_look(value: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_look_sensitivity"):
		player.apply_look_sensitivity(value)
	look_value.text = "%d%%" % roundi(value * 100.0)


func _save_setting(section: String, key: String, value: Variant) -> void:
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)
	settings.set_value(section, key, value)
	settings.save(SETTINGS_PATH)


func _is_game_over_active() -> bool:
	var ui_nodes := get_tree().get_nodes_in_group("player_status_ui")
	if ui_nodes.is_empty():
		return false
	var game_over := ui_nodes[0].get_node_or_null("GameOverOverlay") as Control
	return game_over != null and game_over.visible


func _apply_safe_area() -> void:
	if not is_instance_valid(safe_area):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var window_size := Vector2(DisplayServer.window_get_size())
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or window_size.x <= 0.0 or window_size.y <= 0.0:
		return
	var safe_rect := DisplayServer.get_display_safe_area()
	var scale := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	safe_area.offset_left = maxf(float(safe_rect.position.x) * scale.x, 12.0)
	safe_area.offset_top = maxf(float(safe_rect.position.y) * scale.y, 12.0)
	safe_area.offset_right = -maxf(float(window_size.x - safe_rect.end.x) * scale.x, 12.0)
	safe_area.offset_bottom = -maxf(float(window_size.y - safe_rect.end.y) * scale.y, 12.0)
