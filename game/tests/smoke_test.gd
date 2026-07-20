extends SceneTree


func _initialize() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var buttons := scene.find_children("*", "Button", true, false)
	if buttons.size() < 5:
		push_error("Title screen did not create required controls")
		quit(1)
		return
	scene._show_character_creation()
	await process_frame
	scene.name_input.text = "Smoke Wanderer"
	scene.seed_input.text = "7719"
	scene._create_character_and_start()
	await process_frame
	await process_frame
	var session := root.get_node("GameSession")
	var game: Variant = null
	for child in scene.screen_root.get_children():
		if child.has_method("_enter_depth"):
			game = child
	if game == null:
		push_error("Character creation did not launch the game view")
		quit(1)
		return
	if game.level.is_empty() or game.enemies.is_empty():
		push_error("Playable world failed to generate")
		quit(1)
		return
	var start: Vector2i = game.player.position
	var moved := false
	for direction: Vector2i in GridPathfinder.DIRECTIONS:
		var target := start + direction
		if GridPathfinder.is_walkable(game.level.tiles, target) and game._enemy_at(target) < 0:
			game._try_move(direction)
			moved = game.player.position == target
			break
	if not moved:
		push_error("Smoke player could not move")
		quit(1)
		return
	var before_inventory: int = session.state.inventory.size()
	var chest: Dictionary = {}
	for object: Dictionary in game.level.objects:
		if object.type == "chest":
			chest = object
			break
	if not chest.is_empty():
		game.player.position = chest.position
		game._interact()
		if session.state.inventory.size() < before_inventory:
			push_error("Chest pickup reduced inventory")
			quit(1)
			return
	game.enemies[0].position = game.player.position + Vector2i(1, 0)
	game.enemies[0].health = 30
	game.enemies[0].max_health = 30
	game._melee_attack(0)
	var mana_before := int(game.player.mana)
	game.enemies[0].position = game.player.position + Vector2i(2, 0)
	game.enemies[0].alive = true
	game._recalculate_visibility()
	game._cast_first_spell()
	if int(game.player.mana) >= mana_before:
		push_error("Spell smoke did not spend focus")
		quit(1)
		return
	game._save()
	if not root.get_node("SaveService").has_slot(0):
		push_error("Smoke save was not created")
		quit(1)
		return
	game._load()
	game._enter_depth(1)
	if int(game.level.depth) != 1:
		push_error("Level transition failed")
		quit(1)
		return
	var quest := {"id": "smoke_quest", "stages": [{"target": 1}]}
	var quest_state := QuestEngine.advance(QuestEngine.start({}, quest.id), quest)
	if quest_state.smoke_quest.state != "complete":
		push_error("Quest smoke did not complete")
		quit(1)
		return
	print("SMOKE PASS: menu, character, world, move, pickup, combat, spell, save/load, level, quest")
	root.get_node("AudioDirector").stop_all()
	await create_timer(0.15).timeout
	game.texture_cache.clear()
	game.floor_texture = null
	game.wall_texture = null
	game.effect_state.clear()
	game.get_parent().remove_child(game)
	game.free()
	game = null
	root.remove_child(scene)
	scene.free()
	scene = null
	packed = null
	await process_frame
	await process_frame
	quit(0)
