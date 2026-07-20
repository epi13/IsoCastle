class_name InventorySlot
extends PanelContainer

signal drop_requested(source: Dictionary, destination: Dictionary)
signal split_requested(index: int)
signal activated(source: Dictionary)
signal drag_started(source: Dictionary)

var source: Dictionary = {}
var destination: Dictionary = {}
var stack: Dictionary = {}
var item: Dictionary = {}
var destination_validator: Callable
var default_modulate := Color.WHITE


func configure(source_value: Dictionary, destination_value: Dictionary, stack_value: Dictionary, item_value: Dictionary, validator: Callable) -> void:
	source = source_value.duplicate(true)
	destination = destination_value.duplicate(true)
	stack = stack_value.duplicate(true)
	item = item_value.duplicate(true)
	destination_validator = validator
	custom_minimum_size = Vector2(68, 72)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	tooltip_text = _tooltip()
	_build_contents()


func _build_contents() -> void:
	for child in get_children():
		child.queue_free()
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(38, 38)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not item.is_empty() and ResourceLoader.exists(String(item.get("icon", ""))):
		icon.texture = load(String(item.icon))
	box.add_child(icon)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size.x = 62
	label.add_theme_font_size_override("font_size", 11)
	if stack.is_empty():
		label.text = String(destination.get("label", "Empty"))
	else:
		label.text = "%s%s" % [item.get("name", stack.get("id", "Item")), " ×%d" % int(stack.get("count", 1)) if int(stack.get("count", 1)) > 1 else ""]
	box.add_child(label)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if stack.is_empty() or source.is_empty():
		return null
	var payload := {
		"kind": "inventory_drag",
		"source": source.duplicate(true),
		"stack": stack.duplicate(true),
	}
	if get_viewport().gui_is_dragging():
		set_drag_preview(_make_preview())
	drag_started.emit(source)
	self_modulate = Color(0.65, 0.65, 0.65, 0.65)
	return payload


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or data.get("kind") != "inventory_drag" or not destination_validator.is_valid():
		self_modulate = Color(1.0, 0.48, 0.48, 1.0)
		return false
	var validation: Dictionary = destination_validator.call(data.source, destination)
	self_modulate = Color(0.62, 1.0, 0.68, 1.0) if bool(validation.get("ok", false)) else Color(1.0, 0.48, 0.48, 1.0)
	return bool(validation.get("ok", false))


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	self_modulate = default_modulate
	if data is Dictionary and data.get("kind") == "inventory_drag":
		drop_requested.emit(data.source, destination)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if source.get("kind") == "inventory" and int(stack.get("count", 1)) > 1:
			split_requested.emit(int(source.get("index", -1)))
		accept_event()
	elif event.is_action_pressed("ui_accept") and not event.is_echo() and not stack.is_empty():
		activated.emit(source)
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		self_modulate = default_modulate


func _make_preview() -> Control:
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(180, 54)
	preview.modulate = Color(1.0, 1.0, 1.0, 0.92)
	var row := HBoxContainer.new()
	preview.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(String(item.get("icon", ""))):
		icon.texture = load(String(item.icon))
	row.add_child(icon)
	var label := Label.new()
	label.text = "%s%s" % [item.get("name", stack.get("id", "Item")), " ×%d" % int(stack.get("count", 1)) if int(stack.get("count", 1)) > 1 else ""]
	row.add_child(label)
	return preview


func _tooltip() -> String:
	if stack.is_empty():
		return String(destination.get("label", "Empty slot"))
	return "%s%s\n%s\nWeight %.2f" % [
		item.get("name", stack.get("id", "Item")),
		" ×%d" % int(stack.get("count", 1)) if int(stack.get("count", 1)) > 1 else "",
		item.get("description", ""),
		float(item.get("weight", 0.0)) * int(stack.get("count", 1)),
	]
