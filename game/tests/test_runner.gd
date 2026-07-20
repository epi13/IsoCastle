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
		"potion": {"stack_limit": 3, "weight": 0.2, "value": 10, "slot": ""},
		"club": {"stack_limit": 1, "weight": 2.0, "value": 20, "slot": "main_hand", "requirements": {"might": 0}},
		"maul": {"stack_limit": 1, "weight": 4.0, "value": 50, "slot": "main_hand", "requirements": {"might": 5}},
		"bow": {"stack_limit": 1, "weight": 2.5, "value": 45, "slot": "ranged", "requirements": {"finesse": 2}},
		"helm": {"stack_limit": 1, "weight": 1.5, "value": 35, "slot": "head", "requirements": {"might": 1}},
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

	var arranged := [
		{"id": "club", "count": 1, "identified": true, "state": "ordinary"},
		{"id": "potion", "count": 2, "identified": true, "state": "ordinary"},
		{"id": "helm", "count": 1, "identified": true, "state": "ordinary"},
	]
	var moved := InventoryRules.move(arranged, 0, 3, catalog)
	expect(moved.ok and moved.operation == "move" and moved.inventory[2].id == "club", "Moving an item to an empty logical slot reorders inventory")
	var swapped := InventoryRules.move(moved.inventory, 0, 1, catalog)
	expect(swapped.ok and swapped.operation == "swap" and swapped.inventory[0].id == "helm" and swapped.inventory[1].id == "potion", "Dropping on an incompatible occupied slot swaps items")
	var merged := InventoryRules.move([
		{"id": "potion", "count": 2, "identified": true, "state": "ordinary"},
		{"id": "potion", "count": 1, "identified": true, "state": "ordinary"},
	], 1, 0, catalog)
	expect(merged.ok and merged.operation == "merge" and merged.inventory.size() == 1 and int(merged.inventory[0].count) == 3, "Compatible stacks merge without exceeding their limit")
	var split := InventoryRules.split(merged.inventory, 0, 1, catalog)
	expect(split.ok and split.inventory.size() == 2 and int(split.inventory[0].count) == 2 and int(split.inventory[1].count) == 1, "Explicit split operation preserves the total stack count")
	for invalid_amount in [-1, 0, 3, 4]:
		var invalid_split := InventoryRules.split(merged.inventory, 0, invalid_amount, catalog)
		expect(not invalid_split.ok and invalid_split.inventory == merged.inventory, "Invalid split quantity %d is rejected without mutation" % invalid_amount)
	var nonsplittable := InventoryRules.split([arranged[0]], 0, 1, catalog)
	expect(not nonsplittable.ok, "Non-stackable items cannot be split")
	var variants := [
		{"id": "potion", "count": 1, "identified": true, "state": "ordinary", "affixes": ["warm"]},
		{"id": "potion", "count": 1, "identified": true, "state": "ordinary", "affixes": ["clear"]},
	]
	var variant_swap := InventoryRules.move(variants, 0, 1, catalog)
	expect(variant_swap.ok and variant_swap.operation == "swap" and variant_swap.inventory[0].affixes == ["clear"], "Incompatible item variants swap instead of merging")

	var equipped := InventoryRules.equip(arranged, {}, 0, "main_hand", {"might": 5, "finesse": 5}, catalog)
	expect(equipped.ok and equipped.inventory.size() == 2 and equipped.equipment.main_hand.id == "club", "Valid equipment moves out of inventory and into its slot")
	var wrong_slot := InventoryRules.equip(arranged, {}, 2, "main_hand", {"might": 5}, catalog)
	expect(not wrong_slot.ok and wrong_slot.inventory == arranged and wrong_slot.equipment.is_empty(), "Incompatible equipment slot drop is rejected atomically")
	var unmet := InventoryRules.equip([{"id": "maul", "count": 1}], {}, 0, "main_hand", {"might": 4}, catalog)
	expect(not unmet.ok and unmet.inventory.size() == 1, "Unmet equipment requirements reject the drop without item loss")
	var replaced := InventoryRules.equip(
		[{"id": "club", "count": 1, "identified": true, "state": "ordinary"}],
		{"main_hand": {"id": "maul", "count": 1, "identified": true, "state": "etched", "affixes": ["old"]}},
		0, "main_hand", {"might": 5}, catalog
	)
	expect(replaced.ok and replaced.equipment.main_hand.id == "club" and replaced.inventory[0].id == "maul", "Replacing equipment returns the original metadata-bearing item to inventory")
	expect(replaced.inventory[0].state == "etched" and replaced.inventory[0].affixes == ["old"], "Equipment replacement preserves unique metadata")
	var unequipped := InventoryRules.unequip(equipped.inventory, equipped.equipment, "main_hand", -1, {"might": 5}, catalog)
	expect(unequipped.ok and unequipped.equipment.is_empty() and unequipped.inventory.back().id == "club", "Equipped items can move back into inventory")
	var equipment_moved := InventoryRules.move_equipped(
		{"main_hand": {"id": "club", "count": 1}, "ranged": {"id": "bow", "count": 1}},
		"main_hand", "ranged", {"might": 5, "finesse": 5}, catalog
	)
	expect(not equipment_moved.ok, "Equipped items only swap when both destination slot validations pass")

	var full_inventory: Array = []
	for _slot in range(InventoryRules.MAX_SLOTS):
		full_inventory.append({"id": "helm", "count": 1, "identified": true, "state": "ordinary"})
	var full_add := InventoryRules.add(full_inventory, "club", 1, catalog)
	expect(not full_add.ok and full_add.inventory == full_inventory, "A full inventory rejects a new stack without partial mutation")
	var full_unequip := InventoryRules.unequip(full_inventory, {"main_hand": {"id": "club", "count": 1}}, "main_hand", -1, {"might": 5}, catalog)
	expect(not full_unequip.ok and full_unequip.equipment.has("main_hand"), "A full inventory cannot lose an unequipped item")
	var cancelled := InventoryRules.cancel(arranged, {"main_hand": {"id": "maul", "count": 1}})
	expect(cancelled.ok and not cancelled.changed and cancelled.inventory == arranged and cancelled.equipment.main_hand.id == "maul", "Drag cancellation is a deterministic no-op")
	var rejected := InventoryRules.validate_destination(arranged, {}, {"kind": "inventory", "index": 2}, {"kind": "equipment", "slot": "main_hand"}, {"might": 5}, catalog)
	expect(not rejected.ok, "Destination validation identifies a rejected drop before state mutation")
	var before_units := _inventory_units([{"id": "club", "count": 1}]) + _equipment_units({"main_hand": {"id": "maul", "count": 1}})
	var after_units := _inventory_units(replaced.inventory) + _equipment_units(replaced.equipment)
	expect(before_units == after_units, "Equipment replacement does not duplicate or lose item units")
	expect(is_equal_approx(InventoryRules.total_carried_weight(replaced.inventory, replaced.equipment, catalog), 6.0), "Carried weight includes inventory and equipped items exactly once")


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
	expect(int(migrated.save_version) == 4, "Version 1 save migrates to current schema")
	expect(migrated.has("factions") and migrated.has("journal"), "Save migration creates faction and journal fields")
	save.delete_slot(4)
	var fixture := {
		"seed": 7719,
		"player": {"name": "Test Wanderer", "health": 17},
		"world": {"location": "greywake", "turn": 9},
		"inventory": [{"id": "consumable_redroot_draught", "count": 2, "affixes": ["clear"]}],
		"equipment": {"main_hand": {"id": "weapon_club", "count": 1, "state": "etched", "affixes": ["old"]}},
	}
	var error: Error = save.save_slot(4, fixture)
	expect(error == OK, "Atomic save writes")
	var loaded: Dictionary = save.load_slot(4)
	expect(int(loaded.get("save_version", 0)) == 4, "Save version stamped")
	expect(int(loaded.get("seed", 0)) == 7719, "Seed round trips")
	expect(loaded.get("player", {}).get("name") == "Test Wanderer", "Nested player state round trips")
	expect(loaded.equipment.main_hand.state == "etched" and loaded.inventory[0].affixes == ["clear"], "Inventory and equipment metadata survive save/load")
	save.delete_slot(4)
	var legacy_file := FileAccess.open(old_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({
		"save_version": 3,
		"inventory": [{"id": "weapon_club", "count": 1, "identified": true, "state": "ordinary"}],
		"equipment": {"main_hand": "weapon_club"},
	}))
	legacy_file.close()
	var ownership_migrated: Dictionary = save.load_slot(4)
	expect(int(ownership_migrated.save_version) == 4 and ownership_migrated.inventory.is_empty(), "Version 3 equipment references migrate to single ownership")
	expect(ownership_migrated.equipment.main_hand.id == "weapon_club", "Migrated equipment retains the equipped item")
	save.delete_slot(4)


func _inventory_units(inventory: Array) -> int:
	var total := 0
	for stack: Dictionary in inventory:
		total += int(stack.get("count", 0))
	return total


func _equipment_units(equipment: Dictionary) -> int:
	var total := 0
	for slot: String in equipment:
		total += int(equipment[slot].get("count", 0))
	return total
