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
	print("SMOKE PASS: main scene, title screen, and %d menu buttons loaded" % buttons.size())
	quit(0)

