extends RefCounted
class_name EconomyRules

# Cálculos de renda por turno e compra de unidades na loja

static func calculate_turn_income(buildings_factions: Array, target_faction: int, income_per_building: int) -> int:
	if income_per_building <= 0 or buildings_factions.is_empty():
		return 0
		
	var owned_count: int = 0
	for faction in buildings_factions:
		if int(faction) == target_faction:
			owned_count += 1
			
	return owned_count * income_per_building


static func process_unit_purchase(
	current_funds: int,
	catalog_costs: Array,
	catalog_index: int,
	is_tile_occupied: bool = false
) -> Dictionary:
	if is_tile_occupied:
		return {
			"can_purchase": false,
			"remaining_funds": current_funds,
			"cost": 0,
			"reason": "TILE_OCCUPIED"
		}
		
	if catalog_index < 0 or catalog_index >= catalog_costs.size():
		return {
			"can_purchase": false,
			"remaining_funds": current_funds,
			"cost": 0,
			"reason": "INVALID_INDEX"
		}
		
	var raw_cost = catalog_costs[catalog_index]
	if raw_cost == null:
		return {
			"can_purchase": false,
			"remaining_funds": current_funds,
			"cost": 0,
			"reason": "INVALID_PRESET"
		}
		
	var unit_cost: int = max(0, int(raw_cost))
	
	if current_funds < unit_cost or current_funds < 0:
		return {
			"can_purchase": false,
			"remaining_funds": current_funds,
			"cost": unit_cost,
			"reason": "INSUFFICIENT_FUNDS"
		}
		
	return {
		"can_purchase": true,
		"remaining_funds": current_funds - unit_cost,
		"cost": unit_cost,
		"reason": "OK"
	}
