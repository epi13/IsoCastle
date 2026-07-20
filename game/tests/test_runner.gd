extends SceneTree

var failures: PackedStringArray = []
var checks := 0


func _initialize() -> void:
	print("IsoCastle headless unit tests")
	_test_catalogs()
	_test_projection()
	_test_save_round_trip()
	if failures.is_empty():
		print("PASS: %d checks" % checks)
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d failures across %d checks" % [failures.size(), checks])
		quit(1)


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _load_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	expect(file != null, "Open catalog %s" % path)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	expect(parsed is Array, "Parse catalog %s" % path)
	return parsed if parsed is Array else []


func _test_catalogs() -> void:
	var expected := {
		"res://content/items/items.json": 140,
		"res://content/spells/spells.json": 48,
		"res://content/enemies/enemies.json": 50,
		"res://content/actors/npcs.json": 25,
		"res://content/quests/quests.json": 30,
		"res://content/dialogue/dialogue.json": 100
	}
	for path: String in expected:
		var entries := _load_array(path)
		expect(entries.size() >= expected[path], "%s minimum count" % path)
		var ids: Dictionary = {}
		for entry: Dictionary in entries:
			expect(not ids.has(entry.id), "Unique ID %s" % entry.id)
			ids[entry.id] = true


func _test_projection() -> void:
	var tile := Vector2(96, 48)
	var grid := Vector2i(3, 2)
	var screen := Vector2((grid.x - grid.y) * tile.x * 0.5, (grid.x + grid.y) * tile.y * 0.5)
	expect(screen == Vector2(48, 120), "Isometric projection remains stable")


func _test_save_round_trip() -> void:
	var save := root.get_node_or_null("SaveService")
	expect(save != null, "SaveService autoload exists")
	if save == null:
		return
	save.delete_slot(4)
	var fixture := {
		"seed": 7719,
		"player": {"name": "Test Wanderer", "health": 17},
		"world": {"location": "greywake", "turn": 9},
		"inventory": [{"id": "weapon_club", "count": 1}]
	}
	var error: Error = save.save_slot(4, fixture)
	expect(error == OK, "Atomic save writes")
	var loaded: Dictionary = save.load_slot(4)
	expect(int(loaded.get("save_version", 0)) == 3, "Save version stamped")
	expect(int(loaded.get("seed", 0)) == 7719, "Seed round trips")
	expect(loaded.get("player", {}).get("name") == "Test Wanderer", "Nested player state round trips")
	save.delete_slot(4)

