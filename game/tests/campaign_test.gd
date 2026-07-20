extends SceneTree


func _initialize() -> void:
	var character := {
		"name": "Campaign Auditor", "presentation": "Weathered traveler", "portrait": "stone",
		"background": "Ledger Dropout", "practice": "threadseeing", "level": 12, "xp": 0,
		"might": 8, "finesse": 8, "resolve": 10, "max_health": 120, "health": 120,
		"max_mana": 120, "mana": 120, "accuracy": 90, "evasion": 16, "armor": 8,
		"speed": 120, "critical": 15, "silver": 500, "statuses": [], "alive": true,
		"starting_items": [{"id": "artifact_the_patient_shield", "count": 1, "identified": true, "state": "ordinary"}],
		"starting_spells": ["spell_find_the_seam"],
	}
	var session := root.get_node("GameSession")
	session.new_game(character, 424242, "journey")
	var game_script: Script = load("res://game/ui/game_view.gd")
	var game: Variant = game_script.new()
	root.add_child(game)
	await process_frame
	await process_frame
	var seen_themes: Dictionary = {}
	for depth_index in range(12):
		game._enter_depth(depth_index)
		if game.level.is_empty():
			push_error("Campaign depth %d did not generate" % depth_index)
			_cleanup(game, game_script)
			quit(1)
			return
		var path := GridPathfinder.find_path(game.level.tiles, game.level.start, game.level.exit)
		if path.is_empty():
			push_error("Campaign depth %d has no main path" % depth_index)
			_cleanup(game, game_script)
			quit(1)
			return
		seen_themes[game.level.theme] = true
		game.player.position = game.level.exit
		session.state.world.turn = int(session.state.world.turn) + path.size()
	if seen_themes.size() != 12:
		push_error("Campaign did not visit all 12 environment themes")
		_cleanup(game, game_script)
		quit(1)
		return
	game._show_ending()
	game._finish_ending("archive")
	if not bool(session.state.flags.get("campaign_complete", false)):
		push_error("Campaign completion flag was not set")
		_cleanup(game, game_script)
		quit(1)
		return
	if session.state.flags.get("ending") != "archive" or session.state.world.location != "postgame_greywake":
		push_error("Ending consequence or post-game state missing")
		_cleanup(game, game_script)
		quit(1)
		return
	var completed_main := 0
	for quest: Dictionary in root.get_node("ContentDB").all("quests"):
		if quest.type == "main" and session.state.quests.get(quest.id, {}).get("state") == "complete":
			completed_main += 1
	if completed_main < 9:
		push_error("Main quest chain did not progress through the campaign")
		_cleanup(game, game_script)
		quit(1)
		return
	print("CAMPAIGN PASS: 12 themes, reachable exits, three-act quest state, ending, post-game")
	_cleanup(game, game_script)
	game = null
	game_script = null
	await create_timer(0.15).timeout
	quit(0)


func _cleanup(game: Variant, game_script: Script) -> void:
	root.get_node("AudioDirector").stop_all()
	game.texture_cache.clear()
	game.floor_texture = null
	game.wall_texture = null
	game.effect_state.clear()
	root.remove_child(game)
	game.free()
	game = null
	game_script = null
