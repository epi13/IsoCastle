class_name GameView
extends Control

signal return_to_menu

const TILE_WIDTH := 40.0
const TILE_HEIGHT := 20.0
const VIEW_ORIGIN := Vector2(665, 74)
const PLAYER_ANIMATIONS := ["idle", "walk", "run", "melee_attack", "ranged_attack", "cast", "hit", "block", "use_item", "interact", "death", "victory"]

var level: Dictionary = {}
var depth := 0
var player: Dictionary = {}
var enemies: Array[Dictionary] = []
var visible_tiles: Dictionary = {}
var discovered: Dictionary = {}
var combat_log: PackedStringArray = []
var item_catalog: Dictionary = {}
var spell_catalog: Dictionary = {}
var enemy_catalog: Array = []
var hud_label: RichTextLabel
var log_label: RichTextLabel
var modal: PanelContainer
var modal_title: Label
var modal_body: RichTextLabel
var modal_actions: VBoxContainer
var hover_tile := Vector2i(-1, -1)
var turn_seed := 0
var screenshot_mode := false
var texture_cache: Dictionary = {}
var floor_texture: Texture2D
var wall_texture: Texture2D
var effect_state: Dictionary = {}
var npc: Dictionary = {}
var debug_enabled := false


func _ready() -> void:
	set_process(true)
	set_process_unhandled_input(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	for item: Dictionary in ContentDB.all("items"):
		item_catalog[item.id] = item
	for spell: Dictionary in ContentDB.all("spells"):
		spell_catalog[spell.id] = spell
	enemy_catalog = ContentDB.all("enemies")
	_build_hud()
	_restore_or_start()
	_enter_depth(int(GameSession.state.get("world", {}).get("floor", 0)))


func _process(_delta: float) -> void:
	if not effect_state.is_empty():
		var elapsed := (Time.get_ticks_msec() - int(effect_state.started)) / 1000.0
		if elapsed >= 0.48:
			effect_state.clear()
			queue_redraw()
		else:
			effect_state.frame = mini(3, int(elapsed / 0.12))
			queue_redraw()


func _build_hud() -> void:
	var top_bar := ColorRect.new()
	top_bar.color = Color("#101925e8")
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(1280, 46)
	add_child(top_bar)

	var place := Label.new()
	place.name = "PlaceLabel"
	place.text = "GREYWAKE • THE BELL BELOW"
	place.position = Vector2(20, 10)
	place.size = Vector2(600, 30)
	place.add_theme_font_size_override("font_size", 18)
	place.add_theme_color_override("font_color", Color("#e0bd76"))
	add_child(place)

	var help := Label.new()
	help.text = "QWE/ASD/ZXC move  •  F interact  •  V search  •  1 cast  •  2 ranged  •  3 quick item  •  I/B/J/M  •  Esc"
	help.position = Vector2(480, 12)
	help.size = Vector2(775, 24)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	help.add_theme_font_size_override("font_size", 13)
	help.add_theme_color_override("font_color", Color("#9bb0b7"))
	add_child(help)

	var side := ColorRect.new()
	side.color = Color("#0c141eea")
	side.position = Vector2(965, 46)
	side.size = Vector2(315, 674)
	add_child(side)

	hud_label = RichTextLabel.new()
	hud_label.bbcode_enabled = true
	hud_label.fit_content = false
	hud_label.scroll_active = false
	hud_label.position = Vector2(984, 66)
	hud_label.size = Vector2(276, 320)
	hud_label.add_theme_font_size_override("normal_font_size", 16)
	add_child(hud_label)

	var divider := HSeparator.new()
	divider.position = Vector2(984, 388)
	divider.size = Vector2(276, 10)
	add_child(divider)

	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.position = Vector2(984, 405)
	log_label.size = Vector2(276, 286)
	log_label.add_theme_font_size_override("normal_font_size", 14)
	add_child(log_label)

	modal = PanelContainer.new()
	modal.visible = false
	modal.position = Vector2(160, 92)
	modal.size = Vector2(760, 560)
	modal.z_index = 100
	add_child(modal)
	var modal_box := VBoxContainer.new()
	modal_box.add_theme_constant_override("separation", 12)
	modal.add_child(modal_box)
	modal_title = Label.new()
	modal_title.add_theme_font_size_override("font_size", 32)
	modal_title.add_theme_color_override("font_color", Color("#e0bd76"))
	modal_box.add_child(modal_title)
	modal_body = RichTextLabel.new()
	modal_body.bbcode_enabled = true
	modal_body.custom_minimum_size = Vector2(700, 430)
	modal_body.add_theme_font_size_override("normal_font_size", 17)
	modal_box.add_child(modal_body)
	modal_actions = VBoxContainer.new()
	modal_actions.add_theme_constant_override("separation", 6)
	modal_box.add_child(modal_actions)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(func() -> void: modal.visible = false)
	modal_box.add_child(close)


func _restore_or_start() -> void:
	var stored: Dictionary = GameSession.state.get("player", {})
	if stored.is_empty():
		stored = {
			"name": "Wayfarer", "background": "Returned Apprentice", "practice": "cinderweave",
			"level": 1, "xp": 0, "might": 3, "finesse": 3, "resolve": 4,
			"max_health": 28, "health": 28, "max_mana": 18, "mana": 18,
			"accuracy": 68, "evasion": 8, "armor": 1, "speed": 100, "critical": 5,
			"silver": 40, "statuses": [], "alive": true,
		}
	player = stored.duplicate(true)
	player["position"] = Vector2i.ZERO
	player["alive"] = int(player.get("health", 1)) > 0
	if GameSession.state.inventory.is_empty():
		GameSession.state.inventory = [
			{"id": "weapon_club", "count": 1, "identified": true, "state": "ordinary"},
			{"id": "consumable_redroot_draught", "count": 2, "identified": true, "state": "ordinary"},
		]
	if GameSession.state.known_spells.is_empty():
		GameSession.state.known_spells = ["spell_coal_spark"]


func _enter_depth(new_depth: int) -> void:
	depth = new_depth
	var themes := ContentDB.all("themes")
	var theme: Dictionary = themes[depth % themes.size()] if not themes.is_empty() else {"id": "theme_unknown", "name": "Unknown Vault"}
	var generator := DungeonGenerator.new()
	level = generator.generate(int(GameSession.state.seed) + depth * 104729, theme.id, depth)
	if level.is_empty():
		push_error("Dungeon generation failed")
		return
	floor_texture = load(theme.floor_tile)
	wall_texture = load(theme.wall_tile)
	AudioDirector.play_music(theme.ambient_track)
	player.position = level.start
	enemies.clear()
	var rooms: Array = level.rooms
	var enemy_limit := 5 if GameSession.state.difficulty == "story" else (8 if GameSession.state.difficulty == "grim" else 7)
	for i in range(1, mini(rooms.size() - 1, enemy_limit)):
		var definition: Dictionary = enemy_catalog[(depth * 4 + i) % enemy_catalog.size()]
		var stats: Dictionary = definition.stats
		var max_health := int(stats.health)
		enemies.append({
			"id": "%s_%d" % [definition.id, i], "definition_id": definition.id, "name": definition.name,
			"position": rooms[i].position + rooms[i].size / 2, "home": rooms[i].position + rooms[i].size / 2,
			"health": max_health, "max_health": max_health, "armor": 1 + depth / 4,
			"accuracy": int(stats.accuracy), "evasion": int(stats.evasion), "might": int(stats.might),
			"speed": int(stats.speed), "resistances": definition.resistances,
			"vision": int(definition.perception.vision), "hearing": int(definition.perception.hearing),
			"archetype": definition.ai_archetype, "reach": 1, "range": 6,
			"state": "idle", "last_known": Vector2i.ZERO, "memory_turns": 0, "alive": true,
		})
	var npc_definitions := ContentDB.all("npcs")
	var npc_definition: Dictionary = npc_definitions[(depth * 3 + 5) % npc_definitions.size()]
	var npc_position: Vector2i = level.start
	for direction: Vector2i in GridPathfinder.DIRECTIONS:
		var candidate: Vector2i = level.start + direction
		if GridPathfinder.is_walkable(level.tiles, candidate) and _enemy_at(candidate) < 0:
			npc_position = candidate
			break
	npc = {
		"definition_id": npc_definition.id, "name": npc_definition.name,
		"role": npc_definition.role, "position": npc_position,
		"sprite": npc_definition.sprite, "portrait": npc_definition.portrait,
		"activity": _scheduled_activity(npc_definition)
	}
	GameSession.state.world.floor = depth
	GameSession.state.world.location = theme.id
	_recalculate_visibility()
	_log("[color=#e0bd76]Entered %s[/color] — depth %d — seed %d" % [theme.name, depth + 1, int(level.seed)])
	_advance_campaign_for_depth()
	_unlock_practice_spell()
	if GameSession.state.difficulty == "story" and depth > 0:
		player.health = mini(int(player.max_health), int(player.health) + int(player.max_health) / 3)
		player.mana = mini(int(player.max_mana), int(player.mana) + int(player.max_mana) / 3)
	_update_hud()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover_tile = screen_to_grid(event.position)
		queue_redraw()
		return
	if not event.is_pressed() or event.is_echo():
		return
	if modal.visible:
		if event.is_action_pressed("ui_cancel"):
			modal.visible = false
		return
	if event.is_action_pressed("ui_cancel"):
		_show_pause()
		return
	if event.is_action_pressed("inventory"):
		_show_inventory()
		return
	if event.is_action_pressed("spellbook"):
		_show_spellbook()
		return
	if event.is_action_pressed("journal"):
		_show_journal()
		return
	if event.is_action_pressed("map"):
		_show_map_help()
		return
	if event.is_action_pressed("search"):
		_search()
		return
	if event.is_action_pressed("interact"):
		_interact()
		return
	if event.is_action_pressed("quick_save"):
		_save()
		return
	if event.is_action_pressed("quick_load"):
		_load()
		return
	if event.is_action_pressed("screenshot_mode"):
		screenshot_mode = not screenshot_mode
		for child in get_children():
			if child != modal:
				child.visible = not screenshot_mode
		queue_redraw()
		return
	if event.is_action_pressed("toggle_overlay"):
		debug_enabled = not debug_enabled
		_update_hud()
		return
	if event is InputEventKey and event.physical_keycode == KEY_1:
		_cast_first_spell()
		return
	if event is InputEventKey and event.physical_keycode == KEY_2:
		_ranged_attack()
		return
	if event is InputEventKey and event.physical_keycode == KEY_3:
		_use_first_consumable()
		return
	var direction := Vector2i.ZERO
	if event.is_action_pressed("move_north"): direction = Vector2i(0, -1)
	elif event.is_action_pressed("move_south"): direction = Vector2i(0, 1)
	elif event.is_action_pressed("move_west"): direction = Vector2i(-1, 0)
	elif event.is_action_pressed("move_east"): direction = Vector2i(1, 0)
	elif event.is_action_pressed("move_northwest"): direction = Vector2i(-1, -1)
	elif event.is_action_pressed("move_northeast"): direction = Vector2i(1, -1)
	elif event.is_action_pressed("move_southwest"): direction = Vector2i(-1, 1)
	elif event.is_action_pressed("move_southeast"): direction = Vector2i(1, 1)
	elif event.is_action_pressed("wait_turn"):
		_finish_player_action(0)
		return
	if direction != Vector2i.ZERO:
		_try_move(direction)


func _try_move(direction: Vector2i) -> void:
	if not bool(player.alive):
		return
	var target: Vector2i = player.position + direction
	if direction.x != 0 and direction.y != 0:
		if not GridPathfinder.is_walkable(level.tiles, player.position + Vector2i(direction.x, 0)) or not GridPathfinder.is_walkable(level.tiles, player.position + Vector2i(0, direction.y)):
			_log("The corner is too tight to pass.")
			return
	var enemy_index := _enemy_at(target)
	if enemy_index >= 0:
		_melee_attack(enemy_index)
		return
	if not GridPathfinder.is_walkable(level.tiles, target):
		_log("Stone and old mortar bar the way.")
		return
	player.position = target
	var noise := 1
	for object: Dictionary in level.objects:
		if object.position == target and object.type == "trap" and bool(object.hidden) and not bool(object.disarmed):
			var trap_damage := 3 + depth
			player.health = maxi(0, int(player.health) - trap_damage)
			player.alive = int(player.health) > 0
			object.hidden = false
			_log("[color=#e88768]A hidden trap deals %d damage![/color]" % trap_damage)
			noise = 3
	if target == level.exit:
		_log("Stairs lead onward. Press F to descend.")
	_finish_player_action(noise)


func _melee_attack(enemy_index: int) -> void:
	var weapon: Dictionary = item_catalog.get(_equipped_weapon_id(), item_catalog.get("weapon_club", {"damage": [1, 4], "damage_type": "crush"}))
	var result := CombatRules.attack(player, enemies[enemy_index], weapon, _next_seed())
	AudioDirector.play_sfx("res://assets/sounds/weapons/blade_hit.wav" if result.hit else "res://assets/sounds/weapons/blade_swing.wav")
	if result.hit:
		enemies[enemy_index] = CombatRules.apply_damage(enemies[enemy_index], result)
		_log("You hit %s for [color=#f1c574]%d %s[/color]%s." % [
			enemies[enemy_index].name, int(result.damage), result.damage_type,
			" — critical!" if result.critical else ""
		])
		if not bool(enemies[enemy_index].alive):
			_log("[color=#a8d49d]%s falls.[/color]" % enemies[enemy_index].name)
			_gain_xp(8 + depth * 3)
	else:
		_log("You miss %s (%d%% chance)." % [enemies[enemy_index].name, int(result.accuracy)])
	_finish_player_action(4)


func _cast_first_spell() -> void:
	var known: Array = GameSession.state.known_spells
	if known.is_empty():
		_log("You know no working yet.")
		return
	var spell: Dictionary = spell_catalog.get(known[0], {})
	if spell.is_empty():
		return
	if int(player.mana) < int(spell.mana_cost):
		_log("You lack the focus for %s." % spell.name)
		return
	var target_index := _nearest_visible_enemy(int(spell.range))
	if target_index < 0:
		_log("No hostile lies within %s's reach." % spell.name)
		return
	player.mana = int(player.mana) - int(spell.mana_cost)
	var result := CombatRules.spell_damage(player, enemies[target_index], spell, _next_seed())
	AudioDirector.play_sfx(spell.sfx)
	effect_state = {
		"texture": _texture(spell.vfx), "position": enemies[target_index].position,
		"frame": 0, "started": Time.get_ticks_msec()
	}
	enemies[target_index] = CombatRules.apply_damage(enemies[target_index], result)
	_log("[color=#9ed8e3]%s[/color] strikes %s for %d %s." % [spell.name, enemies[target_index].name, int(result.damage), result.damage_type])
	if not bool(enemies[target_index].alive):
		_log("[color=#a8d49d]%s dissolves into the vault's quiet.[/color]" % enemies[target_index].name)
		_gain_xp(10 + depth * 3)
	_finish_player_action(5)


func _ranged_attack() -> void:
	var weapon: Dictionary = item_catalog.get(_equipped_weapon_id(), {})
	if int(weapon.get("range", 1)) <= 1:
		_log("Equip a ranged weapon before making a ranged attack.")
		return
	var target_index := _nearest_visible_enemy(int(weapon.range))
	if target_index < 0:
		_log("No hostile is within the weapon's range.")
		return
	var result := CombatRules.attack(player, enemies[target_index], weapon, _next_seed())
	AudioDirector.play_sfx("res://assets/sounds/weapons/bow_hit.wav" if result.hit else "res://assets/sounds/weapons/bow_swing.wav")
	if result.hit:
		enemies[target_index] = CombatRules.apply_damage(enemies[target_index], result)
		_log("Your shot hits %s for %d %s." % [enemies[target_index].name, int(result.damage), result.damage_type])
		if not bool(enemies[target_index].alive):
			_gain_xp(8 + depth * 3)
	else:
		_log("Your shot misses %s." % enemies[target_index].name)
	_finish_player_action(4)


func _use_first_consumable() -> void:
	for index in range(GameSession.state.inventory.size()):
		var definition: Dictionary = item_catalog.get(GameSession.state.inventory[index].id, {})
		if definition.get("category") == "consumable":
			_use_item(index)
			return
	_log("No consumable is ready.")


func _finish_player_action(noise: int) -> void:
	GameSession.state.world.turn = int(GameSession.state.world.turn) + 1
	_run_enemy_turns(noise)
	_recalculate_visibility()
	_update_hud()
	queue_redraw()
	if not bool(player.alive):
		_show_game_over()


func _run_enemy_turns(noise: int) -> void:
	for index in range(enemies.size()):
		if not bool(enemies[index].alive):
			continue
		enemies[index] = AIPlanner.update_awareness(enemies[index], player.position, level.tiles, noise)
		var occupied: Dictionary = {}
		for other: Dictionary in enemies:
			if bool(other.alive) and other.id != enemies[index].id:
				occupied[other.position] = true
		var action := AIPlanner.choose_action(enemies[index], player, level.tiles, occupied)
		match action.type:
			"move", "retreat":
				if not occupied.has(action.target) and action.target != player.position:
					enemies[index].position = action.target
			"attack":
				var claw := {"damage": [2 + depth / 3, 5 + depth / 2], "damage_type": "crush"}
				var result := CombatRules.attack(enemies[index], player, claw, _next_seed())
				if result.hit:
					AudioDirector.play_sfx("res://assets/sounds/armor/impact_leather.wav", 0.92 + index * 0.015)
					var adjusted := result.duplicate(true)
					if GameSession.state.difficulty == "story":
						adjusted.damage = maxi(1, int(result.damage * 0.72))
					elif GameSession.state.difficulty == "grim":
						adjusted.damage = maxi(1, int(ceil(result.damage * 1.18)))
					player = CombatRules.apply_damage(player, adjusted)
					_log("[color=#e88768]%s hits you for %d.[/color]" % [enemies[index].name, int(adjusted.damage)])
				else:
					_log("%s's attack passes wide." % enemies[index].name)
			"ability":
				var damage := 2 + depth / 2
				player.health = maxi(0, int(player.health) - damage)
				player.alive = int(player.health) > 0
				_log("[color=#d894db]%s uses a ranged working for %d.[/color]" % [enemies[index].name, damage])


func _search() -> void:
	var found := 0
	for object: Dictionary in level.objects:
		if object.position.distance_squared_to(player.position) <= 9 and bool(object.get("hidden", false)):
			object.hidden = false
			found += 1
	if found:
		_log("[color=#a8d49d]You reveal %d hidden danger%s.[/color]" % [found, "" if found == 1 else "s"])
	else:
		_log("You notice dust, drafts, and nothing eager to be found.")
	_finish_player_action(1)


func _interact() -> void:
	if not npc.is_empty() and npc.position.distance_squared_to(player.position) <= 2:
		_show_dialogue(npc.definition_id, "dialogue_%s_00" % npc.definition_id)
		return
	if player.position == level.exit:
		if depth >= 11:
			_show_ending()
		else:
			_enter_depth(depth + 1)
		return
	for object: Dictionary in level.objects:
		if object.position.distance_squared_to(player.position) > 2:
			continue
		if object.type == "chest" and not bool(object.opened):
			object.opened = true
			AudioDirector.play_sfx("res://assets/sounds/environment/chest_open.wav")
			var item: Dictionary = ContentDB.all("items")[(depth * 17 + int(GameSession.state.world.turn)) % ContentDB.all("items").size()]
			GameSession.state.inventory = InventoryRules.add_item(GameSession.state.inventory, item.id, 1, item_catalog)
			_log("[color=#e0bd76]Chest opened: %s.[/color]" % item.name)
			_finish_player_action(2)
			return
		if object.type == "key" and not bool(object.taken):
			object.taken = true
			GameSession.state.flags["has_floor_key_%d" % depth] = true
			_log("You take the floor's iron key.")
			_finish_player_action(1)
			return
		if object.type == "locked_door" and bool(object.locked):
			if bool(GameSession.state.flags.get("has_floor_key_%d" % depth, false)):
				object.locked = false
				_log("[color=#a8d49d]The floor key turns. The old lock yields.[/color]")
				AudioDirector.play_sfx("res://assets/sounds/environment/door_open.wav")
			else:
				_log("The door is locked. Its key must be somewhere on this floor.")
			_finish_player_action(1)
			return
		if object.type == "secret_door" and not bool(object.hidden) and not bool(object.opened):
			object.opened = true
			_log("[color=#a8d49d]A hidden seam opens into a narrow treasure recess.[/color]")
			_finish_player_action(1)
			return
	_log("Nothing nearby answers your hand.")


func _save() -> void:
	GameSession.state.player = _serializable_player()
	var error := SaveService.save_slot(0, GameSession.serialize())
	AudioDirector.play_sfx("res://assets/sounds/ui/save.wav")
	_log("[color=#a8d49d]Journey saved atomically.[/color]" if error == OK else "[color=#e88768]Save failed: %s[/color]" % error_string(error))
	_update_hud()


func _load() -> void:
	var loaded := SaveService.load_slot(0)
	if loaded.is_empty():
		_log("No valid autosave or backup was found.")
		return
	GameSession.restore(loaded)
	AudioDirector.play_sfx("res://assets/sounds/ui/load.wav")
	_restore_or_start()
	_enter_depth(int(loaded.get("world", {}).get("floor", 0)))
	_log("[color=#a8d49d]Journey restored.[/color]")


func _serializable_player() -> Dictionary:
	var saved := player.duplicate(true)
	saved.erase("position")
	return saved


func _equipped_weapon_id() -> String:
	return String(GameSession.state.equipment.get("main_hand", "weapon_club"))


func _gain_xp(amount: int) -> void:
	player.xp = int(player.get("xp", 0)) + amount
	var threshold := int(player.get("level", 1)) * 40
	if int(player.xp) >= threshold:
		player.xp = int(player.xp) - threshold
		player.level = int(player.level) + 1
		player.max_health = int(player.max_health) + 5
		player.health = int(player.max_health)
		player.max_mana = int(player.max_mana) + 3
		player.mana = int(player.max_mana)
		player.might = int(player.might) + (1 if int(player.level) % 2 == 0 else 0)
		_log("[color=#e0bd76][b]Level %d![/b] Your road grows wider.[/color]" % int(player.level))


func _enemy_at(position: Vector2i) -> int:
	for i in range(enemies.size()):
		if bool(enemies[i].alive) and enemies[i].position == position:
			return i
	return -1


func _nearest_visible_enemy(max_range: int) -> int:
	var best := -1
	var best_distance := 999
	for i in range(enemies.size()):
		if not bool(enemies[i].alive) or not visible_tiles.has(enemies[i].position):
			continue
		var distance := maxi(absi(enemies[i].position.x - player.position.x), absi(enemies[i].position.y - player.position.y))
		if distance <= max_range and distance < best_distance:
			best = i
			best_distance = distance
	return best


func _recalculate_visibility() -> void:
	visible_tiles.clear()
	for y in range(maxi(0, player.position.y - 8), mini(int(level.height), player.position.y + 9)):
		for x in range(maxi(0, player.position.x - 8), mini(int(level.width), player.position.x + 9)):
			var position := Vector2i(x, y)
			if player.position.distance_squared_to(position) <= 64 and GridPathfinder.line_of_sight(level.tiles, player.position, position):
				visible_tiles[position] = true
				discovered[position] = true


func _next_seed() -> int:
	turn_seed += 1
	return int(GameSession.state.seed) + int(GameSession.state.world.turn) * 1009 + turn_seed


func _log(message: String) -> void:
	combat_log.append(message)
	if combat_log.size() > 14:
		combat_log.remove_at(0)
	if log_label:
		log_label.text = "[b]EVENTS[/b]\n\n" + "\n".join(combat_log)


func _update_hud() -> void:
	if hud_label == null:
		return
	var quest_state: Dictionary = GameSession.state.quests.get("quest_homecoming_in_iron", GameSession.state.quests.get("homecoming", {"state": "active"}))
	hud_label.text = (
		"[font_size=24][color=#f1e3c4]%s[/color][/font_size]\n%s • level %d\n\n" +
		"[color=#d96f62]HEALTH[/color]  %d / %d\n[color=#78b8d8]FOCUS[/color]   %d / %d\n" +
		"Armor %d  •  Evasion %d\nMight %d  •  Finesse %d  •  Resolve %d\n\n" +
		"Depth %d / 12\nTurn %d  •  Seed %d\nSilver %d\n\n[b]Current thread[/b]\nHomecoming in Iron — %s"
	) % [
		player.get("name", "Wayfarer"), player.get("background", "Returned Apprentice"), int(player.get("level", 1)),
		int(player.health), int(player.max_health), int(player.mana), int(player.max_mana),
		int(player.armor), int(player.evasion), int(player.might), int(player.finesse), int(player.resolve),
		depth + 1, int(GameSession.state.world.turn), int(GameSession.state.seed), int(player.get("silver", 0)),
		String(quest_state.get("state", "active")).capitalize(),
	]
	if debug_enabled:
		hud_label.text += "\n\n[color=#9ed8e3][b]DEVELOPER OVERLAY[/b][/color]\nFPS %d • actors %d\nVisible %d • discovered %d\nMap attempt %d • objects %d\nDraw calls %d" % [
			Engine.get_frames_per_second(), enemies.size() + 2, visible_tiles.size(), discovered.size(),
			int(level.get("attempt", 0)), level.get("objects", []).size(),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		]


func _show_inventory() -> void:
	var lines := PackedStringArray()
	var index := 1
	for stack: Dictionary in GameSession.state.inventory:
		var item: Dictionary = item_catalog.get(stack.id, {"name": stack.id, "weight": 0.0, "description": ""})
		lines.append("[img=48x48]%s[/img] %d. [color=#e0bd76]%s[/color] ×%d  (%.2f weight)\n   %s" % [item.icon, index, item.name, int(stack.count), float(item.weight) * int(stack.count), item.description])
		index += 1
	var weight := InventoryRules.total_weight(GameSession.state.inventory, item_catalog)
	_show_modal("Inventory & Equipment", "Carried weight: %.2f / %d\nMain hand: %s\n\n%s" % [weight, 22 + int(player.might) * 4, item_catalog.get(_equipped_weapon_id(), {"name": "Hands"}).name, "\n\n".join(lines)])
	for stack_index in range(GameSession.state.inventory.size()):
		var stack: Dictionary = GameSession.state.inventory[stack_index]
		var definition: Dictionary = item_catalog.get(stack.id, {})
		if definition.get("slot", "") != "":
			_add_modal_action("Equip %s" % definition.name, func() -> void: _equip_item(stack_index))
		elif definition.get("category") == "consumable":
			_add_modal_action("Use %s" % definition.name, func() -> void: _use_item(stack_index))


func _show_spellbook() -> void:
	var lines := PackedStringArray()
	for spell_id: String in GameSession.state.known_spells:
		var spell: Dictionary = spell_catalog.get(spell_id, {})
		if not spell.is_empty():
			lines.append("[color=#9ed8e3]%s[/color] — %s\nFocus %d • range %d • %s • power %d" % [spell.name, spell.discipline.capitalize(), int(spell.mana_cost), int(spell.range), spell.shape, int(spell.power)])
	_show_modal("The Eight Practices", "\n\n".join(lines) + "\n\nPress 1 in the world to cast the first prepared working.")
	for spell_id: String in GameSession.state.known_spells:
		var spell: Dictionary = spell_catalog.get(spell_id, {})
		if not spell.is_empty():
			_add_modal_action("Prepare %s" % spell.name, func() -> void: _prepare_spell(spell_id))


func _prepare_spell(spell_id: String) -> void:
	var known: Array = GameSession.state.known_spells
	var index := known.find(spell_id)
	if index >= 0:
		known.remove_at(index)
		known.push_front(spell_id)
		AudioDirector.play_sfx("res://assets/sounds/ui/confirm.wav")
		_log("Prepared %s." % spell_catalog[spell_id].name)
	modal.visible = false


func _show_journal() -> void:
	var lines := PackedStringArray()
	for quest: Dictionary in ContentDB.all("quests").slice(0, 8):
		var state: Dictionary = GameSession.state.quests.get(quest.id, {})
		lines.append("[color=#e0bd76]%s[/color]\n%s%s" % [quest.name, quest.summary, "\nState: " + String(state.get("state", "not begun")) if not state.is_empty() else ""])
	_show_modal("Quest Journal", "\n\n".join(lines))


func _show_map_help() -> void:
	_show_modal("Map & Legend", "Gold stair: transition • red mark: hostile • pale blue figure: you • amber square: chest • violet mark: trap or secret\n\nDiscovered tiles remain on the map while current line of sight is brightly lit. Procedural floors are replayable from seed %d." % int(GameSession.state.seed))


func _show_modal(title_text: String, body_text: String) -> void:
	for child in modal_actions.get_children():
		child.queue_free()
	modal_title.text = title_text
	modal_body.text = body_text
	modal.visible = true


func _add_modal_action(text_value: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 34
	button.pressed.connect(callback)
	modal_actions.add_child(button)


func _equip_item(stack_index: int) -> void:
	if stack_index < 0 or stack_index >= GameSession.state.inventory.size():
		return
	var stack: Dictionary = GameSession.state.inventory[stack_index]
	var definition: Dictionary = item_catalog.get(stack.id, {})
	var check := InventoryRules.can_equip(player, definition)
	if not check.ok:
		_log(check.reason)
		return
	GameSession.state.equipment[definition.slot] = definition.id
	if definition.has("armor"):
		player.armor = maxi(0, int(definition.armor))
	AudioDirector.play_sfx("res://assets/sounds/ui/equip.wav")
	_log("[color=#a8d49d]Equipped %s.[/color]" % definition.name)
	_show_inventory()


func _use_item(stack_index: int) -> void:
	if stack_index < 0 or stack_index >= GameSession.state.inventory.size():
		return
	var stack: Dictionary = GameSession.state.inventory[stack_index]
	var definition: Dictionary = item_catalog.get(stack.id, {})
	var effect: Dictionary = definition.get("effect", {})
	match effect.get("type", ""):
		"heal":
			player.health = mini(int(player.max_health), int(player.health) + int(effect.get("amount", 0)))
		"mana":
			player.mana = mini(int(player.max_mana), int(player.mana) + int(effect.get("amount", 0)))
		_:
			player.statuses.append({"id": effect.get("type", "nourished"), "duration": 5, "amount": effect.get("amount", 1)})
	GameSession.state.inventory = InventoryRules.remove_item(GameSession.state.inventory, definition.id, 1)
	AudioDirector.play_sfx("res://assets/sounds/environment/potion.wav")
	_log("Used %s." % definition.name)
	modal.visible = false
	_finish_player_action(1)


func _show_dialogue(npc_id: String, node_id: String) -> void:
	var definition := ContentDB.get_entry("npcs", npc_id)
	var node := ContentDB.get_entry("dialogue", node_id)
	if definition.is_empty() or node.is_empty():
		_log("They have nothing to say just now.")
		return
	GameSession.state.flags["met_%s" % npc_id] = true
	_show_modal(definition.name, "[img=96x120]%s[/img]\n[color=#9ed8e3]%s[/color]\n\n%s\n\n[i]%s[/i]" % [
		definition.portrait, definition.role.capitalize(), node.text.trim_prefix(definition.name + ": "), definition.voice
	])
	for choice: Dictionary in node.choices:
		var next_id: String = choice.next
		_add_modal_action(choice.text, func() -> void:
			if next_id.is_empty():
				modal.visible = false
			else:
				_show_dialogue(npc_id, next_id)
		)
	if definition.role in ["merchant", "smith", "healer", "lockwright", "spell teacher"]:
		_add_modal_action("Ask about services", func() -> void: _show_merchant(definition))


func _show_merchant(definition: Dictionary) -> void:
	var stock: Array[Dictionary] = []
	for offset in range(6):
		stock.append(ContentDB.all("items")[(depth * 13 + offset * 17) % ContentDB.all("items").size()])
	var lines := PackedStringArray(["%s has arranged a small, useful stock. Your silver: %d" % [definition.name, int(player.silver)]])
	for item: Dictionary in stock:
		lines.append("[img=40x40]%s[/img] [color=#e0bd76]%s[/color] — %d silver" % [item.icon, item.name, InventoryRules.merchant_price(item, 0, true)])
	_show_modal("Trade — %s" % definition.name, "\n\n".join(lines))
	for item: Dictionary in stock:
		var price := InventoryRules.merchant_price(item, 0, true)
		_add_modal_action("Buy %s — %d silver" % [item.name, price], func() -> void:
			if int(player.silver) < price:
				_log("You cannot afford %s." % item.name)
				return
			player.silver = int(player.silver) - price
			GameSession.state.inventory = InventoryRules.add_item(GameSession.state.inventory, item.id, 1, item_catalog)
			AudioDirector.play_sfx("res://assets/sounds/ui/coins.wav")
			_log("Bought %s for %d silver." % [item.name, price])
			_show_merchant(definition)
		)
	for stack_index in range(GameSession.state.inventory.size()):
		var stack: Dictionary = GameSession.state.inventory[stack_index]
		var owned: Dictionary = item_catalog.get(stack.id, {})
		if owned.get("rarity") not in ["quest", "artifact"]:
			var sell_price := InventoryRules.merchant_price(owned, 0, false)
			_add_modal_action("Sell %s — %d silver" % [owned.name, sell_price], func() -> void:
				GameSession.state.inventory = InventoryRules.remove_item(GameSession.state.inventory, owned.id, 1)
				player.silver = int(player.silver) + sell_price
				AudioDirector.play_sfx("res://assets/sounds/ui/coins.wav")
				_log("Sold %s for %d silver." % [owned.name, sell_price])
				_show_merchant(definition)
			)
			break


func _show_pause() -> void:
	_show_modal("Journey Paused", "The tactical world waits without advancing a turn.\n\nManual slots are independent from the slot-1 quick save.")
	for slot in range(SaveService.SLOT_COUNT):
		_add_modal_action("Save to slot %d" % (slot + 1), func() -> void:
			GameSession.state.player = _serializable_player()
			var error := SaveService.save_slot(slot, GameSession.serialize())
			_log("Saved to slot %d." % (slot + 1) if error == OK else "Save failed.")
			modal.visible = false
		)
	_add_modal_action("Return to title", func() -> void:
		AudioDirector.play_music("res://assets/music/theme_00.wav")
		return_to_menu.emit()
	)


func _advance_campaign_for_depth() -> void:
	var main_quests: Array = ContentDB.all("quests").filter(func(quest: Dictionary) -> bool: return quest.type == "main")
	var quest_index := mini(main_quests.size() - 1, int(floori(depth * main_quests.size() / 12.0)))
	for index in range(quest_index):
		GameSession.state.quests[main_quests[index].id] = {"state": "complete", "stage": main_quests[index].stages.size(), "progress": 0, "choices": []}
	var current: Dictionary = main_quests[quest_index]
	if not GameSession.state.quests.has(current.id):
		GameSession.state.quests[current.id] = {"state": "active", "stage": 0, "progress": 0, "choices": []}
	if depth == 4:
		_show_modal("ACT II — WINTER OWES A DEBT", "Beyond the Underbell, falling snow stops in midair. Maelin's trail crosses the Lorn Shelf, and something there has learned to preserve a moment by killing everything that might change it.")
	elif depth == 8:
		_show_modal("ACT III — THE COUNTERWEIGHT ROAD", "The three tuning names open a road that climbs as often as it descends. Above the clouds, Rime-Crown holds the Bell's counterweight—and Maelin's unfinished answer.")


func _unlock_practice_spell() -> void:
	var practice: String = player.get("practice", "cinderweave")
	var practice_spells: Array = ContentDB.all("spells").filter(func(spell: Dictionary) -> bool: return spell.discipline == practice)
	practice_spells.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.rank) < int(b.rank))
	var unlocked_rank := mini(6, 1 + depth / 2)
	for spell: Dictionary in practice_spells:
		if int(spell.rank) <= unlocked_rank and not GameSession.state.known_spells.has(spell.id):
			GameSession.state.known_spells.append(spell.id)
			_log("[color=#9ed8e3]You understand a new working: %s.[/color]" % spell.name)


func _scheduled_activity(definition: Dictionary) -> String:
	var hour := int(GameSession.state.world.turn / 10) % 24
	var activity := "sleep"
	for entry: Dictionary in definition.schedule:
		if hour >= int(entry.start):
			activity = entry.activity
	return activity


func _show_game_over() -> void:
	_show_modal("The Road Ends Here", "The Bell continues beneath the snow. Load your last atomic save with F6 after closing this panel, or return to the title with Escape.")


func _show_ending() -> void:
	_show_modal("THE BELL'S LAST QUESTION", "The Tallyman releases the counterweight. Every borrowed grief rises around you as light, each one waiting for an answer no machine can give.\n\nWhat should the Bell become?")
	_add_modal_action("Silence it and return every private grief", func() -> void: _finish_ending("quiet"))
	_add_modal_action("Retune it as a consensual shared archive", func() -> void: _finish_ending("archive"))
	_add_modal_action("Break its housing and free the Choir", func() -> void: _finish_ending("free"))


func _finish_ending(ending_id: String) -> void:
	var endings := {
		"quiet": ["THE QUIET ENDING", "The Bell falls silent. Stolen sorrow returns to its owners as rain returns to a river. Maelin survives, but forgets the road that brought you both here."],
		"archive": ["THE SHARED ARCHIVE", "Every memory chooses its keeper. Little Ash hears rain without borrowing anyone else's ears. Greywake appoints witnesses instead of wardens."],
		"free": ["THE FREE CHOIR", "The housing breaks. A thousand voices depart into stone, storm, moth, and flame. Magic becomes stranger, but no mind below the mountain is property again."],
	}
	GameSession.state.flags["campaign_complete"] = true
	GameSession.state.flags["ending"] = ending_id
	GameSession.state.world.location = "postgame_greywake"
	var ending: Array = endings[ending_id]
	_show_modal(ending[0], "%s\n\nMaelin laughs once, exhausted. The Bell sounds a final, human note.\n\nCAMPAIGN COMPLETE\nSeed %d • Turns %d\n\nThe post-game returns to a changed Greywake, and this seed remains available for another journey." % [ending[1], int(GameSession.state.seed), int(GameSession.state.world.turn)])
	AudioDirector.play_music("res://assets/music/theme_10.wav")
	SaveService.save_slot(0, GameSession.serialize())


func grid_to_screen(grid: Vector2i) -> Vector2:
	return VIEW_ORIGIN + Vector2((grid.x - grid.y) * TILE_WIDTH * 0.5, (grid.x + grid.y) * TILE_HEIGHT * 0.5)


func screen_to_grid(screen: Vector2) -> Vector2i:
	var local := screen - VIEW_ORIGIN
	var x := local.x / TILE_WIDTH + local.y / TILE_HEIGHT
	var y := local.y / TILE_HEIGHT - local.x / TILE_WIDTH
	return Vector2i(roundi(x), roundi(y))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#07101a"))
	if level.is_empty():
		return
	var theme_index := depth % 12
	var floor_palette := [
		Color("#53614c"), Color("#554d45"), Color("#395c64"), Color("#60768a"),
		Color("#405a40"), Color("#5a5346"), Color("#514b60"), Color("#42624e"),
		Color("#704537"), Color("#4d506e"), Color("#4d6377"), Color("#493f58")
	]
	var floor_color: Color = floor_palette[theme_index]
	for y in range(int(level.height)):
		for x in range(int(level.width)):
			var position := Vector2i(x, y)
			if not discovered.has(position):
				continue
			var tile: String = level.tiles[y][x]
			if tile == "wall" and not _wall_visible(position):
				continue
			var center := grid_to_screen(position)
			var light := 1.0 if visible_tiles.has(position) else 0.38
			var color := floor_color * light
			var diamond := PackedVector2Array([
				center + Vector2(0, -TILE_HEIGHT * 0.5), center + Vector2(TILE_WIDTH * 0.5, 0),
				center + Vector2(0, TILE_HEIGHT * 0.5), center + Vector2(-TILE_WIDTH * 0.5, 0)
			])
			if tile == "wall":
				if wall_texture:
					draw_texture_rect(wall_texture, Rect2(center - Vector2(20, 39), Vector2(40, 40)), false, Color(light, light, light, 1))
			else:
				if tile == "stairs": color = Color("#a78043") * light
				elif tile == "water": color = Color("#2f6475") * light
				elif tile == "ice": color = Color("#91bec7") * light
				if floor_texture:
					draw_texture_rect(floor_texture, Rect2(center - Vector2(20, 10), Vector2(40, 20)), false, Color(light, light, light, 1))
				else:
					draw_colored_polygon(diamond, color)
				draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color("#1d2830") * light, 1.0)
			if position == hover_tile and visible_tiles.has(position):
				draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color("#f1d58e"), 2.0)
	for object: Dictionary in level.objects:
		if not visible_tiles.has(object.position) or bool(object.get("hidden", false)) or bool(object.get("taken", false)):
			continue
		var center := grid_to_screen(object.position)
		if object.type == "chest" and not bool(object.opened):
			var chest_texture := _texture("res://assets/sprites/objects/chest.png")
			draw_texture_rect_region(chest_texture, Rect2(center - Vector2(16, 40), Vector2(32, 40)), Rect2(0, 0, 64, 80))
		elif object.type == "trap":
			draw_circle(center - Vector2(0, 2), 5, Color("#a85d8b"))
		elif object.type == "key":
			draw_circle(center - Vector2(0, 5), 4, Color("#e0bd76"), false, 2)
	if visible_tiles.has(player.position):
		_draw_actor_sprite(grid_to_screen(player.position), "res://assets/sprites/player/player_%s.png" % player.get("portrait", "aurora"), true, bool(player.alive))
	for enemy: Dictionary in enemies:
		if bool(enemy.alive) and visible_tiles.has(enemy.position):
			var definition: Dictionary = ContentDB.get_entry("enemies", enemy.definition_id)
			_draw_actor_sprite(grid_to_screen(enemy.position), definition.get("sprite", ""), false, true)
	if not npc.is_empty() and visible_tiles.has(npc.position):
		_draw_actor_sprite(grid_to_screen(npc.position), npc.sprite, false, true)
	if not effect_state.is_empty():
		var effect_texture: Texture2D = effect_state.texture
		var effect_center := grid_to_screen(effect_state.position) - Vector2(0, 18)
		draw_texture_rect_region(effect_texture, Rect2(effect_center - Vector2(24, 24), Vector2(48, 48)), Rect2(int(effect_state.frame) * 64, 0, 64, 64))


func _draw_actor_sprite(foot: Vector2, path: String, is_player: bool, alive: bool) -> void:
	if not alive or path.is_empty() or not ResourceLoader.exists(path):
		_draw_actor(foot, Color("#a7d5dc") if is_player else Color("#c8685c"), is_player, alive)
		return
	var texture := _texture(path)
	var idle_frame := int(Time.get_ticks_msec() / 260) % 4
	draw_texture_rect_region(texture, Rect2(foot - Vector2(16, 40), Vector2(32, 40)), Rect2(idle_frame * 64, 0, 64, 80))


func _texture(path: String) -> Texture2D:
	if not texture_cache.has(path):
		texture_cache[path] = load(path)
	return texture_cache[path]


func _draw_actor(foot: Vector2, color: Color, is_player: bool, alive: bool) -> void:
	if not alive:
		_draw_flat_ellipse(foot - Vector2(0, 4), Vector2(13, 5), Color("#5c4750"))
		return
	_draw_flat_ellipse(foot + Vector2(2, 1), Vector2(11, 4), Color(0, 0, 0, 0.45))
	draw_colored_polygon(PackedVector2Array([
		foot + Vector2(-9, -4), foot + Vector2(-6, -24), foot + Vector2(0, -33),
		foot + Vector2(7, -24), foot + Vector2(10, -4), foot
	]), color)
	draw_circle(foot + Vector2(0, -34), 6, color.lightened(0.2))
	if is_player:
		draw_line(foot + Vector2(7, -24), foot + Vector2(14, -12), Color("#d7b36c"), 3)


func _draw_flat_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(20):
		var angle := TAU * i / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _wall_visible(position: Vector2i) -> bool:
	for direction: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nearby: Vector2i = position + direction
		if discovered.has(nearby) and GridPathfinder.is_walkable(level.tiles, nearby):
			return true
	return false
