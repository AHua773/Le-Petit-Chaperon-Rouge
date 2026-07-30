extends Control

const GAME_SCENE_PATH := "res://main.tscn"
const SETTINGS_PATH := "user://app_settings.cfg"
const MIN_LOADING_SECONDS := 1.4

@onready var safe_area: Control = %SafeArea
@onready var menu_panel: Control = %MenuPanel
@onready var loading_view: Control = %LoadingView
@onready var modal_overlay: Control = %ModalOverlay
@onready var modal_title: Label = %ModalTitle
@onready var how_to_play_text: RichTextLabel = %HowToPlayText
@onready var credits_text: RichTextLabel = %CreditsText
@onready var settings_box: VBoxContainer = %SettingsBox
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var master_volume_value: Label = %MasterVolumeValue
@onready var reduce_motion_check: CheckButton = %ReduceMotionCheck
@onready var loading_icon: TextureRect = %LoadingIcon
@onready var loading_stage: Label = %LoadingStage
@onready var loading_detail: Label = %LoadingDetail
@onready var loading_progress: ProgressBar = %LoadingProgress
@onready var loading_percent: Label = %LoadingPercent
@onready var loading_return_button: Button = %LoadingReturnButton

var _load_started := false
var _load_finished := false
var _load_failed := false
var _load_elapsed := 0.0
var _displayed_progress := 0.0
var _loaded_scene: PackedScene
var _reduce_motion := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%StartButton.pressed.connect(_start_game)
	%HowToPlayButton.pressed.connect(_open_how_to_play)
	%SettingsButton.pressed.connect(_open_settings)
	%CreditsButton.pressed.connect(_open_credits)
	%ModalBackButton.pressed.connect(_close_modal)
	loading_return_button.pressed.connect(_return_to_menu_after_error)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	reduce_motion_check.toggled.connect(_on_reduce_motion_toggled)
	get_viewport().size_changed.connect(_apply_safe_area)

	_load_preferences()
	_apply_safe_area()
	_show_menu_immediately()
	%StartButton.grab_focus()
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and modal_overlay.visible:
		_close_modal()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _load_started:
		return

	_load_elapsed += delta
	if not _reduce_motion:
		loading_icon.rotation += delta * 0.8

	var raw_progress := 1.0 if _load_finished else 0.0
	if not _load_finished:
		var progress_values: Array = []
		var status := ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH, progress_values)
		if not progress_values.is_empty():
			raw_progress = clampf(float(progress_values[0]), 0.0, 1.0)

		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				_update_loading_target(raw_progress)
			ResourceLoader.THREAD_LOAD_LOADED:
				_loaded_scene = ResourceLoader.load_threaded_get(GAME_SCENE_PATH) as PackedScene
				_load_finished = _loaded_scene != null
				if not _load_finished:
					_show_loading_error()
					return
				raw_progress = 1.0
				_update_loading_target(raw_progress)
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_show_loading_error()
				return

	var minimum_progress := clampf(_load_elapsed / MIN_LOADING_SECONDS, 0.0, 1.0)
	var visual_target := minf(maxf(raw_progress, minimum_progress), 0.96)
	if _load_finished:
		visual_target = minimum_progress
	_displayed_progress = move_toward(_displayed_progress, visual_target, delta * 0.9)
	_update_loading_ui(_displayed_progress)

	if _load_finished and _load_elapsed >= MIN_LOADING_SECONDS and _displayed_progress >= 0.995:
		set_process(false)
		get_tree().change_scene_to_packed(_loaded_scene)


func _start_game() -> void:
	if _load_started:
		return

	_close_modal()
	_load_started = true
	_load_finished = false
	_load_failed = false
	_load_elapsed = 0.0
	_displayed_progress = 0.0
	_loaded_scene = null
	menu_panel.visible = false
	loading_view.visible = true
	loading_return_button.visible = false
	loading_icon.rotation = 0.0
	_update_loading_ui(0.0)

	var error := ResourceLoader.load_threaded_request(GAME_SCENE_PATH, "PackedScene", true)
	if error != OK:
		_show_loading_error()
		return
	set_process(true)


func _update_loading_target(progress: float) -> void:
	if progress < 0.22:
		loading_stage.text = "PREPARING THE FOREST"
		loading_detail.text = "Gathering the road, the trees, and what waits between them."
	elif progress < 0.52:
		loading_stage.text = "REMEMBERING THE PATH"
		loading_detail.text = "Six fragments are waiting where their stories belong."
	elif progress < 0.82:
		loading_stage.text = "WAKING THE SHADOWS"
		loading_detail.text = "Watch the warning. Move sideways when the wolf lunges."
	else:
		loading_stage.text = "FOLLOWING THE RED THREAD"
		loading_detail.text = "The safe-looking door is not the only way forward."


func _update_loading_ui(progress: float) -> void:
	var percentage := clampi(roundi(progress * 100.0), 0, 100)
	loading_progress.value = percentage
	loading_percent.text = "%d%%" % percentage
	if percentage >= 100:
		loading_stage.text = "THE FOREST REMEMBERS YOU"
		loading_detail.text = "Entering the road..."


func _show_loading_error() -> void:
	if _load_failed:
		return
	_load_failed = true
	_load_started = false
	set_process(false)
	loading_stage.text = "THE ROAD COULD NOT BE OPENED"
	loading_detail.text = "The game scene could not be loaded. Return and try again."
	loading_return_button.visible = true
	loading_return_button.grab_focus()


func _return_to_menu_after_error() -> void:
	loading_view.visible = false
	menu_panel.visible = true
	loading_return_button.visible = false
	%StartButton.grab_focus()


func _open_how_to_play() -> void:
	modal_title.text = "HOW TO PLAY"
	how_to_play_text.visible = true
	settings_box.visible = false
	credits_text.visible = false
	_show_modal()


func _open_settings() -> void:
	modal_title.text = "SETTINGS"
	how_to_play_text.visible = false
	settings_box.visible = true
	credits_text.visible = false
	_show_modal()
	master_volume_slider.grab_focus()


func _open_credits() -> void:
	modal_title.text = "CREDITS"
	how_to_play_text.visible = false
	settings_box.visible = false
	credits_text.visible = true
	_show_modal()


func _show_modal() -> void:
	modal_overlay.visible = true
	%ModalBackButton.grab_focus()


func _close_modal() -> void:
	modal_overlay.visible = false
	if menu_panel.visible:
		%StartButton.grab_focus()


func _show_menu_immediately() -> void:
	menu_panel.visible = true
	loading_view.visible = false
	modal_overlay.visible = false


func _load_preferences() -> void:
	var settings := ConfigFile.new()
	var volume := 0.82
	if settings.load(SETTINGS_PATH) == OK:
		volume = clampf(float(settings.get_value("audio", "master_volume", volume)), 0.0, 1.0)
		_reduce_motion = bool(settings.get_value("accessibility", "reduce_ui_motion", false))
	master_volume_slider.set_value_no_signal(volume * 100.0)
	reduce_motion_check.set_pressed_no_signal(_reduce_motion)
	_apply_master_volume(volume)


func _save_preferences() -> void:
	var settings := ConfigFile.new()
	settings.set_value("audio", "master_volume", master_volume_slider.value / 100.0)
	settings.set_value("accessibility", "reduce_ui_motion", _reduce_motion)
	settings.save(SETTINGS_PATH)


func _on_master_volume_changed(value: float) -> void:
	_apply_master_volume(value / 100.0)
	_save_preferences()


func _apply_master_volume(linear_volume: float) -> void:
	var clamped_volume := clampf(linear_volume, 0.0, 1.0)
	AudioServer.set_bus_mute(0, clamped_volume <= 0.001)
	if clamped_volume > 0.001:
		AudioServer.set_bus_volume_db(0, linear_to_db(clamped_volume))
	master_volume_value.text = "%d%%" % roundi(clamped_volume * 100.0)


func _on_reduce_motion_toggled(enabled: bool) -> void:
	_reduce_motion = enabled
	_save_preferences()


func _apply_safe_area() -> void:
	if not is_instance_valid(safe_area):
		return

	var viewport_size := get_viewport_rect().size
	var window_size := Vector2(DisplayServer.window_get_size())
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or window_size.x <= 0.0 or window_size.y <= 0.0:
		return

	var safe_rect := DisplayServer.get_display_safe_area()
	var scale := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	var left := float(safe_rect.position.x) * scale.x
	var top := float(safe_rect.position.y) * scale.y
	var right := float(window_size.x - safe_rect.end.x) * scale.x
	var bottom := float(window_size.y - safe_rect.end.y) * scale.y

	safe_area.offset_left = maxf(left, 18.0)
	safe_area.offset_top = maxf(top, 12.0)
	safe_area.offset_right = -maxf(right, 18.0)
	safe_area.offset_bottom = -maxf(bottom, 12.0)
