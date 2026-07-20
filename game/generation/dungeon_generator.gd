class_name DungeonGenerator
extends RefCounted

const WIDTH := 29
const HEIGHT := 23
const MAX_ATTEMPTS := 12


func generate(seed_value: int, theme_id: String, depth: int = 0) -> Dictionary:
	for attempt in range(MAX_ATTEMPTS):
		var result := _generate_attempt(seed_value + attempt * 7919, theme_id, depth, attempt)
		if validate(result):
			return result
	return {}


func _generate_attempt(seed_value: int, theme_id: String, depth: int, attempt: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var tiles: Array = []
	for y in range(HEIGHT):
		var row: Array[String] = []
		for _x in range(WIDTH):
			row.append("wall")
		tiles.append(row)

	var rooms: Array[Rect2i] = []
	for room_index in range(11):
		var room_size := Vector2i(rng.randi_range(4, 7), rng.randi_range(4, 6))
		var room_position := Vector2i(rng.randi_range(1, WIDTH - room_size.x - 2), rng.randi_range(1, HEIGHT - room_size.y - 2))
		var room := Rect2i(room_position, room_size)
		var overlaps := false
		for existing: Rect2i in rooms:
			if existing.grow(1).intersects(room):
				overlaps = true
				break
		if overlaps:
			continue
		_carve_room(tiles, room)
		if not rooms.is_empty():
			_carve_corridor(tiles, _center(rooms.back()), _center(room), rng.randi() % 2 == 0)
		rooms.append(room)
	if rooms.size() < 4:
		return {}

	var start := _center(rooms.front())
	var exit := _center(rooms.back())
	tiles[start.y][start.x] = "stairs"
	tiles[exit.y][exit.x] = "stairs"
	var objects: Array[Dictionary] = []
	var floor_positions: Array[Vector2i] = []
	for y in range(1, HEIGHT - 1):
		for x in range(1, WIDTH - 1):
			if tiles[y][x] == "floor" and Vector2i(x, y) not in [start, exit]:
				floor_positions.append(Vector2i(x, y))
	for index in range(floor_positions.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held := floor_positions[index]
		floor_positions[index] = floor_positions[swap_index]
		floor_positions[swap_index] = held
	for i in range(mini(4 + depth / 2, floor_positions.size())):
		objects.append({"type": "trap", "position": floor_positions[i], "hidden": true, "disarmed": false})
	for i in range(4, mini(8, floor_positions.size())):
		objects.append({"type": "chest", "position": floor_positions[i], "opened": false})
	if floor_positions.size() > 10:
		objects.append({"type": "key", "id": "floor_key", "position": floor_positions[8], "taken": false})
		objects.append({"type": "locked_door", "key": "floor_key", "position": floor_positions[9], "locked": true})
	if depth % 3 == 1 and floor_positions.size() > 12:
		var hazard_position := floor_positions[12]
		tiles[hazard_position.y][hazard_position.x] = ["water", "ice", "bridge"][depth % 3]
	return {
		"seed": seed_value, "attempt": attempt, "theme": theme_id, "depth": depth,
		"width": WIDTH, "height": HEIGHT, "tiles": tiles, "rooms": rooms,
		"start": start, "exit": exit, "objects": objects,
	}


func validate(level: Dictionary) -> bool:
	if level.is_empty() or not level.has("tiles") or not level.has("start") or not level.has("exit"):
		return false
	var reachable := GridPathfinder.reachable(level.tiles, level.start)
	if not reachable.has(level.exit):
		return false
	var key_seen := false
	for object: Dictionary in level.get("objects", []):
		if object.type == "key":
			key_seen = reachable.has(object.position)
		elif object.type == "locked_door" and not key_seen:
			return false
	return true


func _carve_room(tiles: Array, room: Rect2i) -> void:
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			tiles[y][x] = "floor"


func _carve_corridor(tiles: Array, start: Vector2i, end: Vector2i, horizontal_first: bool) -> void:
	var cursor := start
	if horizontal_first:
		while cursor.x != end.x:
			tiles[cursor.y][cursor.x] = "floor"
			cursor.x += signi(end.x - cursor.x)
		while cursor.y != end.y:
			tiles[cursor.y][cursor.x] = "floor"
			cursor.y += signi(end.y - cursor.y)
	else:
		while cursor.y != end.y:
			tiles[cursor.y][cursor.x] = "floor"
			cursor.y += signi(end.y - cursor.y)
		while cursor.x != end.x:
			tiles[cursor.y][cursor.x] = "floor"
			cursor.x += signi(end.x - cursor.x)
	tiles[end.y][end.x] = "floor"


func _center(room: Rect2i) -> Vector2i:
	return room.position + room.size / 2
