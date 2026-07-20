class_name TurnEngine
extends RefCounted

var actors: Array[Dictionary] = []
var round_index := 0


func reset(source: Array[Dictionary]) -> void:
	actors = source.duplicate(true)
	round_index = 0
	for actor: Dictionary in actors:
		actor["energy"] = int(actor.get("energy", 100))
		actor["alive"] = bool(actor.get("alive", true))


func next_actor_index() -> int:
	for _guard in range(1000):
		var best_index := -1
		var best_energy := -1
		for index in range(actors.size()):
			var actor := actors[index]
			if bool(actor.get("alive", true)) and int(actor.get("energy", 0)) >= 100 and int(actor.energy) > best_energy:
				best_energy = int(actor.energy)
				best_index = index
		if best_index >= 0:
			return best_index
		for actor: Dictionary in actors:
			if bool(actor.get("alive", true)):
				actor.energy = int(actor.get("energy", 0)) + int(actor.get("speed", 100))
		round_index += 1
	return -1


func spend(index: int, cost: int = 100) -> void:
	if index >= 0 and index < actors.size():
		actors[index].energy = int(actors[index].get("energy", 0)) - cost

