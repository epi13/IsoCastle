extends Node

var snapshot: Dictionary = {"screen": "boot", "ready": false}


func _ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.IsoCastleTest = {screen:'boot', ready:false};")
	set_value("platform", "web" if OS.has_feature("web") else OS.get_name().to_lower())
	call_deferred("_publish_startup_state")


func _publish_startup_state() -> void:
	var settings := get_node_or_null("/root/SettingsService")
	if settings != null:
		set_value("bindings", settings.input_bindings.serialized())
		for key: String in ["master_volume", "music_volume", "effects_volume", "fullscreen"]:
			set_value("setting_%s" % key, settings.get_value(key))
	var saves := get_node_or_null("/root/SaveService")
	if saves != null:
		set_value("has_save", saves.has_slot(0))


func set_screen(screen_id: String) -> void:
	set_value("screen", screen_id)
	set_value("ready", true)


func set_value(key: String, value: Variant) -> void:
	snapshot[key] = value
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.IsoCastleTest[%s] = %s;" % [JSON.stringify(key), JSON.stringify(value)])


func publish_inventory(inventory: Array, equipment: Dictionary) -> void:
	var inventory_units := 0
	var ids := PackedStringArray()
	for stack: Dictionary in inventory:
		inventory_units += int(stack.get("count", 0))
		ids.append("%s:%d" % [stack.get("id", ""), int(stack.get("count", 0))])
	var equipment_units := 0
	var equipped_ids: Dictionary = {}
	for slot: String in equipment:
		var stack: Dictionary = equipment[slot]
		equipment_units += int(stack.get("count", 0))
		equipped_ids[slot] = stack.get("id", "")
	set_value("inventory_units", inventory_units)
	set_value("equipment_units", equipment_units)
	set_value("inventory", Array(ids))
	set_value("equipment", equipped_ids)
