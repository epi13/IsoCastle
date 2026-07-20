class_name QuestEngine
extends RefCounted


static func start(quest_states: Dictionary, quest_id: String) -> Dictionary:
	var result := quest_states.duplicate(true)
	if not result.has(quest_id):
		result[quest_id] = {"state": "active", "stage": 0, "progress": 0, "choices": []}
	return result


static func advance(quest_states: Dictionary, quest: Dictionary, amount: int = 1) -> Dictionary:
	var result := quest_states.duplicate(true)
	if not result.has(quest.id):
		return result
	var state: Dictionary = result[quest.id]
	if state.get("state") != "active":
		return result
	state.progress = int(state.get("progress", 0)) + amount
	var stage_index := int(state.get("stage", 0))
	var stages: Array = quest.get("stages", [])
	if stage_index < stages.size() and int(state.progress) >= int(stages[stage_index].get("target", 1)):
		state.progress = 0
		state.stage = stage_index + 1
		if int(state.stage) >= stages.size():
			state.state = "complete"
	return result


static func record_choice(quest_states: Dictionary, quest_id: String, choice: String) -> Dictionary:
	var result := quest_states.duplicate(true)
	if result.has(quest_id):
		result[quest_id].choices.append(choice)
	return result

