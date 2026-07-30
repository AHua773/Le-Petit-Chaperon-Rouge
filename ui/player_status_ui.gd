extends CanvasLayer

@onready var health_bar: ProgressBar = $Root/Meters/HealthBar
@onready var sanity_bar: ProgressBar = $Root/Meters/SanityBar
@onready var health_label: Label = $Root/Meters/HealthLabel
@onready var sanity_label: Label = $Root/Meters/SanityLabel
@onready var blur_overlay: ColorRect = $Root/BlurOverlay
@onready var damage_overlay: ColorRect = $Root/DamageOverlay
@onready var sanity_overlay: ColorRect = $Root/SanityOverlay
@onready var blur_material: ShaderMaterial = $Root/BlurOverlay.material as ShaderMaterial
@onready var memory_panel: Control = $Root/MemoryPanel
@onready var memory_title_label: Label = $Root/MemoryPanel/Margin/Text/Title
@onready var memory_line_label: Label = $Root/MemoryPanel/Margin/Text/Line
@onready var objective_panel: Control = $Root/ObjectivePanel
@onready var objective_title_label: Label = $Root/ObjectivePanel/Margin/Text/Title
@onready var objective_line_label: Label = $Root/ObjectivePanel/Margin/Text/Line
@onready var game_over_overlay: Control = $GameOverOverlay
@onready var retry_button: Button = $GameOverOverlay/Center/Panel/Margin/Content/Buttons/RetryButton
@onready var menu_button: Button = $GameOverOverlay/Center/Panel/Margin/Content/Buttons/MenuButton

var damage_flash: float = 0.0
var low_health_pressure: float = 0.0
var low_sanity_pressure: float = 0.0
var memory_message_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_nodes()
	blur_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sanity_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _resolve_memory_nodes():
		memory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		memory_panel.visible = false
	if _resolve_objective_nodes():
		objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		objective_panel.visible = true
	game_over_overlay.visible = false
	retry_button.pressed.connect(_restart_game)
	menu_button.pressed.connect(_return_to_menu)
	_update_overlays()


func _process(delta: float) -> void:
	damage_flash = maxf(damage_flash - delta * 2.8, 0.0)
	if memory_message_timer > 0.0:
		memory_message_timer = maxf(memory_message_timer - delta, 0.0)
		_update_memory_message()
	_update_overlays()


func set_status(health: float, max_health: float, sanity: float, max_sanity: float) -> void:
	if not _resolve_nodes():
		call_deferred("set_status", health, max_health, sanity, max_sanity)
		return

	health_bar.max_value = max_health
	health_bar.value = health
	sanity_bar.max_value = max_sanity
	sanity_bar.value = sanity

	health_label.text = "HEALTH %d / %d" % [roundi(health), roundi(max_health)]
	sanity_label.text = "SAN %d / %d" % [roundi(sanity), roundi(max_sanity)]

	var health_ratio := health / max_health if max_health > 0.0 else 0.0
	var sanity_ratio := sanity / max_sanity if max_sanity > 0.0 else 0.0
	low_health_pressure = clampf(1.0 - health_ratio, 0.0, 1.0)
	low_sanity_pressure = clampf(1.0 - sanity_ratio, 0.0, 1.0)
	_update_overlays()


func show_damage_feedback() -> void:
	if not _resolve_nodes():
		call_deferred("show_damage_feedback")
		return

	damage_flash = 1.0
	_update_overlays()


func show_memory_fragment(title: String, line: String, duration: float = 4.0) -> void:
	if not _resolve_memory_nodes():
		call_deferred("show_memory_fragment", title, line, duration)
		return

	memory_title_label.text = title
	memory_line_label.text = line
	memory_message_timer = maxf(duration, 1.0)
	_update_memory_message()


func set_objective(title: String, line: String) -> void:
	if not _resolve_objective_nodes():
		call_deferred("set_objective", title, line)
		return

	objective_title_label.text = title
	objective_line_label.text = line
	objective_panel.visible = true


func show_game_over() -> void:
	if game_over_overlay.visible:
		return

	memory_panel.visible = false
	game_over_overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	retry_button.grab_focus()


func _restart_game() -> void:
	game_over_overlay.visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_menu() -> void:
	game_over_overlay.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/app_launcher.tscn")


func _update_overlays() -> void:
	if not _resolve_nodes():
		return

	var blur_strength := low_sanity_pressure * 5.5 + low_health_pressure * 2.0
	if blur_material:
		blur_material.set_shader_parameter("blur_strength", blur_strength)

	var damage_alpha := damage_flash * 0.46 + low_health_pressure * 0.16
	damage_overlay.color = Color(0.72, 0.02, 0.01, clampf(damage_alpha, 0.0, 0.62))

	var sanity_alpha := low_sanity_pressure * 0.36 + low_health_pressure * 0.12
	sanity_overlay.color = Color(0.02, 0.0, 0.045, clampf(sanity_alpha, 0.0, 0.5))


func _update_memory_message() -> void:
	if not _resolve_memory_nodes():
		return

	memory_panel.visible = memory_message_timer > 0.0
	if not memory_panel.visible:
		return

	var fade_alpha := clampf(memory_message_timer / 0.35, 0.0, 1.0)
	memory_panel.modulate.a = fade_alpha


func _resolve_nodes() -> bool:
	if health_bar and sanity_bar and health_label and sanity_label and blur_overlay and damage_overlay and sanity_overlay:
		return true

	health_bar = get_node_or_null("Root/Meters/HealthBar") as ProgressBar
	sanity_bar = get_node_or_null("Root/Meters/SanityBar") as ProgressBar
	health_label = get_node_or_null("Root/Meters/HealthLabel") as Label
	sanity_label = get_node_or_null("Root/Meters/SanityLabel") as Label
	blur_overlay = get_node_or_null("Root/BlurOverlay") as ColorRect
	damage_overlay = get_node_or_null("Root/DamageOverlay") as ColorRect
	sanity_overlay = get_node_or_null("Root/SanityOverlay") as ColorRect

	if blur_overlay:
		blur_material = blur_overlay.material as ShaderMaterial

	return health_bar != null and sanity_bar != null and health_label != null and sanity_label != null and blur_overlay != null and damage_overlay != null and sanity_overlay != null


func _resolve_memory_nodes() -> bool:
	if memory_panel and memory_title_label and memory_line_label:
		return true

	memory_panel = get_node_or_null("Root/MemoryPanel") as Control
	memory_title_label = get_node_or_null("Root/MemoryPanel/Margin/Text/Title") as Label
	memory_line_label = get_node_or_null("Root/MemoryPanel/Margin/Text/Line") as Label

	return memory_panel != null and memory_title_label != null and memory_line_label != null


func _resolve_objective_nodes() -> bool:
	if objective_panel and objective_title_label and objective_line_label:
		return true

	objective_panel = get_node_or_null("Root/ObjectivePanel") as Control
	objective_title_label = get_node_or_null("Root/ObjectivePanel/Margin/Text/Title") as Label
	objective_line_label = get_node_or_null("Root/ObjectivePanel/Margin/Text/Line") as Label

	return objective_panel != null and objective_title_label != null and objective_line_label != null
