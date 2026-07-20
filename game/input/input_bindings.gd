class_name InputBindings
extends RefCounted

const FORMAT_VERSION := 2
const AXIS_CAPTURE_THRESHOLD := 0.72

var current: Dictionary = {}


func _init(saved: Dictionary = {}, version: int = FORMAT_VERSION) -> void:
	current = migrate(saved, version)


func reset_all() -> Dictionary:
	current = InputDefaults.bindings().duplicate(true)
	apply_to_input_map()
	return {"ok": true, "changed": true}


func reset_action(action: String) -> Dictionary:
	if not InputDefaults.ACTION_ORDER.has(action):
		return {"ok": false, "reason": "Unknown action."}
	current[action] = InputDefaults.bindings()[action].duplicate(true)
	apply_to_input_map()
	return {"ok": true, "changed": true}


func assign_event(action: String, event: InputEvent, replace_index: int = -1, resolve_conflict: bool = false, browser_safe: bool = false) -> Dictionary:
	var serialized := event_to_data(event)
	if serialized.is_empty():
		return {"ok": false, "reason": "Unsupported or incomplete input event."}
	return assign_data(action, serialized, replace_index, resolve_conflict, browser_safe)


func assign_data(action: String, data: Dictionary, replace_index: int = -1, resolve_conflict: bool = false, browser_safe: bool = false) -> Dictionary:
	if not InputDefaults.ACTION_ORDER.has(action):
		return {"ok": false, "reason": "Unknown action."}
	if not is_valid_data(data):
		return {"ok": false, "reason": "Unsupported binding data."}
	if browser_safe and is_browser_reserved(data):
		return {"ok": false, "reason": "That shortcut is reserved by browsers.", "browser_reserved": true}
	var candidate := canonical(data)
	for index in range(current[action].size()):
		if index != replace_index and canonical(current[action][index]) == candidate:
			return {"ok": true, "changed": false, "reason": "", "duplicate": true}
	var conflicts := find_conflicts(action, data)
	if not conflicts.is_empty() and not resolve_conflict:
		return {
			"ok": false, "reason": "Binding is already assigned.",
			"conflict_action": conflicts[0].action, "conflict_index": conflicts[0].index,
		}
	var updated := current.duplicate(true)
	if resolve_conflict:
		for conflict: Dictionary in conflicts:
			var conflict_events: Array = updated[conflict.action]
			if conflict.action == "ui_cancel" and conflict_events.size() <= 1:
				return {"ok": false, "reason": "Pause / cancel must retain at least one binding.", "protected_cancel": true}
			conflict_events.remove_at(int(conflict.index))
	var action_events: Array = updated[action]
	if replace_index >= 0:
		if replace_index >= action_events.size():
			return {"ok": false, "reason": "Binding no longer exists."}
		action_events[replace_index] = normalized(data)
	else:
		action_events.append(normalized(data))
	if action == "ui_cancel" and action_events.is_empty():
		return {"ok": false, "reason": "Pause / cancel must retain at least one binding.", "protected_cancel": true}
	current = updated
	apply_to_input_map()
	return {"ok": true, "changed": true, "reason": ""}


func clear_binding(action: String, index: int) -> Dictionary:
	if not current.has(action) or index < 0 or index >= current[action].size():
		return {"ok": false, "reason": "Binding no longer exists."}
	if action == "ui_cancel" and current[action].size() <= 1:
		return {"ok": false, "reason": "Pause / cancel must retain at least one binding.", "protected_cancel": true}
	var updated := current.duplicate(true)
	updated[action].remove_at(index)
	current = updated
	apply_to_input_map()
	return {"ok": true, "changed": true, "reason": ""}


func find_conflicts(action: String, data: Dictionary) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	var candidate := canonical(data)
	for other_action: String in InputDefaults.ACTION_ORDER:
		if other_action == action:
			continue
		for index in range(current.get(other_action, []).size()):
			if canonical(current[other_action][index]) == candidate:
				matches.append({"action": other_action, "index": index})
	return matches


func apply_to_input_map() -> void:
	for action: String in InputDefaults.ACTION_ORDER:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.35)
		InputMap.action_erase_events(action)
		for data: Dictionary in current.get(action, []):
			var event := data_to_event(data)
			if event != null:
				InputMap.action_add_event(action, event)


func binding_text(action: String) -> String:
	var labels := PackedStringArray()
	for data: Dictionary in current.get(action, []):
		labels.append(display_name(data))
	return ", ".join(labels) if not labels.is_empty() else "Unbound"


func serialized() -> Dictionary:
	return current.duplicate(true)


static func migrate(saved: Dictionary, version: int) -> Dictionary:
	var result := InputDefaults.bindings().duplicate(true)
	var source := saved.duplicate(true)
	if version <= 1:
		for old_action: String in InputDefaults.RENAMED_ACTIONS:
			if source.has(old_action) and not source.has(InputDefaults.RENAMED_ACTIONS[old_action]):
				source[InputDefaults.RENAMED_ACTIONS[old_action]] = source[old_action]
	for action: String in source:
		if not InputDefaults.ACTION_ORDER.has(action) or not source[action] is Array:
			continue
		var valid_events: Array[Dictionary] = []
		for data: Variant in source[action]:
			if data is Dictionary and is_valid_data(data):
				valid_events.append(normalized(data))
		if not valid_events.is_empty() or action != "ui_cancel":
			result[action] = valid_events
	if result.ui_cancel.is_empty():
		result.ui_cancel = InputDefaults.bindings().ui_cancel.duplicate(true)
	return result


static func event_to_data(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key", "physical_keycode": int(event.physical_keycode),
			"shift": event.shift_pressed, "ctrl": event.ctrl_pressed,
			"alt": event.alt_pressed, "meta": event.meta_pressed,
		} if event.physical_keycode != 0 else {}
	if event is InputEventMouseButton:
		return {"type": "mouse_button", "button_index": int(event.button_index)} if event.button_index > 0 else {}
	if event is InputEventJoypadButton:
		return {"type": "joypad_button", "button_index": int(event.button_index)}
	if event is InputEventJoypadMotion and absf(event.axis_value) >= AXIS_CAPTURE_THRESHOLD:
		return {"type": "joypad_motion", "axis": int(event.axis), "axis_value": signf(event.axis_value), "deadzone": 0.55}
	return {}


static func data_to_event(data: Dictionary) -> InputEvent:
	match data.get("type", ""):
		"key":
			var key := InputEventKey.new()
			key.physical_keycode = int(data.get("physical_keycode", 0)) as Key
			key.shift_pressed = bool(data.get("shift", false))
			key.ctrl_pressed = bool(data.get("ctrl", false))
			key.alt_pressed = bool(data.get("alt", false))
			key.meta_pressed = bool(data.get("meta", false))
			return key
		"mouse_button":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = int(data.get("button_index", 0)) as MouseButton
			return mouse
		"joypad_button":
			var button := InputEventJoypadButton.new()
			button.button_index = int(data.get("button_index", 0)) as JoyButton
			return button
		"joypad_motion":
			var motion := InputEventJoypadMotion.new()
			motion.axis = int(data.get("axis", 0)) as JoyAxis
			motion.axis_value = float(data.get("axis_value", 0.0))
			return motion
	return null


static func display_name(data: Dictionary) -> String:
	match data.get("type", ""):
		"key":
			var pieces := PackedStringArray()
			if bool(data.get("ctrl", false)): pieces.append("Ctrl")
			if bool(data.get("alt", false)): pieces.append("Alt")
			if bool(data.get("shift", false)): pieces.append("Shift")
			if bool(data.get("meta", false)): pieces.append("Meta")
			pieces.append(OS.get_keycode_string(int(data.get("physical_keycode", 0)) as Key))
			return "+".join(pieces) + " (physical)"
		"mouse_button":
			var mouse_names := {1: "Mouse Left", 2: "Mouse Right", 3: "Mouse Middle", 4: "Wheel Up", 5: "Wheel Down"}
			return mouse_names.get(int(data.get("button_index", 0)), "Mouse %d" % int(data.get("button_index", 0)))
		"joypad_button":
			return "Controller Button %d" % int(data.get("button_index", 0))
		"joypad_motion":
			return "Controller Axis %d %s" % [int(data.get("axis", 0)), "+" if float(data.get("axis_value", 0.0)) > 0.0 else "−"]
	return "Unknown"


static func is_browser_reserved(data: Dictionary) -> bool:
	if data.get("type") != "key":
		return false
	var code := int(data.get("physical_keycode", 0))
	if code in [KEY_F5, KEY_F11, KEY_F12]:
		return true
	return bool(data.get("ctrl", false)) and code in [KEY_R, KEY_W, KEY_L]


static func is_valid_data(data: Dictionary) -> bool:
	match data.get("type", ""):
		"key": return int(data.get("physical_keycode", 0)) > 0
		"mouse_button": return int(data.get("button_index", 0)) > 0
		"joypad_button": return int(data.get("button_index", -1)) >= 0
		"joypad_motion": return int(data.get("axis", -1)) >= 0 and absf(float(data.get("axis_value", 0.0))) == 1.0
	return false


static func normalized(data: Dictionary) -> Dictionary:
	var event := event_to_data(data_to_event(data))
	if data.get("type") == "joypad_motion":
		event["deadzone"] = clampf(float(data.get("deadzone", 0.55)), 0.25, 0.9)
	return event


static func canonical(data: Dictionary) -> String:
	var clean := normalized(data)
	clean.erase("deadzone")
	return JSON.stringify(clean, "", true)
