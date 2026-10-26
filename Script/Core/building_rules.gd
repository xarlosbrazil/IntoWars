extends RefCounted
class_name BuildingRules

# Lógica de captura de construções e verificação de derrota da partida

static func process_capture_step(
	current_faction: int,
	capturing_faction: int,
	current_points: int,
	max_points: int,
	capture_power: int
) -> Dictionary:
	var safe_max: int = max(1, max_points)
	var safe_current: int = clampi(current_points, 0, safe_max)
	
	if current_faction == capturing_faction or capture_power <= 0:
		return {
			"faction": current_faction,
			"capture_points": safe_current,
			"was_captured": false
		}
	
	var remaining_points: int = clampi(safe_current - capture_power, 0, safe_max)
	
	if remaining_points <= 0:
		return {
			"faction": capturing_faction,
			"capture_points": safe_max,
			"was_captured": true
		}
		
	return {
		"faction": current_faction,
		"capture_points": remaining_points,
		"was_captured": false
	}


static func is_player_defeated(buildings: Array) -> bool:
	if buildings.is_empty():
		return true
		
	for b in buildings:
		if b == null:
			continue
		var b_is_hq: bool = false
		var b_faction: int = 0
		
		if b is Dictionary:
			b_is_hq = bool(b.get("is_hq", false))
			b_faction = int(b.get("faction", 0))
		elif b is Object:
			b_is_hq = bool(b.get("is_hq"))
			b_faction = int(b.get("faction"))
			
		if b_is_hq and b_faction == 1:
			return false
			
	return true
