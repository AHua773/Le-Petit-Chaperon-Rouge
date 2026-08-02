extends CanvasLayer

const BAG_BUTTON_SIZE := Vector2(118.0, 56.0)
const BAG_EDGE_MARGIN := Vector2(18.0, 16.0)

@onready var bag_button: Button = $Root/BagButton
@onready var overlay: Control = $Root/Overlay
@onready var inventory_window: Control = $Root/Overlay/Window
@onready var close_button: Button = $Root/Overlay/Window/Margin/Layout/Header/CloseButton
@onready var progress_label: Label = $Root/Overlay/Window/Margin/Layout/Header/Progress
@onready var item_list: VBoxContainer = $Root/Overlay/Window/Margin/Layout/Body/Items/Scroll/List
@onready var empty_label: Label = $Root/Overlay/Window/Margin/Layout/Body/Items/Empty
@onready var artifact_label: Label = $Root/Overlay/Window/Margin/Layout/Body/Details/Artifact
@onready var title_label: Label = $Root/Overlay/Window/Margin/Layout/Body/Details/Title
@onready var story_text: RichTextLabel = $Root/Overlay/Window/Margin/Layout/Body/Details/Story

var memory_state: Node
var selected_fragment_id: String = ""
var item_buttons: Dictionary = {}
var inventory_open: bool = false
var _paused_by_inventory: bool = false
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bag_button.pressed.connect(_on_bag_button_pressed)
	close_button.pressed.connect(close_inventory)
	get_viewport().size_changed.connect(_apply_safe_area_layout)
	if DisplayServer.has_signal("orientation_changed"):
		DisplayServer.orientation_changed.connect(_on_orientation_changed)
	overlay.visible = false
	call_deferred("_resolve_memory_state")
	call_deferred("_apply_safe_area_layout")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif inventory_open and event.is_action_pressed("ui_cancel"):
		close_inventory()
		get_viewport().set_input_as_handled()


func toggle_inventory() -> void:
	if inventory_open:
		close_inventory()
	else:
		open_inventory()


func _on_bag_button_pressed() -> void:
	toggle_inventory()


func _on_orientation_changed(_orientation: int) -> void:
	call_deferred("_apply_safe_area_layout")


func open_inventory() -> void:
	if inventory_open:
		return

	_resolve_memory_state()
	inventory_open = true
	overlay.visible = true
	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not get_tree().paused:
		_paused_by_inventory = true
		get_tree().paused = true
	_notify_player_inventory_state(true)
	_refresh_inventory()
	close_button.grab_focus()


func close_inventory() -> void:
	if not inventory_open:
		return

	inventory_open = false
	overlay.visible = false
	if _paused_by_inventory:
		_paused_by_inventory = false
		get_tree().paused = false
	_notify_player_inventory_state(false)
	Input.mouse_mode = _previous_mouse_mode
	bag_button.grab_focus()


func _resolve_memory_state() -> void:
	if is_instance_valid(memory_state):
		return

	memory_state = get_tree().get_first_node_in_group("memory_state")
	if not is_instance_valid(memory_state):
		return
	if memory_state.has_signal("fragment_collected") and not memory_state.fragment_collected.is_connected(_on_fragment_collected):
		memory_state.fragment_collected.connect(_on_fragment_collected)
	_refresh_inventory()


func _on_fragment_collected(fragment_id: String, _collected_count: int) -> void:
	if selected_fragment_id.is_empty():
		selected_fragment_id = fragment_id
	_refresh_inventory()


func _refresh_inventory() -> void:
	if not is_instance_valid(memory_state):
		bag_button.text = "BAG 0/6"
		progress_label.text = "0 / 6 RECOVERED"
		return

	var collected_ids: PackedStringArray = memory_state.get_collected_fragment_ids()
	bag_button.text = "BAG %d/6" % collected_ids.size()
	progress_label.text = "%d / 6 RECOVERED" % collected_ids.size()
	_rebuild_item_list(collected_ids)

	if collected_ids.is_empty():
		selected_fragment_id = ""
		empty_label.visible = true
		_show_empty_details()
		return

	empty_label.visible = false
	if selected_fragment_id.is_empty() or not memory_state.has_fragment(selected_fragment_id):
		selected_fragment_id = collected_ids[0]
	_show_fragment_details(selected_fragment_id)
	_update_button_styles()


func _rebuild_item_list(collected_ids: PackedStringArray) -> void:
	for child in item_list.get_children():
		child.queue_free()
	item_buttons.clear()

	for fragment_id in collected_ids:
		var archive: Dictionary = memory_state.get_fragment_archive(fragment_id)
		var button := Button.new()
		button.name = "Item_%s" % fragment_id
		button.custom_minimum_size = Vector2(0.0, 58.0)
		button.text = "%s   %s" % [archive.get("index", "--"), str(archive.get("name", fragment_id)).to_upper()]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_select_fragment.bind(fragment_id))
		item_list.add_child(button)
		item_buttons[fragment_id] = button


func _select_fragment(fragment_id: String) -> void:
	selected_fragment_id = fragment_id
	_show_fragment_details(fragment_id)
	_update_button_styles()


func _show_fragment_details(fragment_id: String) -> void:
	var archive: Dictionary = memory_state.get_fragment_archive(fragment_id)
	if archive.is_empty():
		_show_empty_details()
		return

	artifact_label.text = str(archive.get("artifact", "Recovered memory")).to_upper()
	title_label.text = str(archive.get("name", "Memory Fragment"))
	story_text.text = (
		"[color=#d9aa48][b]FULL MEMORY[/b][/color]\n%s\n\n"
		+ "[color=#d9aa48][b]WHAT HAPPENED[/b][/color]\n%s\n\n"
		+ "[color=#d9aa48][b]TRUTH REVEALED[/b][/color]\n%s\n\n"
		+ "[color=#d9aa48][b]PLACE IN THE STORY[/b][/color]\n%s"
	) % [
		archive.get("memory", ""),
		archive.get("story", ""),
		archive.get("truth", ""),
		archive.get("connection", ""),
	]
	story_text.scroll_to_line(0)


func _show_empty_details() -> void:
	artifact_label.text = "THE BAG IS STILL LIGHT"
	title_label.text = "No memories recovered"
	story_text.text = "The forest keeps its objects close.\n\nWhen you recover one, its complete memory and the truth hidden inside it will be preserved here."


func _update_button_styles() -> void:
	for fragment_id_value in item_buttons:
		var fragment_id := str(fragment_id_value)
		var button := item_buttons[fragment_id] as Button
		var selected: bool = fragment_id == selected_fragment_id
		button.add_theme_stylebox_override("normal", _make_button_style(selected, false))
		button.add_theme_stylebox_override("hover", _make_button_style(selected, true))
		button.add_theme_stylebox_override("pressed", _make_button_style(true, true))
		button.add_theme_stylebox_override("focus", _make_button_style(true, false))
		button.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55, 1.0) if selected else Color(0.84, 0.82, 0.78, 1.0))
		button.add_theme_font_size_override("font_size", 14)


func _make_button_style(selected: bool, highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.055, 0.045, 0.96) if selected else Color(0.045, 0.04, 0.052, 0.88)
	if highlighted:
		style.bg_color = style.bg_color.lightened(0.08)
	style.border_width_left = 3 if selected else 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.9, 0.56, 0.16, 0.9) if selected else Color(0.22, 0.2, 0.24, 0.9)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	style.content_margin_left = 14.0
	style.content_margin_right = 10.0
	return style


func _notify_player_inventory_state(is_open: bool) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if player and player.has_method("set_inventory_open"):
			player.set_inventory_open(is_open)


func _apply_safe_area_layout() -> void:
	if not is_instance_valid(bag_button) or not is_instance_valid(inventory_window):
		return

	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var safe_insets := _get_ios_safe_insets(viewport_size)
	var right_margin := maxf(BAG_EDGE_MARGIN.x, safe_insets.z + 12.0)
	var top_margin := maxf(BAG_EDGE_MARGIN.y, safe_insets.y + 12.0)

	bag_button.offset_right = -right_margin
	bag_button.offset_left = bag_button.offset_right - BAG_BUTTON_SIZE.x
	bag_button.offset_top = top_margin
	bag_button.offset_bottom = top_margin + BAG_BUTTON_SIZE.y

	var horizontal_margin := viewport_size.x * 0.06
	var vertical_margin := viewport_size.y * 0.07
	inventory_window.anchor_left = 0.0
	inventory_window.anchor_top = 0.0
	inventory_window.anchor_right = 1.0
	inventory_window.anchor_bottom = 1.0
	inventory_window.offset_left = maxf(horizontal_margin, safe_insets.x + 12.0)
	inventory_window.offset_top = maxf(vertical_margin, safe_insets.y + 12.0)
	inventory_window.offset_right = -maxf(horizontal_margin, safe_insets.z + 12.0)
	inventory_window.offset_bottom = -maxf(vertical_margin, safe_insets.w + 12.0)


func _get_ios_safe_insets(viewport_size: Vector2) -> Vector4:
	if not OS.has_feature("ios"):
		return Vector4.ZERO

	var safe_area := DisplayServer.get_display_safe_area()
	var window_size := Vector2(DisplayServer.window_get_size())
	if safe_area.size.x <= 0 or safe_area.size.y <= 0 or window_size.x <= 0.0 or window_size.y <= 0.0:
		return Vector4.ZERO

	var scale := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	var left := float(safe_area.position.x) * scale.x
	var top := float(safe_area.position.y) * scale.y
	var right := float(window_size.x - safe_area.position.x - safe_area.size.x) * scale.x
	var bottom := float(window_size.y - safe_area.position.y - safe_area.size.y) * scale.y
	return Vector4(maxf(left, 0.0), maxf(top, 0.0), maxf(right, 0.0), maxf(bottom, 0.0))
