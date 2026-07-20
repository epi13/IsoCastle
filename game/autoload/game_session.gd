extends Node

signal state_changed(section: String)

var state: Dictionary = {}


func _ready() -> void:
	reset()


func reset() -> void:
	state = {
		"save_version": SaveService.SAVE_VERSION,
		"seed": 130713,
		"difficulty": "journey",
		"player": {},
		"world": {"location": "greywake", "floor": 0, "turn": 0, "discovered": []},
		"inventory": [],
		"equipment": {},
		"known_spells": [],
		"quests": {},
		"flags": {},
		"factions": {"greywake": 0, "marsh_keepers": 0, "quiet_ledger": 0},
		"journal": {"lore": [], "bestiary": []},
		"play_seconds": 0.0
	}
	state_changed.emit("all")


func new_game(character: Dictionary, seed_value: int, difficulty_value: String) -> void:
	reset()
	state.player = character.duplicate(true)
	state.seed = seed_value
	state.difficulty = difficulty_value
	state.inventory = character.get("starting_items", []).duplicate(true)
	state.known_spells = character.get("starting_spells", []).duplicate()
	state.quests = {"homecoming": {"state": "active", "stage": 0}}
	state_changed.emit("all")


func serialize() -> Dictionary:
	return state.duplicate(true)


func restore(saved_state: Dictionary) -> void:
	state = saved_state.duplicate(true)
	state_changed.emit("all")

