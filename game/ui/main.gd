extends Control

var screen_root: Control
var status_label: Label


func _ready() -> void:
	_build_shell()
	show_title()


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("#07131f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var moon := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("#375169"), Color("#101c2b"), Color("#07131f")])
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	moon.gradient = gradient
	moon.width = 1280
	moon.height = 720
	moon.fill_from = Vector2(0.15, 0.0)
	moon.fill_to = Vector2(0.8, 1.0)
	var sky := TextureRect.new()
	sky.texture = moon
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

	var title := Label.new()
	title.text = "ISOCASTLE"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color("#f1e3c4"))
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
	_show_message("Character Creation", "The complete character builder is being assembled. This first runnable scene verifies the project foundation and resolution-independent screen router.")


func _on_continue() -> void:
	var loaded := SaveService.load_slot(0)
	if loaded.is_empty():
		_show_message("No Journey Found", "No valid autosave or recovery backup is available.")
	else:
		GameSession.restore(loaded)
		_show_message("Journey Restored", "Save schema %d loaded safely." % int(loaded.save_version))


func _on_load() -> void:
	_show_message("Load Game", "Five manual slots plus an autosave are supported by the versioned save service.")


func _on_settings() -> void:
	_show_message("Settings & Accessibility", "Audio categories, UI and text scale, high contrast, reduced motion and flashing, screen shake, animation speed, interaction highlighting, confirmations, and remappable input are represented independently from campaign saves.")


func _on_credits() -> void:
	_show_message("Credits", "An original AI-assisted project directed by the repository owner.\n\nDesign, engineering, writing, generated art, animation, procedural composition, sound design, testing, and build tooling were created for IsoCastle.\n\nInspired by the spirit of classic shareware-era fantasy RPGs, including Castle of the Winds.")


func _on_quit() -> void:
	get_tree().quit()

