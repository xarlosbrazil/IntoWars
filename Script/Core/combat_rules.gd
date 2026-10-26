extends RefCounted
class_name CombatRules

# Regras de cálculo de dano e validação de alcance de ataque

static func calculate_damage_result(current_hp: int, max_hp: int, damage_amount: int) -> Dictionary:
	var safe_max_hp: int = max(1, max_hp)
	var clamped_current: int = clampi(current_hp, 0, safe_max_hp)
	
	if damage_amount <= 0:
		return {
			"new_hp": clamped_current,
			"damage_applied": 0,
			"is_defeated": clamped_current <= 0
		}
	
	var new_hp: int = clampi(clamped_current - damage_amount, 0, safe_max_hp)
	var actual_damage: int = clamped_current - new_hp
	
	return {
		"new_hp": new_hp,
		"damage_applied": actual_damage,
		"is_defeated": new_hp <= 0
	}


static func can_unit_attack_target(
	attacker_pos: Vector2i,
	target_pos: Vector2i,
	attack_range: int,
	attacker_is_enemy: bool,
	target_is_enemy: bool
) -> bool:
	if attack_range <= 0 or attacker_pos == target_pos:
		return false
		
	if attacker_is_enemy == target_is_enemy:
		return false
		
	var dx: int = abs(attacker_pos.x - target_pos.x)
	var dy: int = abs(attacker_pos.y - target_pos.y)
	
	# Ataque em linha reta (ortogonal)
	var is_orthogonal: bool = (dx == 0 and dy > 0) or (dy == 0 and dx > 0)
	if not is_orthogonal:
		return false
		
	var distance: int = dx + dy
	return distance >= 1 and distance <= attack_range
