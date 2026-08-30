class_name InventoryRules
extends RefCounted

const MAX_SLOTS := 24
const EQUIPMENT_SLOTS: Array[String] = [
	"main_hand", "ranged", "off_hand", "head", "body", "hands",
	"feet", "waist", "back", "neck", "ring",
]


static func add_item(inventory: Array, item_id: String, count: int, catalog: Dictionary) -> Array:
	var result: Dictionary = add(inventory, item_id, count, catalog, 2147483647)
	return result.inventory


static func add(inventory: Array, item_id: String, count: int, catalog: Dictionary, max_slots: int = MAX_SLOTS, metadata: Dictionary = {}) -> Dictionary:
	var original := inventory.duplicate(true)
	if count <= 0:
		return _inventory_result(false, original, "Count must be positive.")
	var definition: Dictionary = catalog.get(item_id, {})
	if definition.is_empty():
		return _inventory_result(false, original, "Unknown item.")
	var result := original.duplicate(true)
	var limit := maxi(1, int(definition.get("stack_limit", 1)))
	var remaining := count
	var prototype := metadata.duplicate(true)
	prototype["id"] = item_id
	prototype["identified"] = prototype.get("identified", true)
	prototype["state"] = prototype.get("state", "ordinary")
	for stack: Dictionary in result:
		if _can_merge(stack, prototype, definition):
			var added := mini(remaining, limit - int(stack.get("count", 1)))
			stack["count"] = int(stack.get("count", 1)) + added
			remaining -= added
			if remaining == 0:
				break
	var required_slots := int(ceili(float(remaining) / float(limit)))
	if result.size() + required_slots > max_slots:
		return _inventory_result(false, original, "Inventory is full.")
	while remaining > 0:
		var amount := mini(remaining, limit)
		var stack := prototype.duplicate(true)
		stack["count"] = amount
		result.append(stack)
		remaining -= amount
	return _inventory_result(true, result, "", result != original, "add")


static func remove_item(inventory: Array, item_id: String, count: int) -> Array:
	var result := inventory.duplicate(true)
	var remaining := maxi(0, count)
	for index in range(result.size() - 1, -1, -1):
		var stack: Dictionary = result[index]
		if stack.get("id") != item_id:
			continue
		var taken := mini(remaining, int(stack.get("count", 1)))
		stack["count"] = int(stack.get("count", 1)) - taken
		remaining -= taken
		if int(stack.get("count", 0)) <= 0:
			result.remove_at(index)
		if remaining <= 0:
			break
	return result


static func move(inventory: Array, source_index: int, destination_index: int, catalog: Dictionary, amount: int = -1, max_slots: int = MAX_SLOTS) -> Dictionary:
	var original := inventory.duplicate(true)
	if source_index < 0 or source_index >= original.size():
		return _inventory_result(false, original, "Source slot is empty.")
	if destination_index < 0 or destination_index >= max_slots:
		return _inventory_result(false, original, "Destination slot is unavailable.")
	if source_index == destination_index:
		return _inventory_result(true, original, "", false, "no_op")
	var source: Dictionary = original[source_index]
	var source_count := int(source.get("count", 0))
	var move_count := source_count if amount < 0 else amount
	if move_count <= 0 or move_count > source_count:
		return _inventory_result(false, original, "Invalid move quantity.")
	var definition: Dictionary = catalog.get(source.get("id", ""), {})
	if definition.is_empty():
		return _inventory_result(false, original, "Unknown source item.")
	if destination_index >= original.size():
		var appended := original.duplicate(true)
		var moved: Dictionary = source.duplicate(true)
		moved["count"] = move_count
		if move_count == source_count:
			appended.remove_at(source_index)
		else:
			appended[source_index]["count"] = source_count - move_count
		appended.append(moved)
		return _inventory_result(true, appended, "", appended != original, "move")
	var destination: Dictionary = original[destination_index]
	if _can_merge(source, destination, definition):
		var available := maxi(0, int(definition.get("stack_limit", 1)) - int(destination.get("count", 1)))
		if available <= 0:
			return _inventory_result(false, original, "Destination stack is full.")
		var merged_count := mini(move_count, available)
		var merged := original.duplicate(true)
		merged[destination_index]["count"] = int(destination.get("count", 1)) + merged_count
		merged[source_index]["count"] = source_count - merged_count
		if int(merged[source_index].get("count", 0)) == 0:
			merged.remove_at(source_index)
		return _inventory_result(true, merged, "", true, "merge", merged_count)
	if move_count != source_count:
		return _inventory_result(false, original, "A split stack can only move to an empty or compatible slot.")
	var swapped := original.duplicate(true)
	var temporary: Dictionary = swapped[source_index]
	swapped[source_index] = swapped[destination_index]
	swapped[destination_index] = temporary
	return _inventory_result(true, swapped, "", true, "swap")


static func split(inventory: Array, source_index: int, amount: int, catalog: Dictionary, destination_index: int = -1, max_slots: int = MAX_SLOTS) -> Dictionary:
	var original := inventory.duplicate(true)
	if source_index < 0 or source_index >= original.size():
		return _inventory_result(false, original, "Source slot is empty.")
	var source: Dictionary = original[source_index]
	var definition: Dictionary = catalog.get(source.get("id", ""), {})
	if int(definition.get("stack_limit", 1)) <= 1:
		return _inventory_result(false, original, "This item cannot be split.")
	var source_count := int(source.get("count", 0))
	if amount <= 0 or amount >= source_count:
		return _inventory_result(false, original, "Split amount must leave at least one item in each stack.")
	if original.size() >= max_slots:
		return _inventory_result(false, original, "Inventory is full.")
	var target := destination_index
	if target < 0:
		target = mini(source_index + 1, original.size())
	if target < 0 or target > original.size() or target >= max_slots:
		return _inventory_result(false, original, "Destination slot is unavailable.")
	var result := original.duplicate(true)
	result[source_index]["count"] = source_count - amount
	var separated: Dictionary = source.duplicate(true)
	separated["count"] = amount
	result.insert(target, separated)
	return _inventory_result(true, result, "", true, "split", amount)


static func split_stack(inventory: Array, index: int, amount: int) -> Array:
	var catalog: Dictionary = {}
	if index >= 0 and index < inventory.size():
		catalog[inventory[index].get("id", "")] = {"stack_limit": maxi(2, int(inventory[index].get("count", 1)))}
	return split(inventory, index, amount, catalog, -1, 2147483647).inventory


static func equip(inventory: Array, equipment: Dictionary, source_index: int, destination_slot: String, player: Dictionary, catalog: Dictionary) -> Dictionary:
	var original_inventory := inventory.duplicate(true)
	var original_equipment := equipment.duplicate(true)
	if source_index < 0 or source_index >= original_inventory.size():
		return _state_result(false, original_inventory, original_equipment, "Source slot is empty.")
	if not EQUIPMENT_SLOTS.has(destination_slot):
		return _state_result(false, original_inventory, original_equipment, "Unknown equipment slot.")
	var stack: Dictionary = original_inventory[source_index]
	var definition: Dictionary = catalog.get(stack.get("id", ""), {})
	var validation := can_equip_to_slot(player, definition, destination_slot)
	if not validation.ok:
		return _state_result(false, original_inventory, original_equipment, validation.reason)
	if int(stack.get("count", 0)) != 1:
		return _state_result(false, original_inventory, original_equipment, "Equippable items must be individual stacks.")
	var result_inventory := original_inventory.duplicate(true)
	var result_equipment := original_equipment.duplicate(true)
	var replaced: Dictionary = result_equipment.get(destination_slot, {})
	result_equipment[destination_slot] = stack.duplicate(true)
	if replaced.is_empty():
		result_inventory.remove_at(source_index)
	else:
		result_inventory[source_index] = replaced.duplicate(true)
	return _state_result(true, result_inventory, result_equipment, "", true, "equip")


static func unequip(inventory: Array, equipment: Dictionary, source_slot: String, destination_index: int, player: Dictionary, catalog: Dictionary, max_slots: int = MAX_SLOTS) -> Dictionary:
	var original_inventory := inventory.duplicate(true)
	var original_equipment := equipment.duplicate(true)
	var equipped: Dictionary = original_equipment.get(source_slot, {})
	if equipped.is_empty():
		return _state_result(false, original_inventory, original_equipment, "Equipment slot is empty.")
	if destination_index < 0:
		destination_index = original_inventory.size()
	if destination_index < 0 or destination_index >= max_slots:
		return _state_result(false, original_inventory, original_equipment, "Destination slot is unavailable.")
	var result_inventory := original_inventory.duplicate(true)
	var result_equipment := original_equipment.duplicate(true)
	if destination_index >= result_inventory.size():
		if result_inventory.size() >= max_slots:
			return _state_result(false, original_inventory, original_equipment, "Inventory is full.")
		result_inventory.append(equipped.duplicate(true))
		result_equipment.erase(source_slot)
		return _state_result(true, result_inventory, result_equipment, "", true, "unequip")
	var replacement: Dictionary = result_inventory[destination_index]
	var replacement_definition: Dictionary = catalog.get(replacement.get("id", ""), {})
	var validation := can_equip_to_slot(player, replacement_definition, source_slot)
	if not validation.ok:
		return _state_result(false, original_inventory, original_equipment, validation.reason)
	result_inventory[destination_index] = equipped.duplicate(true)
	result_equipment[source_slot] = replacement.duplicate(true)
	return _state_result(true, result_inventory, result_equipment, "", true, "equipment_swap")


static func move_equipped(equipment: Dictionary, source_slot: String, destination_slot: String, player: Dictionary, catalog: Dictionary) -> Dictionary:
	var original := equipment.duplicate(true)
	if source_slot == destination_slot:
		return _state_result(true, [], original, "", false, "no_op")
	var source: Dictionary = original.get(source_slot, {})
	if source.is_empty():
		return _state_result(false, [], original, "Equipment slot is empty.")
	var source_validation := can_equip_to_slot(player, catalog.get(source.get("id", ""), {}), destination_slot)
	if not source_validation.ok:
		return _state_result(false, [], original, source_validation.reason)
	var destination: Dictionary = original.get(destination_slot, {})
	if not destination.is_empty():
		var destination_validation := can_equip_to_slot(player, catalog.get(destination.get("id", ""), {}), source_slot)
		if not destination_validation.ok:
			return _state_result(false, [], original, destination_validation.reason)
	var result := original.duplicate(true)
	result[destination_slot] = source.duplicate(true)
	if destination.is_empty():
		result.erase(source_slot)
	else:
		result[source_slot] = destination.duplicate(true)
	return _state_result(true, [], result, "", true, "equipment_move")


static func validate_destination(inventory: Array, equipment: Dictionary, source: Dictionary, destination: Dictionary, player: Dictionary, catalog: Dictionary, max_slots: int = MAX_SLOTS) -> Dictionary:
	var source_kind: String = source.get("kind", "")
	var destination_kind: String = destination.get("kind", "")
	var result: Dictionary
	if source_kind == "inventory" and destination_kind == "inventory":
		result = move(inventory, int(source.get("index", -1)), int(destination.get("index", -1)), catalog, int(source.get("amount", -1)), max_slots)
	elif source_kind == "inventory" and destination_kind == "equipment":
		result = equip(inventory, equipment, int(source.get("index", -1)), String(destination.get("slot", "")), player, catalog)
	elif source_kind == "equipment" and destination_kind == "inventory":
		result = unequip(inventory, equipment, String(source.get("slot", "")), int(destination.get("index", -1)), player, catalog, max_slots)
	elif source_kind == "equipment" and destination_kind == "equipment":
		result = move_equipped(equipment, String(source.get("slot", "")), String(destination.get("slot", "")), player, catalog)
	else:
		result = _state_result(false, inventory.duplicate(true), equipment.duplicate(true), "Unsupported destination.")
	return {"ok": bool(result.ok), "reason": String(result.reason), "operation": String(result.get("operation", ""))}


static func cancel(inventory: Array, equipment: Dictionary) -> Dictionary:
	return _state_result(true, inventory.duplicate(true), equipment.duplicate(true), "", false, "cancel")


static func total_weight(inventory: Array, catalog: Dictionary) -> float:
	var weight := 0.0
	for stack: Dictionary in inventory:
		weight += float(catalog.get(stack.get("id"), {}).get("weight", 0.0)) * int(stack.get("count", 1))
	return snappedf(weight, 0.01)


static func total_carried_weight(inventory: Array, equipment: Dictionary, catalog: Dictionary) -> float:
	var weight := total_weight(inventory, catalog)
	for slot: String in equipment:
		var stack: Dictionary = equipment.get(slot, {})
		weight += float(catalog.get(stack.get("id"), {}).get("weight", 0.0)) * int(stack.get("count", 1))
	return snappedf(weight, 0.01)


static func can_equip(player: Dictionary, item: Dictionary) -> Dictionary:
	for stat: String in item.get("requirements", {}):
		var required := int(item.requirements[stat])
		if int(player.get(stat, 0)) < required:
			return {"ok": false, "reason": "Requires %s %d" % [stat.capitalize(), required]}
	return {"ok": true, "reason": ""}


static func can_equip_to_slot(player: Dictionary, item: Dictionary, destination_slot: String) -> Dictionary:
	if item.is_empty() or String(item.get("slot", "")) != destination_slot:
		return {"ok": false, "reason": "That item is incompatible with the %s slot." % destination_slot.replace("_", " ")}
	return can_equip(player, item)


static func merchant_price(item: Dictionary, disposition: int, buying: bool) -> int:
	var base := int(item.get("value", 0))
	var modifier := clampf(1.0 - disposition * 0.01, 0.65, 1.35) if buying else clampf(0.42 + disposition * 0.005, 0.25, 0.7)
	return maxi(0, int(round(base * modifier)))


static func _can_merge(first: Dictionary, second: Dictionary, definition: Dictionary) -> bool:
	if int(definition.get("stack_limit", 1)) <= 1:
		return false
	var first_variant := first.duplicate(true)
	var second_variant := second.duplicate(true)
	first_variant.erase("count")
	second_variant.erase("count")
	return first_variant == second_variant


static func _inventory_result(ok: bool, inventory: Array, reason: String, changed: bool = false, operation: String = "", amount: int = 0) -> Dictionary:
	return {
		"ok": ok, "inventory": inventory, "reason": reason, "changed": changed,
		"operation": operation, "amount": amount,
	}


static func _state_result(ok: bool, inventory: Array, equipment: Dictionary, reason: String, changed: bool = false, operation: String = "") -> Dictionary:
	return {
		"ok": ok, "inventory": inventory, "equipment": equipment, "reason": reason,
		"changed": changed, "operation": operation,
	}
