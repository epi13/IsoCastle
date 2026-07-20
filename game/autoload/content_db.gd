extends Node

const CATALOGS: Dictionary = {
	"items": "res://content/items/items.json",
	"affixes": "res://content/items/affixes.json",
	"spells": "res://content/spells/spells.json",
	"enemies": "res://content/enemies/enemies.json",
	"npcs": "res://content/actors/npcs.json",
	"quests": "res://content/quests/quests.json",
	"dialogue": "res://content/dialogue/dialogue.json",
	"lore": "res://content/dialogue/lore.json",
	"themes": "res://content/world/themes.json",
	"loot": "res://content/loot/loot_tables.json",
	"localization": "res://content/localization/en.json"
}

var data: Dictionary = {}
var by_id: Dictionary = {}
var errors: PackedStringArray = []


func _ready() -> void:
	reload()


func reload() -> bool:
	data.clear()
	by_id.clear()
	errors.clear()
	for catalog_name: String in CATALOGS:
		var path: String = CATALOGS[catalog_name]
		if not FileAccess.file_exists(path):
			errors.append("Missing catalog: %s" % path)
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			errors.append("Cannot open catalog: %s" % path)
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not parsed is Array:
			errors.append("Catalog must be an array: %s" % path)
			continue
		data[catalog_name] = parsed
		var index: Dictionary = {}
		for entry: Variant in parsed:
			if entry is Dictionary and entry.has("id"):
				index[String(entry.id)] = entry
		by_id[catalog_name] = index
	return errors.is_empty()


func get_entry(catalog_name: String, entry_id: String) -> Dictionary:
	return by_id.get(catalog_name, {}).get(entry_id, {})


func all(catalog_name: String) -> Array:
	return data.get(catalog_name, [])


func has_entry(catalog_name: String, entry_id: String) -> bool:
	return by_id.get(catalog_name, {}).has(entry_id)
