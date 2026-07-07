extends CanvasLayer

@onready var health_bar: ProgressBar = $Root/Meters/HealthBar
@onready var sanity_bar: ProgressBar = $Root/Meters/SanityBar
@onready var health_label: Label = $Root/Meters/HealthLabel
@onready var sanity_label: Label = $Root/Meters/SanityLabel
@onready var blur_overlay: ColorRect = $Root/BlurOverlay
@onready var damage_overlay: ColorRect = $Root/DamageOverlay
@onready var sanity_overlay: ColorRect = $Root/SanityOverlay
@onready var blur_material: ShaderMaterial = $Root/BlurOverlay.material as ShaderMaterial

var damage_flash: float = 0.0
var low_health_pressure: float = 0.0
var low_sanity_pressure: float = 0.0


func _ready() -> void:
	_resolve_nodes()
	blur_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sanity_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_overlays()


func _process(delta: float) -> void:
	damage_flash = maxf(damage_flash - delta * 2.8, 0.0)
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
