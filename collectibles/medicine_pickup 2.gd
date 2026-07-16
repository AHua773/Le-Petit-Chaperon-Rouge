extends Area3D

enum MedicineType {
	MOONCAP,
	BLOODCAP
}

@export_enum("Mooncap", "Bloodcap") var medicine_type: int = MedicineType.MOONCAP
@export var use_type_defaults: bool = true
@export var health_amount: float = 18.0
@export var sanity_amount: float = 12.0
@export var bob_speed: float = 2.6
@export var bob_height: float = 0.08
@export var spin_speed: float = 1.35
@export var pulse_speed: float = 3.2

@onready var visual: Node3D = $Visual
@onready var stem: MeshInstance3D = $Visual/Stem
@onready var cap: MeshInstance3D = $Visual/Cap
@onready var spots: MeshInstance3D = $Visual/Spots
@onready var glow_ring: MeshInstance3D = $Visual/GlowRing
@onready var glow_light: OmniLight3D = $GlowLight

var _base_visual_y: float = 0.0
var _base_light_energy: float = 1.0
var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_base_visual_y = visual.position.y
	_base_light_energy = glow_light.light_energy

	if use_type_defaults:
		_apply_type_defaults()

	_apply_visual_style()


func _process(delta: float) -> void:
	_time += delta
	visual.position.y = _base_visual_y + sin(_time * bob_speed) * bob_height
	visual.rotation.y += spin_speed * delta

	var pulse := 0.75 + (sin(_time * pulse_speed) + 1.0) * 0.25
	glow_light.light_energy = _base_light_energy * pulse


func _apply_type_defaults() -> void:
	match medicine_type:
		MedicineType.BLOODCAP:
			health_amount = 45.0
			sanity_amount = -30.0
		_:
			health_amount = 18.0
			sanity_amount = 12.0


func _apply_visual_style() -> void:
	var stem_color := Color(0.62, 0.51, 0.39, 1.0)
	var cap_color := Color(0.2, 0.82, 0.72, 1.0)
	var spot_color := Color(0.87, 1.0, 0.86, 1.0)
	var glow_color := Color(0.16, 0.88, 1.0, 1.0)
	var cap_energy := 1.3
	var visual_scale := Vector3.ONE

	if medicine_type == MedicineType.BLOODCAP:
		stem_color = Color(0.55, 0.38, 0.34, 1.0)
		cap_color = Color(0.78, 0.02, 0.07, 1.0)
		spot_color = Color(1.0, 0.82, 0.78, 1.0)
		glow_color = Color(1.0, 0.04, 0.12, 1.0)
		cap_energy = 1.8
		visual_scale = Vector3(1.18, 1.18, 1.18)

	visual.scale = visual_scale
	stem.set_surface_override_material(0, _make_material(stem_color, stem_color, 0.15))
	cap.set_surface_override_material(0, _make_material(cap_color, glow_color, cap_energy))
	spots.set_surface_override_material(0, _make_material(spot_color, glow_color, cap_energy * 0.7))
	glow_ring.set_surface_override_material(0, _make_material(glow_color, glow_color, cap_energy))
	glow_light.light_color = glow_color


func _make_material(albedo: Color, emission: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.62
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = emission_energy
	return material


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return

	_collected = true

	if body.has_method("apply_medicine"):
		body.apply_medicine(health_amount, sanity_amount)
	else:
		if health_amount > 0.0 and body.has_method("heal"):
			body.heal(health_amount)
		if sanity_amount > 0.0 and body.has_method("restore_sanity"):
			body.restore_sanity(sanity_amount)

	queue_free()
