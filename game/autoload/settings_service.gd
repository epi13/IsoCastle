extends Node

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_VERSION := 2
const DEFAULTS: Dictionary = {
	"master_volume": 0.85,
	"music_volume": 0.72,
	"ambience_volume": 0.68,
	"effects_volume": 0.82,
	"voice_volume": 0.9,
	"fullscreen": false,
	"ui_scale": 1.0,
	"text_scale": 1.0,
	"text_speed": 1.0,
	"animation_speed": 1.0,
	"high_contrast": false,
	"reduced_motion": false,
	"reduced_flashing": false,
	"screen_shake": 0.65,
	"highlight_interactables": true,
	"floating_feedback": true,
	"hold_to_confirm": false,
	"tutorial_enabled": true,
}

var values: Dictionary = DEFAULTS.duplicate(true)
var input_bindings := InputBindings.new()
var last_persistence_error := ""


func _ready() -> void:
	load_settings()
	apply()


func load_settings(path: String = SETTINGS_PATH) -> Error:
	values = DEFAULTS.duplicate(true)
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK:
		input_bindings = InputBindings.new()
		input_bindings.apply_to_input_map()
		return load_error
	for key: String in DEFAULTS:
		values[key] = config.get_value("settings", key, DEFAULTS[key])
	var input_version := int(config.get_value("input", "format_version", 1))
	var stored: Variant = config.get_value("input", "bindings", {})
	if stored is String:
		var parsed: Variant = JSON.parse_string(stored)
		stored = parsed if parsed is Dictionary else {}
	input_bindings = InputBindings.new(stored if stored is Dictionary else {}, input_version)
	input_bindings.apply_to_input_map()
	return OK


func save_settings(path: String = SETTINGS_PATH) -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "settings_version", SETTINGS_VERSION)
	for key: String in values:
		config.set_value("settings", key, values[key])
	config.set_value("input", "format_version", InputBindings.FORMAT_VERSION)
	config.set_value("input", "bindings", JSON.stringify(input_bindings.serialized(), "", true))
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
	var error := config.save(temp_path)
	if error != OK:
		last_persistence_error = "Could not write temporary settings: %s" % error_string(error)
		return error
	var validation := ConfigFile.new()
	error = validation.load(temp_path)
	if error != OK:
		last_persistence_error = "Temporary settings could not be verified: %s" % error_string(error)
		return error
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_backup)
		error = DirAccess.rename_absolute(absolute_path, absolute_backup)
		if error != OK:
			last_persistence_error = "Could not preserve previous settings: %s" % error_string(error)
			return error
	error = DirAccess.rename_absolute(absolute_temp, absolute_path)
	last_persistence_error = "" if error == OK else "Could not replace settings: %s" % error_string(error)
	if error == OK and OS.has_feature("web"):
		var bridge := get_node_or_null("/root/WebBridge")
		if bridge != null:
			bridge.set_value("storage_persistent", OS.is_userfs_persistent())
		JavaScriptBridge.force_fs_sync()
	if is_inside_tree():
		var bridge := get_node_or_null("/root/WebBridge")
		if bridge != null:
			bridge.set_value("settings_save_ok", error == OK)
	return error


func set_value(key: String, value: Variant) -> void:
	if DEFAULTS.has(key):
		values[key] = value
		apply()
		if key == "fullscreen" and OS.has_feature("web"):
			_apply_fullscreen(bool(value))
		if is_inside_tree():
			var bridge := get_node_or_null("/root/WebBridge")
			if bridge != null:
				bridge.set_value("setting_%s" % key, value)


func get_value(key: String) -> Variant:
	return values.get(key, DEFAULTS.get(key))


func action_ids() -> Array[String]:
	return InputDefaults.ACTION_ORDER.duplicate()


func action_label(action: String) -> String:
	return String(InputDefaults.LABELS.get(action, action.replace("_", " ").capitalize()))


func binding_text(action: String) -> String:
	return input_bindings.binding_text(action)


func primary_binding_text(action: String) -> String:
	var action_bindings: Array = input_bindings.current.get(action, [])
	return InputBindings.display_name(action_bindings[0]).replace(" (physical)", "") if not action_bindings.is_empty() else "Unbound"


func bindings_for(action: String) -> Array:
	return input_bindings.current.get(action, []).duplicate(true)


func assign_binding(action: String, event: InputEvent, replace_index: int = -1, resolve_conflict: bool = false) -> Dictionary:
	return input_bindings.assign_event(action, event, replace_index, resolve_conflict, OS.has_feature("web"))


func assign_binding_data(action: String, data: Dictionary, replace_index: int = -1, resolve_conflict: bool = false) -> Dictionary:
	return input_bindings.assign_data(action, data, replace_index, resolve_conflict, OS.has_feature("web"))


func clear_binding(action: String, index: int) -> Dictionary:
	return input_bindings.clear_binding(action, index)


func reset_action(action: String) -> Dictionary:
	return input_bindings.reset_action(action)


func reset_all_bindings() -> Dictionary:
	return input_bindings.reset_all()


func apply() -> void:
	var buses := {
		"Master": "master_volume",
		"Music": "music_volume",
		"Ambience": "ambience_volume",
		"Effects": "effects_volume",
		"Voice": "voice_volume",
	}
	for bus_name: String in buses:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			var linear: float = clampf(float(values[buses[bus_name]]), 0.0, 1.0)
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	if is_inside_tree():
		var scale: float = float(values.ui_scale)
		get_tree().root.content_scale_factor = scale
	if not OS.has_feature("web"):
		_apply_fullscreen(bool(values.fullscreen))


func _apply_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
