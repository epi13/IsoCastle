class_name GridPathfinder
extends RefCounted

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
]


static func find_path(tiles: Array, start: Vector2i, goal: Vector2i, blocked: Dictionary = {}) -> Array[Vector2i]:
	if start == goal:
		return [start]
	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: start}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		for direction: Vector2i in DIRECTIONS:
			var next := current + direction
			if came_from.has(next) or blocked.has(next) or not is_walkable(tiles, next):
				continue
			if direction.x != 0 and direction.y != 0:
				if not is_walkable(tiles, current + Vector2i(direction.x, 0)):
					continue
				if not is_walkable(tiles, current + Vector2i(0, direction.y)):
					continue
			came_from[next] = current
			if next == goal:
				var path: Array[Vector2i] = [goal]
				var cursor := current
				while cursor != start:
					path.push_front(cursor)
					cursor = came_from[cursor]
				path.push_front(start)
				return path
			frontier.append(next)
	return []


static func reachable(tiles: Array, start: Vector2i, blocked: Dictionary = {}) -> Dictionary:
	var found: Dictionary = {start: true}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		for direction: Vector2i in DIRECTIONS:
			var next := current + direction
			if found.has(next) or blocked.has(next) or not is_walkable(tiles, next):
				continue
			if direction.x != 0 and direction.y != 0:
				if not is_walkable(tiles, current + Vector2i(direction.x, 0)) or not is_walkable(tiles, current + Vector2i(0, direction.y)):
					continue
			found[next] = true
			frontier.append(next)
	return found


static func line_of_sight(tiles: Array, start: Vector2i, goal: Vector2i) -> bool:
	var x0 := start.x
	var y0 := start.y
	var x1 := goal.x
	var y1 := goal.y
	var dx := absi(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var error := dx + dy
	while true:
		var point := Vector2i(x0, y0)
		if point != start and point != goal and not is_transparent(tiles, point):
			return false
		if x0 == x1 and y0 == y1:
			return true
		var doubled := 2 * error
		if doubled >= dy:
			error += dy
			x0 += sx
		if doubled <= dx:
			error += dx
			y0 += sy
	return true


static func is_walkable(tiles: Array, position: Vector2i) -> bool:
	if position.y < 0 or position.y >= tiles.size():
		return false
	var row: Array = tiles[position.y]
	if position.x < 0 or position.x >= row.size():
		return false
	return row[position.x] in ["floor", "door", "stairs", "water", "ice", "bridge"]


static func is_transparent(tiles: Array, position: Vector2i) -> bool:
	if position.y < 0 or position.y >= tiles.size():
		return false
	var row: Array = tiles[position.y]
	if position.x < 0 or position.x >= row.size():
		return false
	return row[position.x] not in ["wall", "secret_wall"]

