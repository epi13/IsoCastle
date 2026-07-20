class_name InventoryRules
extends RefCounted


static func add_item(inventory: Array, item_id: String, count: int, catalog: Dictionary) -> Array:
	var result := inventory.duplicate(true)
	var definition: Dictionary = catalog.get(item_id, {})
	var limit := int(definition.get("stack_limit", 1))
	var remaining := count
	for stack: Dictionary in result:
		if stack.get("id") == item_id and int(stack.get("count", 1)) < limit:
			var added := mini(remaining, limit - int(stack.count))
			stack.count = int(stack.count) + added
			remaining -= added
	while remaining > 0:
		var amount := mini(remaining, limit)
		result.append({"id": item_id, "count": amount, "identified": true, "state": "ordinary"})
		remaining -= amount
	return result


static func remove_item(inventory: Array, item_id: String, count: int) -> Array:
	var result := inventory.duplicate(true)
	var remaining := count
	for index in range(result.size() - 1, -1, -1):
		var stack: Dictionary = result[index]
		if stack.get("id") != item_id:
			continue
		var taken := mini(remaining, int(stack.get("count", 1)))
		stack.count = int(stack.count) - taken
		remaining -= taken
		if int(stack.count) <= 0:
			result.remove_at(index)
		if remaining <= 0:
			break
	return result


static func split_stack(inventory: Array, index: int, amount: int) -> Array:
	var result := inventory.duplicate(true)
	if index < 0 or index >= result.size():
		return result
	var stack: Dictionary = result[index]
	if amount <= 0 or amount >= int(stack.get("count", 1)):
		return result
	stack.count = int(stack.count) - amount
	var split := stack.duplicate(true)
	split.count = amount
	result.insert(index + 1, split)
	return result


static func total_weight(inventory: Array, catalog: Dictionary) -> float:
	var weight := 0.0
	for stack: Dictionary in inventory:
		weight += float(catalog.get(stack.get("id"), {}).get("weight", 0.0)) * int(stack.get("count", 1))
	return snappedf(weight, 0.01)


static func can_equip(player: Dictionary, item: Dictionary) -> Dictionary:
	for stat: String in item.get("requirements", {}):
		var required := int(item.requirements[stat])
		if int(player.get(stat, 0)) < required:
			return {"ok": false, "reason": "Requires %s %d" % [stat.capitalize(), required]}
	return {"ok": true, "reason": ""}


static func merchant_price(item: Dictionary, disposition: int, buying: bool) -> int:
	var base := int(item.get("value", 0))
	var modifier := clampf(1.0 - disposition * 0.01, 0.65, 1.35) if buying else clampf(0.42 + disposition * 0.005, 0.25, 0.7)
	return maxi(0, int(round(base * modifier)))

