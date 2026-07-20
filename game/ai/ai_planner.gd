class_name AIPlanner
extends RefCounted


static func update_awareness(actor: Dictionary, player_position: Vector2i, tiles: Array, noise: int) -> Dictionary:
	var updated := actor.duplicate(true)
	var distance := maxi(absi(actor.position.x - player_position.x), absi(actor.position.y - player_position.y))
	var can_see := distance <= int(actor.get("vision", 6)) and GridPathfinder.line_of_sight(tiles, actor.position, player_position)
	var can_hear := distance <= int(actor.get("hearing", 5)) + noise
	if can_see:
		updated.state = "alert"
		updated.last_known = player_position
		updated.memory_turns = 5
	elif can_hear and updated.get("state", "idle") == "idle":
		updated.state = "investigate"
		updated.last_known = player_position
		updated.memory_turns = 3
	elif int(updated.get("memory_turns", 0)) > 0:
		updated.memory_turns = int(updated.memory_turns) - 1
	elif updated.get("state") in ["alert", "investigate", "search"]:
		updated.state = "return"
	return updated


static func choose_action(actor: Dictionary, player: Dictionary, tiles: Array, occupied: Dictionary) -> Dictionary:
	var distance := maxi(absi(actor.position.x - player.position.x), absi(actor.position.y - player.position.y))
	if float(actor.get("health", 1)) / maxf(1.0, float(actor.get("max_health", 1))) < 0.2 and actor.get("archetype") not in ["brute", "guardian", "boss"]:
		return {"type": "retreat", "target": _step_away(actor.position, player.position, tiles)}
	if actor.get("state") == "alert" and distance <= int(actor.get("reach", 1)):
		return {"type": "attack", "target": player.position}
	if actor.get("state") == "alert" and actor.get("archetype") in ["caster", "ranged"] and distance <= int(actor.get("range", 6)):
		return {"type": "ability", "target": player.position}
	var target: Vector2i = actor.get("last_known", actor.get("home", actor.position))
	var path := GridPathfinder.find_path(tiles, actor.position, target, occupied)
	if path.size() > 1:
		return {"type": "move", "target": path[1]}
	if actor.get("state") == "return":
		return {"type": "idle"}
	return {"type": "search"}


static func _step_away(position: Vector2i, threat: Vector2i, tiles: Array) -> Vector2i:
	var options: Array[Vector2i] = []
	for direction: Vector2i in GridPathfinder.DIRECTIONS:
		var next := position + direction
		if GridPathfinder.is_walkable(tiles, next):
			options.append(next)
	options.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_squared_to(threat) > b.distance_squared_to(threat))
	return options.front() if not options.is_empty() else position

