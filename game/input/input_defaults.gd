class_name InputDefaults
extends RefCounted

const ACTION_ORDER: Array[String] = [
	"move_north", "move_south", "move_west", "move_east",
	"move_northwest", "move_northeast", "move_southwest", "move_southeast",
	"wait_turn", "interact", "search", "inventory", "spellbook", "journal", "map",
	"ranged_attack", "cast_prepared", "quick_item", "quick_save", "quick_load",
	"ui_cancel", "toggle_overlay", "screenshot_mode",
]

const LABELS: Dictionary = {
	"move_north": "Move north", "move_south": "Move south",
	"move_west": "Move west", "move_east": "Move east",
	"move_northwest": "Move northwest", "move_northeast": "Move northeast",
	"move_southwest": "Move southwest", "move_southeast": "Move southeast",
	"wait_turn": "Wait one turn", "interact": "Interact", "search": "Search",
	"inventory": "Inventory", "spellbook": "Spellbook", "journal": "Journal",
	"map": "Map", "ranged_attack": "Ranged attack", "cast_prepared": "Cast prepared spell",
	"quick_item": "Quick item", "quick_save": "Quick save", "quick_load": "Quick load",
	"ui_cancel": "Pause / cancel", "toggle_overlay": "Developer overlay",
	"screenshot_mode": "Screenshot mode",
}

const RENAMED_ACTIONS: Dictionary = {
	"cast_spell": "cast_prepared",
	"quick_use": "quick_item",
	"pause": "ui_cancel",
}


static func bindings() -> Dictionary:
	return {
		"move_north": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"move_south": [_key(KEY_S), _key(KEY_DOWN), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"move_west": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"move_east": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"move_northwest": [_key(KEY_Q)],
		"move_northeast": [_key(KEY_E)],
		"move_southwest": [_key(KEY_Z)],
		"move_southeast": [_key(KEY_C)],
		"wait_turn": [_key(KEY_X), _key(KEY_PERIOD)],
		"interact": [_key(KEY_F), _key(KEY_ENTER), _joy_button(JOY_BUTTON_A)],
		"search": [_key(KEY_V)],
		"inventory": [_key(KEY_I), _joy_button(JOY_BUTTON_Y)],
		"spellbook": [_key(KEY_B)],
		"journal": [_key(KEY_J)],
		"map": [_key(KEY_M)],
		"ranged_attack": [_key(KEY_2), _mouse_button(MOUSE_BUTTON_MIDDLE)],
		"cast_prepared": [_key(KEY_1), _joy_button(JOY_BUTTON_X)],
		"quick_item": [_key(KEY_3), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)],
		"quick_save": [_key(KEY_F8)],
		"quick_load": [_key(KEY_F9)],
		"ui_cancel": [_key(KEY_ESCAPE), _joy_button(JOY_BUTTON_B)],
		"toggle_overlay": [_key(KEY_F2)],
		"screenshot_mode": [_key(KEY_F3)],
	}


static func _key(physical_keycode: Key, shift: bool = false, ctrl: bool = false, alt: bool = false, meta: bool = false) -> Dictionary:
	return {
		"type": "key", "physical_keycode": int(physical_keycode),
		"shift": shift, "ctrl": ctrl, "alt": alt, "meta": meta,
	}


static func _mouse_button(button_index: MouseButton) -> Dictionary:
	return {"type": "mouse_button", "button_index": int(button_index)}


static func _joy_button(button_index: JoyButton) -> Dictionary:
	return {"type": "joypad_button", "button_index": int(button_index)}


static func _joy_axis(axis: JoyAxis, axis_value: float) -> Dictionary:
	return {"type": "joypad_motion", "axis": int(axis), "axis_value": axis_value, "deadzone": 0.55}
