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
	scene._on_settings()
	await process_frame
	if scene.find_child("OpenInputRemapping", true, false) == null:
		push_error("Settings did not expose input remapping")
		quit(1)
		return
	scene._show_input_settings()
	await process_frame
	var action_rows := scene.find_children("ActionRow_*", "HBoxContainer", true, false)
	if action_rows.size() != InputDefaults.ACTION_ORDER.size():
		push_error("Input editor did not render every remappable action")
		quit(1)
		return
	var binding_snapshot: Dictionary = root.get_node("SettingsService").input_bindings.serialized()
	scene._begin_capture("search", 0)
	var cancel_capture := InputEventKey.new()
	cancel_capture.physical_keycode = KEY_ESCAPE
	cancel_capture.pressed = true
	scene._unhandled_input(cancel_capture)
	if not scene.capture_action.is_empty() or root.get_node("SettingsService").input_bindings.serialized() != binding_snapshot:
		push_error("Input capture cancellation changed bindings")
		quit(1)
		return
	var remap_key := InputEventKey.new()
	remap_key.physical_keycode = KEY_G
	var remap_result: Dictionary = root.get_node("SettingsService").assign_binding("search", remap_key, 0)
	if not remap_result.ok or not InputMap.event_is_action(remap_key, "search"):
		push_error("Temporary keyboard remap did not reach InputMap")
		quit(1)
		return
	root.get_node("SettingsService").reset_action("search")
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
	var item_catalog: Dictionary = {}
	for item: Dictionary in root.get_node("ContentDB").all("items"):
		item_catalog[item.id] = item
	session.state.inventory = InventoryRules.add_item(session.state.inventory, "consumable_bluecap_tonic", 1, item_catalog)
	session.state.inventory = InventoryRules.add_item(session.state.inventory, "weapon_dagger", 1, item_catalog)
	var drag_units_before := _owned_units(session.state.inventory, session.state.equipment)
	var first_id: String = session.state.inventory[0].id
	var second_id: String = session.state.inventory[1].id
	game._show_inventory()
	await process_frame
	var first_slot := game.find_child("InventorySlot_00", true, false) as InventorySlot
	var second_slot := game.find_child("InventorySlot_01", true, false) as InventorySlot
	if first_slot == null or second_slot == null:
		push_error("Inventory drag slots did not render")
		quit(1)
		return
	var drag_data: Variant = first_slot._get_drag_data(Vector2(10, 10))
	if drag_data == null or not second_slot._can_drop_data(Vector2(10, 10), drag_data):
		push_error("Inventory UI rejected a valid swap drag")
		quit(1)
		return
	second_slot._drop_data(Vector2(10, 10), drag_data)
	if session.state.inventory[0].id != second_id or session.state.inventory[1].id != first_id:
		push_error("Inventory UI drag did not swap logical slots")
		quit(1)
		return
	await process_frame
	var dagger_index := -1
	for index in range(session.state.inventory.size()):
		if session.state.inventory[index].id == "weapon_dagger":
			dagger_index = index
			break
	var dagger_slot := game.find_child("InventorySlot_%02d" % dagger_index, true, false) as InventorySlot
	var hand_slot := game.find_child("EquipmentSlot_main_hand", true, false) as InventorySlot
	if dagger_slot == null or hand_slot == null:
		push_error("Inventory equipment drag targets did not render")
		quit(1)
		return
	var equip_drag: Variant = dagger_slot._get_drag_data(Vector2(10, 10))
	if not hand_slot._can_drop_data(Vector2(10, 10), equip_drag):
		push_error("Inventory UI rejected valid main-hand equipment")
		quit(1)
		return
	hand_slot._drop_data(Vector2(10, 10), equip_drag)
	if session.state.equipment.main_hand.id != "weapon_dagger":
		push_error("Inventory UI equipment drop did not replace main hand")
		quit(1)
		return
	if _owned_units(session.state.inventory, session.state.equipment) != drag_units_before:
		push_error("Inventory UI drag duplicated or lost an item")
		quit(1)
		return
	var cancel_snapshot: Array = session.state.inventory.duplicate(true)
	await process_frame
	var cancel_slot := game.find_child("InventorySlot_00", true, false) as InventorySlot
	if cancel_slot != null:
		cancel_slot._get_drag_data(Vector2(10, 10))
		game._notification(Control.NOTIFICATION_DRAG_END)
	if session.state.inventory != cancel_snapshot:
		push_error("Cancelled inventory drag changed state")
		quit(1)
		return
	game._close_modal()
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
	print("SMOKE PASS: menu, input editor/capture/remap, character, world, move, inventory UI drag/equip/cancel, pickup, combat, spell, save/load, level, quest")
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


func _owned_units(inventory: Array, equipment: Dictionary) -> int:
	var units := 0
	for stack: Dictionary in inventory:
		units += int(stack.get("count", 0))
	for slot: String in equipment:
		units += int(equipment[slot].get("count", 0))
	return units
