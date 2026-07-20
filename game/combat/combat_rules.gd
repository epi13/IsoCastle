class_name CombatRules
extends RefCounted

const DAMAGE_TYPES := ["slash", "pierce", "crush", "fire", "frost", "shock", "radiant", "shadow", "spirit", "fate"]


static func attack(attacker: Dictionary, defender: Dictionary, weapon: Dictionary, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var accuracy := clampi(int(attacker.get("accuracy", 65)) + int(attacker.get("finesse", 0)) * 2 - int(defender.get("evasion", 0)), 5, 95)
	var roll := rng.randi_range(1, 100)
	var result := {"hit": roll <= accuracy, "roll": roll, "accuracy": accuracy, "critical": false, "damage": 0, "damage_type": weapon.get("damage_type", "crush")}
	if not result.hit:
		return result
	var damage_range: Array = weapon.get("damage", [1, 3])
	var raw := rng.randi_range(int(damage_range[0]), int(damage_range[1])) + int(attacker.get("might", 0))
	var critical_chance := clampi(5 + int(attacker.get("critical", 0)), 0, 50)
	result.critical = rng.randi_range(1, 100) <= critical_chance
	if result.critical:
		raw = int(ceil(raw * 1.5))
	var armor := int(defender.get("armor", 0)) if result.damage_type in ["slash", "pierce", "crush"] else 0
	var resistance := int(defender.get("resistances", {}).get(result.damage_type, 0))
	result.damage = maxi(1, int(round(maxi(1, raw - armor) * (1.0 - resistance / 100.0))))
	return result


static func apply_damage(actor: Dictionary, result: Dictionary) -> Dictionary:
	var updated := actor.duplicate(true)
	updated.health = maxi(0, int(updated.get("health", 1)) - int(result.get("damage", 0)))
	updated.alive = updated.health > 0
	return updated


static func tick_statuses(actor: Dictionary) -> Dictionary:
	var updated := actor.duplicate(true)
	var remaining: Array = []
	for status: Dictionary in updated.get("statuses", []):
		if status.get("damage", 0) > 0:
			updated.health = maxi(0, int(updated.health) - int(status.damage))
		if status.get("healing", 0) > 0:
			updated.health = mini(int(updated.max_health), int(updated.health) + int(status.healing))
		var next := status.duplicate(true)
		next.duration = int(next.get("duration", 1)) - 1
		if next.duration > 0:
			remaining.append(next)
	updated.statuses = remaining
	updated.alive = int(updated.health) > 0
	return updated


static func spell_damage(caster: Dictionary, target: Dictionary, spell: Dictionary, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var base := int(spell.get("power", 4))
	var scaling: Dictionary = spell.get("scaling", {})
	var raw := base + int(float(caster.get("resolve", 0)) * float(scaling.get("resolve", 0.0)))
	raw += rng.randi_range(-2, 2)
	var damage_type: String = spell.get("damage_type", "spirit")
	var resistance := int(target.get("resistances", {}).get(damage_type, 0))
	return {"hit": true, "damage": maxi(0, int(round(raw * (1.0 - resistance / 100.0)))), "damage_type": damage_type, "critical": false}

