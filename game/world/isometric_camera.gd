class_name IsometricCamera
extends RefCounted

const TILE_WIDTH := 96.0
const TILE_HEIGHT := 48.0
const MIN_ZOOM := 0.72
const MAX_ZOOM := 1.55
const FOLLOW_SPEED := 12.0
const MAP_TOP_MARGIN := 112.0
const MAP_BOTTOM_MARGIN := 48.0

var viewport_rect := Rect2(Vector2.ZERO, Vector2(960, 600))
var map_bounds := Rect2(-48, -112, 96, 160)
var current_position := Vector2.ZERO
var target_position := Vector2.ZERO
var manual_offset := Vector2.ZERO
var zoom := 1.0
var level_size := Vector2i.ONE


func configure(new_viewport_rect: Rect2, new_level_size: Vector2i) -> void:
	viewport_rect = new_viewport_rect
	level_size = Vector2i(maxi(1, new_level_size.x), maxi(1, new_level_size.y))
	map_bounds = calculate_map_bounds(level_size)
	target_position = _clamp_position(target_position)
	current_position = _clamp_position(current_position)


func set_viewport_rect(new_viewport_rect: Rect2) -> void:
	viewport_rect = new_viewport_rect
	target_position = _clamp_position(target_position)
	current_position = _clamp_position(current_position)


func set_zoom(value: float) -> void:
	zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)
	target_position = _clamp_position(target_position)
	current_position = _clamp_position(current_position)


func focus_grid(grid: Vector2i, immediate: bool = false) -> void:
	target_position = _clamp_position(project_grid(grid) + manual_offset)
	if immediate:
		current_position = target_position


func update(delta: float) -> bool:
	var previous := current_position
	var weight := 1.0 - exp(-FOLLOW_SPEED * maxf(0.0, delta))
	current_position = current_position.lerp(target_position, weight)
	if current_position.distance_squared_to(target_position) < 0.01:
		current_position = target_position
	return previous.distance_squared_to(current_position) > 0.0001


func pan_screen(delta: Vector2) -> void:
	manual_offset -= delta / zoom
	target_position = _clamp_position(target_position - delta / zoom)
	current_position = _clamp_position(current_position - delta / zoom)


func reset_pan(grid: Vector2i, immediate: bool = false) -> void:
	manual_offset = Vector2.ZERO
	focus_grid(grid, immediate)


func grid_to_screen(grid: Vector2i) -> Vector2:
	return world_to_screen(project_grid(grid))


func screen_to_grid(screen: Vector2) -> Vector2i:
	var world := screen_to_world(screen)
	var x := world.x / TILE_WIDTH + world.y / TILE_HEIGHT
	var y := world.y / TILE_HEIGHT - world.x / TILE_WIDTH
	return Vector2i(roundi(x), roundi(y))


func world_to_screen(world: Vector2) -> Vector2:
	return viewport_rect.get_center() + (world - current_position) * zoom


func screen_to_world(screen: Vector2) -> Vector2:
	return current_position + (screen - viewport_rect.get_center()) / zoom


func projected_map_screen_rect() -> Rect2:
	return Rect2(world_to_screen(map_bounds.position), map_bounds.size * zoom)


func _clamp_position(desired: Vector2) -> Vector2:
	var half_visible := viewport_rect.size / (2.0 * zoom)
	var center := map_bounds.get_center()
	var result := desired
	if map_bounds.size.x <= half_visible.x * 2.0:
		result.x = center.x
	else:
		result.x = clampf(desired.x, map_bounds.position.x + half_visible.x, map_bounds.end.x - half_visible.x)
	if map_bounds.size.y <= half_visible.y * 2.0:
		result.y = center.y
	else:
		result.y = clampf(desired.y, map_bounds.position.y + half_visible.y, map_bounds.end.y - half_visible.y)
	return result


static func project_grid(grid: Vector2i) -> Vector2:
	return Vector2((grid.x - grid.y) * TILE_WIDTH * 0.5, (grid.x + grid.y) * TILE_HEIGHT * 0.5)


static func calculate_map_bounds(size_in_tiles: Vector2i) -> Rect2:
	var width := maxi(1, size_in_tiles.x)
	var height := maxi(1, size_in_tiles.y)
	var left := -float(height - 1) * TILE_WIDTH * 0.5 - TILE_WIDTH * 0.5
	var right := float(width - 1) * TILE_WIDTH * 0.5 + TILE_WIDTH * 0.5
	var bottom := float(width + height - 2) * TILE_HEIGHT * 0.5 + TILE_HEIGHT * 0.5 + MAP_BOTTOM_MARGIN
	return Rect2(Vector2(left, -MAP_TOP_MARGIN), Vector2(right - left, bottom + MAP_TOP_MARGIN))
