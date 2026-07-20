extends Node

const SAVE_VERSION := 3
const SLOT_COUNT := 5
const SAVE_DIR := "user://saves"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, clampi(slot, 0, SLOT_COUNT - 1)]


func save_slot(slot: int, state: Dictionary) -> Error:
	var path := slot_path(slot)
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
	var payload := state.duplicate(true)
	payload["save_version"] = SAVE_VERSION
	payload["saved_at_unix"] = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()
	var validation := _read_and_migrate(temp_path)
	if not validation.ok:
		return ERR_FILE_CORRUPT
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_backup)
		var backup_error := DirAccess.rename_absolute(absolute_path, absolute_backup)
		if backup_error != OK:
			return backup_error
	return DirAccess.rename_absolute(absolute_temp, absolute_path)


func load_slot(slot: int) -> Dictionary:
	var path := slot_path(slot)
	var result := _read_and_migrate(path)
	if result.ok:
		return result.data
	var backup := _read_and_migrate(path + ".bak")
	if backup.ok:
		backup.data["recovered_from_backup"] = true
		return backup.data
	return {}


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot)) or FileAccess.file_exists(slot_path(slot) + ".bak")


func delete_slot(slot: int) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot) + ".bak"))


func _read_and_migrate(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "open"}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"ok": false, "error": "parse"}
	var data: Dictionary = parsed
	var version := int(data.get("save_version", 1))
	if version > SAVE_VERSION:
		return {"ok": false, "error": "future_version"}
	while version < SAVE_VERSION:
		if version == 1:
			data["factions"] = data.get("reputation", {})
			data.erase("reputation")
		elif version == 2:
			data["journal"] = data.get("journal", {"lore": [], "bestiary": []})
		version += 1
		data["save_version"] = version
	return {"ok": true, "data": data}

