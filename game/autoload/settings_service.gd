extends Node

const SETTINGS_PATH := "user://settings.cfg"
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
	"tutorial_enabled": true
}

var values: Dictionary = DEFAULTS.duplicate(true)


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for key: String in DEFAULTS:
		values[key] = config.get_value("settings", key, DEFAULTS[key])


func save_settings() -> Error:
	var config := ConfigFile.new()
	for key: String in values:
		config.set_value("settings", key, values[key])
	return config.save(SETTINGS_PATH)


func set_value(key: String, value: Variant) -> void:
	if DEFAULTS.has(key):
		values[key] = value
		apply()


func get_value(key: String) -> Variant:
	return values.get(key, DEFAULTS.get(key))


func apply() -> void:
	var buses := {
		"Master": "master_volume",
		"Music": "music_volume",
		"Ambience": "ambience_volume",
		"Effects": "effects_volume",
		"Voice": "voice_volume"
	}
	for bus_name: String in buses:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			var linear: float = clampf(float(values[buses[bus_name]]), 0.0, 1.0)
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	var scale: float = float(values.ui_scale)
	get_tree().root.content_scale_factor = scale

