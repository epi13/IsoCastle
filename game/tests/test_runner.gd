extends SceneTree

var failures: PackedStringArray = []
var checks := 0


func _initialize() -> void:
	print("IsoCastle headless unit tests")
	_test_catalogs()
	_test_projection()
	_test_pathfinding_and_generation()
	_test_combat_and_statuses()
	_test_turn_engine()
	_test_inventory_and_equipment()
	_test_ai_transitions()
	_test_quest_state()
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


func _test_pathfinding_and_generation() -> void:
	var generator := DungeonGenerator.new()
	for seed_value in range(20, 40):
		var level := generator.generate(seed_value, "theme_mosswake_barrows", seed_value % 12)
		expect(not level.is_empty(), "Dungeon seed %d generates" % seed_value)
		expect(generator.validate(level), "Dungeon seed %d validates connectivity and key order" % seed_value)
		var path := GridPathfinder.find_path(level.tiles, level.start, level.exit)
		expect(path.size() > 1, "Dungeon seed %d exit is reachable" % seed_value)
		expect(path.front() == level.start and path.back() == level.exit, "Path endpoints remain correct")
	var first := generator.generate(7719, "theme_mosswake_barrows", 2)
	var second := generator.generate(7719, "theme_mosswake_barrows", 2)
	expect(first.tiles == second.tiles, "Dungeon tiles are deterministic")
	expect(first.objects == second.objects, "Dungeon objects are deterministic")
	var corner_tiles := [
		["wall", "wall", "wall"],
		["wall", "floor", "wall"],
		["wall", "wall", "floor"]
	]
	expect(GridPathfinder.find_path(corner_tiles, Vector2i(1, 1), Vector2i(2, 2)).is_empty(), "Diagonal corner cutting is rejected")


func _test_combat_and_statuses() -> void:
	var attacker := {"accuracy": 80, "finesse": 4, "might": 3, "critical": 0}
	var defender := {"health": 20, "max_health": 20, "evasion": 5, "armor": 2, "resistances": {"slash": 25}, "alive": true}
	var weapon := {"damage": [6, 10], "damage_type": "slash"}
	var one := CombatRules.attack(attacker, defender, weapon, 991)
	var two := CombatRules.attack(attacker, defender, weapon, 991)
	expect(one == two, "Combat is deterministic for a seed")
	expect(int(one.accuracy) == 83, "Accuracy formula remains legible")
	if one.hit:
		expect(int(one.damage) >= 1, "Armor and resistance retain minimum hit damage")
	var dead := CombatRules.apply_damage(defender, {"damage": 999})
	expect(not dead.alive and int(dead.health) == 0, "Player or actor death clamps health and marks dead")
	var ticking := {
		"health": 10, "max_health": 20, "alive": true,
		"statuses": [{"id": "burn", "damage": 3, "duration": 2}, {"id": "renew", "healing": 1, "duration": 1}]
	}
	var after := CombatRules.tick_statuses(ticking)
	expect(int(after.health) == 8, "Damage and healing over time resolve in order")
	expect(after.statuses.size() == 1 and int(after.statuses[0].duration) == 1, "Statuses expire deterministically")


func _test_turn_engine() -> void:
	var turns := TurnEngine.new()
	turns.reset([
		{"id": "slow", "speed": 80, "energy": 0, "alive": true},
		{"id": "fast", "speed": 120, "energy": 0, "alive": true}
	])
	var next := turns.next_actor_index()
	expect(next == 1, "Higher speed actor reaches action threshold first")
	turns.spend(next, 100)
	expect(int(turns.actors[next].energy) == 20, "Energy action cost is applied exactly")


func _test_inventory_and_equipment() -> void:
	var catalog := {
		"potion": {"stack_limit": 3, "weight": 0.2, "value": 10},
		"maul": {"stack_limit": 1, "weight": 4.0, "value": 50, "requirements": {"might": 5}}
	}
	var inventory: Array = []
	inventory = InventoryRules.add_item(inventory, "potion", 7, catalog)
	expect(inventory.size() == 3, "Inventory stacking creates bounded stacks")
	expect(int(inventory[0].count) == 3 and int(inventory[2].count) == 1, "Stack counts preserve total")
	inventory = InventoryRules.split_stack(inventory, 0, 1)
	expect(int(inventory[0].count) == 2 and int(inventory[1].count) == 1, "Stack splitting preserves source and split")
	inventory = InventoryRules.remove_item(inventory, "potion", 4)
	var remaining := 0
	for stack: Dictionary in inventory:
		if stack.id == "potion":
			remaining += int(stack.count)
	expect(remaining == 3, "Removing stacked inventory preserves remainder")
	expect(is_equal_approx(InventoryRules.total_weight(inventory, catalog), 0.6), "Inventory weight is deterministic")
	expect(not InventoryRules.can_equip({"might": 4}, catalog.maul).ok, "Equipment requirements reject weak build")
	expect(InventoryRules.can_equip({"might": 5}, catalog.maul).ok, "Equipment requirements accept qualifying build")
	expect(InventoryRules.merchant_price(catalog.potion, 0, true) == 10, "Merchant buy baseline is exact")
	expect(InventoryRules.merchant_price(catalog.potion, 0, false) == 4, "Merchant sell baseline is exact")


func _test_ai_transitions() -> void:
	var tiles := []
	for _y in range(7):
		tiles.append(["floor", "floor", "floor", "floor", "floor", "floor", "floor"])
	var actor := {
		"position": Vector2i(1, 1), "home": Vector2i(1, 1), "state": "idle",
		"vision": 5, "hearing": 4, "memory_turns": 0, "health": 10, "max_health": 10,
		"archetype": "pack", "reach": 1
	}
	var alert := AIPlanner.update_awareness(actor, Vector2i(3, 1), tiles, 0)
	expect(alert.state == "alert" and alert.last_known == Vector2i(3, 1), "AI enters alert and remembers target")
	alert.position = Vector2i(2, 1)
	var action := AIPlanner.choose_action(alert, {"position": Vector2i(3, 1)}, tiles, {})
	expect(action.type == "attack", "Adjacent alert AI attacks")
	alert.health = 1
	var retreat := AIPlanner.choose_action(alert, {"position": Vector2i(3, 1)}, tiles, {})
	expect(retreat.type == "retreat", "Wounded non-guardian AI retreats")


func _test_quest_state() -> void:
	var quest := {"id": "test_quest", "stages": [{"target": 1}, {"target": 2}]}
	var states := QuestEngine.start({}, quest.id)
	expect(states.test_quest.state == "active", "Quest begins active")
	states = QuestEngine.advance(states, quest)
	expect(int(states.test_quest.stage) == 1, "Quest advances first stage")
	states = QuestEngine.advance(states, quest, 2)
	expect(states.test_quest.state == "complete", "Quest completes after final objective")
	states = QuestEngine.record_choice(states, quest.id, "mercy")
	expect(states.test_quest.choices == ["mercy"], "Quest consequences retain choices")


func _test_save_round_trip() -> void:
	var save := root.get_node_or_null("SaveService")
	expect(save != null, "SaveService autoload exists")
	if save == null:
		return
	save.delete_slot(4)
	var old_path: String = save.slot_path(4)
	var old_file := FileAccess.open(old_path, FileAccess.WRITE)
	old_file.store_string(JSON.stringify({"save_version": 1, "seed": 9, "reputation": {"greywake": 2}}))
	old_file.close()
	var migrated: Dictionary = save.load_slot(4)
	expect(int(migrated.save_version) == 3, "Version 1 save migrates to current schema")
	expect(migrated.has("factions") and migrated.has("journal"), "Save migration creates faction and journal fields")
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
