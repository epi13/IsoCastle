extends Control

var screen_root: Control
var status_label: Label
var name_input: LineEdit
var presentation_input: OptionButton
var portrait_input: OptionButton
var background_input: OptionButton
var practice_input: OptionButton
var kit_input: OptionButton
var difficulty_input: OptionButton
var seed_input: LineEdit
var capture_action := ""
var capture_index := -1
var capture_panel: PanelContainer
var pending_binding: Dictionary = {}


func _ready() -> void:
	set_process_unhandled_input(true)
	_build_shell()
	AudioDirector.play_music("res://assets/music/theme_00.wav", 0.1)
	show_title()


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("#07131f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var sky := TextureRect.new()
	sky.texture = load("res://assets/ui/title_background.png")
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	screen_root = Control.new()
	screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen_root)

	status_label = Label.new()
	status_label.text = "Godot 4.7.1 • deterministic seed 130713"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_color_override("font_color", Color("#91a9b7"))
	status_label.position = Vector2(820, 680)
	status_label.size = Vector2(430, 24)
	add_child(status_label)


func clear_screen() -> void:
	for child in screen_root.get_children():
		child.queue_free()


func show_title() -> void:
	clear_screen()
	status_label.visible = true
	var panel := VBoxContainer.new()
	panel.position = Vector2(100, 112)
	panel.size = Vector2(510, 520)
	panel.add_theme_constant_override("separation", 14)
	screen_root.add_child(panel)

	var eyebrow := Label.new()
	eyebrow.text = "A NORTHERN ISOMETRIC ROLE-PLAYING GAME"
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.add_theme_color_override("font_color", Color("#d6a85b"))
	panel.add_child(eyebrow)

	var title := TextureRect.new()
	title.texture = load("res://assets/ui/logo.png")
	title.custom_minimum_size = Vector2(500, 150)
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "THE BELL BELOW"
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color("#a9c8d1"))
	panel.add_child(subtitle)

	var rule := HSeparator.new()
	rule.custom_minimum_size.y = 22
	panel.add_child(rule)

	_add_menu_button(panel, "New Journey", _on_new_game)
	var continue_button := _add_menu_button(panel, "Continue", _on_continue)
	continue_button.disabled = not SaveService.has_slot(0)
	_add_menu_button(panel, "Load Game", _on_load)
	_add_menu_button(panel, "Settings & Accessibility", _on_settings)
	_add_menu_button(panel, "Credits", _on_credits)
	_add_menu_button(panel, "Quit", _on_quit)

	var flavor := Label.new()
	flavor.text = "When the iron rang, the winter answered."
	flavor.add_theme_font_size_override("font_size", 17)
	flavor.add_theme_color_override("font_color", Color("#9fb0b4"))
	flavor.position = Vector2(760, 558)
	flavor.size = Vector2(420, 42)
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(flavor)


func _add_menu_button(parent: Control, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(360, 46)
	button.add_theme_font_size_override("font_size", 19)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _show_message(title_text: String, body: String) -> void:
	clear_screen()
	var box := VBoxContainer.new()
	box.position = Vector2(260, 150)
	box.size = Vector2(760, 420)
	box.add_theme_constant_override("separation", 20)
	screen_root.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#f1e3c4"))
	box.add_child(title)
	var copy := Label.new()
	copy.text = body
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.custom_minimum_size = Vector2(700, 220)
	copy.add_theme_font_size_override("font_size", 20)
	box.add_child(copy)
	_add_menu_button(box, "Back", show_title)


func _on_new_game() -> void:
	_show_intro()


func _on_continue() -> void:
	var loaded := SaveService.load_slot(0)
	if loaded.is_empty():
		_show_message("No Journey Found", "No valid autosave or recovery backup is available.")
	else:
		GameSession.restore(loaded)
		_launch_game()


func _on_load() -> void:
	clear_screen()
	var box := VBoxContainer.new()
	box.position = Vector2(250, 110)
	box.size = Vector2(780, 530)
	box.add_theme_constant_override("separation", 14)
	screen_root.add_child(box)
	var title := Label.new()
	title.text = "LOAD JOURNEY"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#f1e3c4"))
	box.add_child(title)
	for slot in range(SaveService.SLOT_COUNT):
		var button := Button.new()
		button.custom_minimum_size = Vector2(700, 52)
		if SaveService.has_slot(slot):
			var metadata := SaveService.load_slot(slot)
			button.text = "Slot %d — %s — depth %d — seed %d" % [
				slot + 1, metadata.get("player", {}).get("name", "Unknown"),
				int(metadata.get("world", {}).get("floor", 0)) + 1, int(metadata.get("seed", 0))
			]
			button.pressed.connect(func() -> void:
				var loaded := SaveService.load_slot(slot)
				if not loaded.is_empty():
					GameSession.restore(loaded)
					_launch_game()
			)
		else:
			button.text = "Slot %d — Empty" % (slot + 1)
			button.disabled = true
		box.add_child(button)
	_add_menu_button(box, "Back", show_title)


func _on_settings() -> void:
	clear_screen()
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(220, 70)
	scroll.size = Vector2(840, 590)
	screen_root.add_child(scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(790, 780)
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	var title := Label.new()
	title.text = "SETTINGS & ACCESSIBILITY"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#f1e3c4"))
	box.add_child(title)
	for entry in [
		["Master volume", "master_volume"], ["Music volume", "music_volume"],
		["Ambience volume", "ambience_volume"], ["Effects volume", "effects_volume"],
		["Text scale", "text_scale"], ["UI scale", "ui_scale"],
		["Animation speed", "animation_speed"], ["Screen shake", "screen_shake"]
	]:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = entry[0]
		label.custom_minimum_size.x = 260
		var slider := HSlider.new()
		slider.min_value = 0.5 if entry[1] in ["text_scale", "ui_scale", "animation_speed"] else 0.0
		slider.max_value = 2.0 if entry[1] in ["text_scale", "ui_scale", "animation_speed"] else 1.0
		slider.step = 0.05
		slider.value = float(SettingsService.get_value(entry[1]))
		slider.custom_minimum_size.x = 430
		slider.value_changed.connect(func(value: float) -> void: SettingsService.set_value(entry[1], value))
		row.add_child(label)
		row.add_child(slider)
		box.add_child(row)
	for entry in [
		["High-contrast interface", "high_contrast"], ["Reduced motion", "reduced_motion"],
		["Reduced flashing", "reduced_flashing"], ["Highlight interactables", "highlight_interactables"],
		["Floating combat feedback", "floating_feedback"], ["Hold to confirm", "hold_to_confirm"],
		["Tutorial narration", "tutorial_enabled"]
	]:
		var toggle := CheckButton.new()
		toggle.text = entry[0]
		toggle.button_pressed = bool(SettingsService.get_value(entry[1]))
		toggle.toggled.connect(func(value: bool) -> void: SettingsService.set_value(entry[1], value))
		box.add_child(toggle)
	var input_button := _add_menu_button(box, "Input Remapping", _show_input_settings)
	input_button.name = "OpenInputRemapping"
	var back := _add_menu_button(box, "Save Settings & Back", func() -> void:
		var save_error: Error = SettingsService.save_settings()
		if save_error == OK:
			show_title()
		else:
			_show_message("Settings Not Saved", SettingsService.last_persistence_error)
	)
	back.custom_minimum_size.x = 500


func _show_input_settings(message: String = "") -> void:
	_cancel_capture(false)
	clear_screen()
	var page := VBoxContainer.new()
	page.position = Vector2(80, 34)
	page.size = Vector2(1120, 650)
	page.add_theme_constant_override("separation", 8)
	screen_root.add_child(page)
	var title := Label.new()
	title.text = "INPUT REMAPPING"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#f1e3c4"))
	page.add_child(title)
	var guidance := Label.new()
	guidance.text = message if not message.is_empty() else "Select a binding to replace it, or add another. Conflicts require confirmation. Menu navigation remains on protected UI controls."
	guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guidance.custom_minimum_size.y = 42
	guidance.add_theme_color_override("font_color", Color("#a9c8d1"))
	page.add_child(guidance)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1100, 505)
	page.add_child(scroll)
	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 1070
	actions.add_theme_constant_override("separation", 5)
	scroll.add_child(actions)
	for action: String in SettingsService.action_ids():
		var row := HBoxContainer.new()
		row.name = "ActionRow_%s" % action
		row.add_theme_constant_override("separation", 5)
		actions.add_child(row)
		var label := Label.new()
		label.text = SettingsService.action_label(action)
		label.custom_minimum_size = Vector2(190, 38)
		label.tooltip_text = action
		row.add_child(label)
		var bindings: Array = SettingsService.bindings_for(action)
		for binding_index in range(bindings.size()):
			var binding: Dictionary = bindings[binding_index]
			var binding_button := Button.new()
			binding_button.name = "Binding_%s_%d" % [action, binding_index]
			binding_button.text = InputBindings.display_name(binding)
			binding_button.custom_minimum_size = Vector2(126, 38)
			binding_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			binding_button.tooltip_text = "Replace %s" % InputBindings.display_name(binding)
			binding_button.pressed.connect(func() -> void: _begin_capture(action, binding_index))
			row.add_child(binding_button)
			var clear_button := Button.new()
			clear_button.name = "Clear_%s_%d" % [action, binding_index]
			clear_button.text = "×"
			clear_button.tooltip_text = "Clear this optional binding"
			clear_button.custom_minimum_size = Vector2(34, 38)
			clear_button.pressed.connect(func() -> void: _clear_input_binding(action, binding_index))
			row.add_child(clear_button)
		var add_button := Button.new()
		add_button.name = "AddBinding_%s" % action
		add_button.text = "+ Add"
		add_button.custom_minimum_size = Vector2(70, 38)
		add_button.pressed.connect(func() -> void: _begin_capture(action, -1))
		row.add_child(add_button)
		var reset_button := Button.new()
		reset_button.name = "ResetBinding_%s" % action
		reset_button.text = "Reset"
		reset_button.custom_minimum_size = Vector2(68, 38)
		reset_button.pressed.connect(func() -> void:
			SettingsService.reset_action(action)
			_show_input_settings("Reset %s to defaults." % SettingsService.action_label(action))
		)
		row.add_child(reset_button)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	page.add_child(footer)
	var reset_all := _add_menu_button(footer, "Reset All Defaults", _confirm_reset_all_bindings)
	reset_all.name = "ResetAllBindings"
	reset_all.custom_minimum_size = Vector2(260, 42)
	var back := _add_menu_button(footer, "Save & Return to Settings", func() -> void:
		var save_error: Error = SettingsService.save_settings()
		if save_error == OK:
			_on_settings()
		else:
			_show_input_settings(SettingsService.last_persistence_error)
	)
	back.name = "SaveInputBindings"
	back.custom_minimum_size = Vector2(330, 42)


func _begin_capture(action: String, binding_index: int) -> void:
	_cancel_capture(false)
	capture_action = action
	capture_index = binding_index
	capture_panel = PanelContainer.new()
	capture_panel.name = "InputCaptureOverlay"
	capture_panel.position = Vector2(250, 210)
	capture_panel.size = Vector2(780, 280)
	capture_panel.z_index = 200
	screen_root.add_child(capture_panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	capture_panel.add_child(box)
	var title := Label.new()
	title.text = "LISTENING FOR %s" % SettingsService.action_label(action).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#e0bd76"))
	box.add_child(title)
	var note := Label.new()
	note.text = "Press a physical key, mouse button, controller button, or move an axis firmly. Mouse motion and small axis noise are ignored. Escape cancels capture."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.custom_minimum_size = Vector2(700, 80)
	box.add_child(note)
	var cancel := Button.new()
	cancel.name = "CancelInputCapture"
	cancel.text = "Cancel Capture"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.custom_minimum_size = Vector2(260, 44)
	cancel.pressed.connect(_cancel_capture)
	box.add_child(cancel)


func _unhandled_input(event: InputEvent) -> void:
	if capture_action.is_empty():
		return
	if event is InputEventMouseMotion:
		return
	if event is InputEventJoypadMotion and absf(event.axis_value) < InputBindings.AXIS_CAPTURE_THRESHOLD:
		return
	if event is InputEventKey:
		if not event.pressed or event.is_echo():
			return
		if event.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_cancel_capture()
			return
	elif event is InputEventMouseButton:
		if not event.pressed:
			return
	elif event is InputEventJoypadButton:
		if not event.pressed:
			return
	elif not event is InputEventJoypadMotion:
		return
	get_viewport().set_input_as_handled()
	_complete_capture(event)


func _complete_capture(event: InputEvent) -> void:
	var action := capture_action
	var binding_index := capture_index
	var data := InputBindings.event_to_data(event)
	_cancel_capture(false)
	if data.is_empty():
		_show_input_settings("That input could not be captured.")
		return
	var result := SettingsService.assign_binding_data(action, data, binding_index, false)
	if result.ok:
		_show_input_settings("Assigned %s to %s." % [InputBindings.display_name(data), SettingsService.action_label(action)])
		return
	if result.has("conflict_action"):
		pending_binding = {"action": action, "index": binding_index, "data": data}
		var dialog := ConfirmationDialog.new()
		dialog.name = "InputConflictDialog"
		dialog.title = "Binding Conflict"
		dialog.dialog_text = "%s is assigned to %s. Move it to %s?" % [
			InputBindings.display_name(data), SettingsService.action_label(result.conflict_action), SettingsService.action_label(action),
		]
		dialog.ok_button_text = "Move Binding"
		dialog.cancel_button_text = "Keep Existing"
		dialog.confirmed.connect(_resolve_input_conflict)
		dialog.canceled.connect(func() -> void:
			pending_binding.clear()
			_show_input_settings("Conflict cancelled; bindings were unchanged.")
			dialog.queue_free()
		)
		add_child(dialog)
		dialog.popup_centered(Vector2i(600, 240))
		return
	_show_input_settings(result.reason)


func _resolve_input_conflict() -> void:
	if pending_binding.is_empty():
		return
	var result: Dictionary = SettingsService.assign_binding_data(pending_binding.action, pending_binding.data, int(pending_binding.index), true)
	var message: String = "Moved binding to %s." % SettingsService.action_label(pending_binding.action) if result.ok else String(result.reason)
	pending_binding.clear()
	_show_input_settings(message)


func _clear_input_binding(action: String, binding_index: int) -> void:
	var result := SettingsService.clear_binding(action, binding_index)
	_show_input_settings("Cleared binding." if result.ok else result.reason)


func _confirm_reset_all_bindings() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.name = "ResetAllBindingsDialog"
	dialog.title = "Reset Every Binding?"
	dialog.dialog_text = "This replaces all custom keyboard, mouse, and controller bindings with the explicit IsoCastle defaults."
	dialog.ok_button_text = "Reset All"
	dialog.confirmed.connect(func() -> void:
		SettingsService.reset_all_bindings()
		_show_input_settings("All bindings reset to defaults.")
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(560, 220))


func _cancel_capture(rebuild: bool = true) -> void:
	capture_action = ""
	capture_index = -1
	if capture_panel != null and is_instance_valid(capture_panel):
		capture_panel.queue_free()
	capture_panel = null
	if rebuild and is_inside_tree():
		_show_input_settings("Capture cancelled; bindings were unchanged.")


func _on_credits() -> void:
	_show_message("Credits", "An original AI-assisted project directed by the repository owner.\n\nDesign, engineering, writing, generated art, animation, procedural composition, sound design, testing, and build tooling were created for IsoCastle.\n\nInspired by the spirit of classic shareware-era fantasy RPGs, including Castle of the Winds.")


func _on_quit() -> void:
	get_tree().quit()


func _show_intro() -> void:
	clear_screen()
	var box := VBoxContainer.new()
	box.position = Vector2(210, 90)
	box.size = Vector2(860, 540)
	box.add_theme_constant_override("separation", 18)
	screen_root.add_child(box)
	var title := Label.new()
	title.text = "THE NIGHT IRON SANG"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("#f1e3c4"))
	box.add_child(title)
	var intro := Label.new()
	intro.text = (
		"You return to Greywake with rain in your collar and Maelin Vey's sealed workshop key in your pocket.\n\n" +
		"At supper, the aurora bends down until green light touches every roof. Every nail, knife, anchor, and old bell rings once. " +
		"Maelin's compass—broken for eleven years—turns inland toward Orrenfast.\n\n" +
		"Edda sets down her cup. “Well,” she says. “You always did arrive with weather.”"
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(820, 330)
	intro.add_theme_font_size_override("font_size", 22)
	intro.add_theme_color_override("font_color", Color("#d8d4c8"))
	box.add_child(intro)
	_add_menu_button(box, "Choose Who Returned", _show_character_creation)
	_add_menu_button(box, "Back", show_title)


func _show_character_creation() -> void:
	clear_screen()
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(170, 48)
	scroll.size = Vector2(940, 630)
	screen_root.add_child(scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(890, 940)
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	var title := Label.new()
	title.text = "WHO RETURNED TO GREYWAKE?"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#f1e3c4"))
	box.add_child(title)
	var note := Label.new()
	note.text = "A class-light beginning. Every Practice and skill remains learnable."
	note.add_theme_color_override("font_color", Color("#a9c8d1"))
	box.add_child(note)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 14)
	box.add_child(grid)
	name_input = _add_text_field(grid, "Name", "Runa")
	presentation_input = _add_option_field(grid, "Presentation", ["Lean traveler", "Broad traveler", "Soft traveler", "Weathered traveler"])
	portrait_input = _add_option_field(grid, "Portrait", ["Aurora", "Ember", "Reed", "Rime", "Stone", "Moth"])
	background_input = _add_option_field(grid, "Background", [
		"Returned Apprentice", "Marsh Runner", "Dock Guard", "Ledger Dropout",
		"Winter Hunter", "Village Healer", "Lockwright's Kin", "Traveling Cantor"
	])
	practice_input = _add_option_field(grid, "First Practice", [
		"Cinderweave", "Rimekeeping", "Galebinding", "Deepstone",
		"Dawnmending", "Veilcraft", "Echocalling", "Threadseeing"
	])
	kit_input = _add_option_field(grid, "Starting Kit", ["Hearth Blade", "March Bow", "Pilgrim Staff", "Lock & Lantern"])
	difficulty_input = _add_option_field(grid, "Difficulty", ["Story", "Journey", "Grim"])
	difficulty_input.select(1)
	seed_input = _add_text_field(grid, "World seed", str(randi_range(100000, 999999999)))
	var formulas := Label.new()
	formulas.text = (
		"Core: Might 3 • Finesse 3 • Resolve 3, plus background emphasis\n" +
		"Health = 22 + Might×2   Focus = 12 + Resolve×2\n" +
		"Accuracy = 60 + Finesse×2   Carry = 22 + Might×4\n\n" +
		"Story improves recovery. Journey is the intended balance. Grim gives enemies fuller tactical evaluation."
	)
	formulas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	formulas.custom_minimum_size = Vector2(840, 140)
	formulas.add_theme_font_size_override("font_size", 17)
	formulas.add_theme_color_override("font_color", Color("#b9c4c4"))
	box.add_child(formulas)
	_add_menu_button(box, "Begin the Journey", _create_character_and_start)
	_add_menu_button(box, "Back", _show_intro)


func _add_text_field(parent: GridContainer, label_text: String, default_text: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(220, 42)
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)
	var input := LineEdit.new()
	input.text = default_text
	input.custom_minimum_size = Vector2(550, 42)
	parent.add_child(input)
	return input


func _add_option_field(parent: GridContainer, label_text: String, choices: Array[String]) -> OptionButton:
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(220, 42)
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)
	var input := OptionButton.new()
	input.custom_minimum_size = Vector2(550, 42)
	for choice: String in choices:
		input.add_item(choice)
	parent.add_child(input)
	return input


func _create_character_and_start() -> void:
	var character_name := name_input.text.strip_edges()
	if character_name.is_empty():
		character_name = "Wayfarer"
	var background := background_input.get_item_text(background_input.selected)
	var practice := practice_input.get_item_text(practice_input.selected).to_lower()
	var might := 3
	var finesse := 3
	var resolve := 3
	match background:
		"Dock Guard": might += 2
		"Winter Hunter", "Marsh Runner", "Lockwright's Kin": finesse += 2
		"Village Healer", "Ledger Dropout", "Traveling Cantor": resolve += 2
		_: resolve += 1; finesse += 1
	var practice_starts := {
		"cinderweave": "spell_coal_spark", "rimekeeping": "spell_rime_needle",
		"galebinding": "spell_crosswind", "deepstone": "spell_pebble_oath",
		"dawnmending": "spell_warm_palm", "veilcraft": "spell_moth_step",
		"echocalling": "spell_ancestor_s_tap", "threadseeing": "spell_find_the_seam"
	}
	var kit := kit_input.get_item_text(kit_input.selected)
	var kit_items := {
		"Hearth Blade": ["weapon_sword", "armor_wool_undertunic", "consumable_redroot_draught"],
		"March Bow": ["weapon_shortbow", "weapon_dagger", "armor_reedweave_jerkin"],
		"Pilgrim Staff": ["weapon_staff", "armor_pilgrim_robe", "consumable_bluecap_tonic"],
		"Lock & Lantern": ["weapon_seax", "utility_brass_lockpicks", "utility_hooded_lantern"]
	}
	var starting_items: Array = []
	for item_id: String in kit_items[kit]:
		starting_items.append({"id": item_id, "count": 1, "identified": true, "state": "ordinary"})
	var character := {
		"name": character_name, "presentation": presentation_input.get_item_text(presentation_input.selected),
		"portrait": portrait_input.get_item_text(portrait_input.selected).to_lower(),
		"background": background, "practice": practice, "level": 1, "xp": 0,
		"might": might, "finesse": finesse, "resolve": resolve,
		"max_health": 22 + might * 2, "health": 22 + might * 2,
		"max_mana": 12 + resolve * 2, "mana": 12 + resolve * 2,
		"accuracy": 60 + finesse * 2, "evasion": 5 + finesse, "armor": 1,
		"speed": 100, "critical": 5, "silver": 40, "statuses": [], "alive": true,
		"starting_items": starting_items, "starting_spells": [practice_starts[practice]],
	}
	var seed_value := int(seed_input.text)
	if seed_value == 0:
		seed_value = 130713
	var difficulty := difficulty_input.get_item_text(difficulty_input.selected).to_lower()
	GameSession.new_game(character, seed_value, difficulty)
	var item_catalog: Dictionary = {}
	for item: Dictionary in ContentDB.all("items"):
		item_catalog[item.id] = item
	for item_index in range(GameSession.state.inventory.size() - 1, -1, -1):
		var starting_stack: Dictionary = GameSession.state.inventory[item_index]
		var definition: Dictionary = item_catalog.get(starting_stack.get("id", ""), {})
		var equipment_slot := String(definition.get("slot", ""))
		if equipment_slot.is_empty() or GameSession.state.equipment.has(equipment_slot):
			continue
		var equip_result := InventoryRules.equip(GameSession.state.inventory, GameSession.state.equipment, item_index, equipment_slot, character, item_catalog)
		if equip_result.ok:
			GameSession.state.inventory = equip_result.inventory
			GameSession.state.equipment = equip_result.equipment
	_launch_game()


func _launch_game() -> void:
	clear_screen()
	status_label.visible = false
	var game := GameView.new()
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.return_to_menu.connect(show_title)
	screen_root.add_child(game)
