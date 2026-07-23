extends Node3D
class_name GridAIController

# --- PRELOAD DIRETO (Ignora bugs de cache global do Godot) ---
const Pathfinder = preload("res://Script/grid_pathfinder.gd")

@onready var game_controller = get_parent()

# Computes paths and plans upcoming attacks for all active enemies
func plan_enemy_attacks() -> void:
	var grid_m = game_controller.grid_manager
	var enemies: Array = []
	for unit in grid_m.active_units.values():
		if unit.is_enemy: 
			enemies.append(unit)
			
	for enemy in enemies:
		var player = find_closest_player(enemy.grid_position, grid_m.active_units)
		if player:
			var best_tile = find_best_tile_for_enemy(enemy, player.grid_position, grid_m)
			
			if best_tile != enemy.grid_position:
				# CORREÇÃO: Utiliza o Pathfinder pré-carregado diretamente do disco
				var path = Pathfinder.calculate_path_to_target(
					grid_m.grid_cells, grid_m.active_units, 
					enemy.grid_position, best_tile, 
					enemy.movement_range, grid_m.max_climb_height
				)
				await game_controller.walk_unit_along_path(enemy, path)
				
			var diff = player.grid_position - enemy.grid_position
			var dir = Vector2i.ZERO
			if abs(diff.x) > abs(diff.y): 
				dir.x = sign(diff.x)
			else: 
				dir.y = sign(diff.y)
				
			enemy.ai_attack_dir = dir
			enemy.update_ai_target_tile()
			
			grid_m.set_tile_base_state(
				enemy.ai_target_tile, 
				grid_m.danger_highlight_color, 
				grid_m.danger_highlight_strength, 
				game_controller.current_hovered_tile
			)


# Evaluates pathfinding options to find the tile that minimizes distance to target
func find_best_tile_for_enemy(enemy, player_pos: Vector2i, grid_m: GridManager) -> Vector2i:
	# CORREÇÃO: Utiliza o Pathfinder pré-carregado diretamente do disco
	var reachable = Pathfinder.calculate_reachable_tiles(
		grid_m.grid_cells, grid_m.active_units, 
		enemy.grid_position, enemy.movement_range, grid_m.max_climb_height
	)
	reachable.append(enemy.grid_position)
	
	var best = enemy.grid_position
	var min_dist = 99999
	for tile in reachable:
		var dist = abs(tile.x - player_pos.x) + abs(tile.y - player_pos.y)
		if dist < min_dist:
			min_dist = dist
			best = tile
	return best


# Resolves telegraphed attacks and inflicts damage
func execute_enemy_attacks() -> void:
	var grid_m = game_controller.grid_manager
	var enemies: Array = []
	for unit in grid_m.active_units.values():
		if unit.is_enemy: 
			enemies.append(unit)
			
	for enemy in enemies:
		enemy.update_ai_target_tile()
		var target = enemy.ai_target_tile
		
		grid_m.set_tile_base_state(target, Color.WHITE, 0.0, game_controller.current_hovered_tile)
		
		if grid_m.active_units.has(target):
			var victim = grid_m.active_units[target]
			victim.take_damage(1)
			
			if victim == game_controller.selected_unit:
				game_controller.ui_manager.update_selection_visuals(game_controller.selected_unit, null)
				
			if victim.current_hp <= 0:
				grid_m.active_units.erase(target)
				
		enemy.ai_attack_dir = Vector2i.ZERO
		enemy.ai_target_tile = Vector2i.ZERO


# Finds the closest player unit to a given enemy coordinate
func find_closest_player(enemy_pos: Vector2i, active_units: Dictionary):
	var closest = null
	var min_dist = 99999
	for unit in active_units.values():
		if not unit.is_enemy:
			var dist = abs(unit.grid_position.x - enemy_pos.x) + abs(unit.grid_position.y - enemy_pos.y)
			if dist < min_dist:
				min_dist = dist
				closest = unit
	return closest
