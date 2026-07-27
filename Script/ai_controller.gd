extends Node3D
class_name GridAIController

const Pathfinder = preload("res://Script/grid_pathfinder.gd")

@onready var game_controller = get_parent()


func plan_enemy_attacks() -> void:
	var grid_m = game_controller.grid_manager
	var enemies: Array = []
	for unit in grid_m.active_units.values():
		if unit.is_enemy: 
			enemies.append(unit)
			
	for enemy in enemies:
		var target_pos: Vector2i = Vector2i(-999, -999)
		
		# 1. Tenta encontrar a unidade do jogador mais próxima
		var target_player = find_closest_player(enemy.grid_position, grid_m.active_units)
		if target_player:
			target_pos = target_player.grid_position
		else:
			# 2. Se não houver jogadores perto, mira no QG do jogador (Ação de Marcha de Invasão) [1]
			target_pos = find_player_hq_position(grid_m.active_buildings)
			
		# Se houver um alvo válido (Jogador ou QG) no mapa
		if target_pos != Vector2i(-999, -999):
			var best_tile = find_best_tile_for_enemy(enemy, target_pos, grid_m)
			
			if best_tile != enemy.grid_position:
				var path = Pathfinder.calculate_path_to_target(
					grid_m.grid_cells, grid_m.active_units, 
					enemy.grid_position, best_tile, 
					enemy.movement_range, grid_m.max_climb_height
				)
				await game_controller.walk_unit_along_path(enemy, path)
				
			# Agora na nova posição, calcula a direção para mirar o ataque
			var diff = target_pos - enemy.grid_position
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


# Encontra o melhor bloco para o inimigo andar baseado na coordenada alvo
func find_best_tile_for_enemy(enemy, target_pos: Vector2i, grid_m: GridManager) -> Vector2i:
	var reachable = Pathfinder.calculate_reachable_tiles(
		grid_m.grid_cells, grid_m.active_units, 
		enemy.grid_position, enemy.movement_range, grid_m.max_climb_height
	)
	reachable.append(enemy.grid_position)
	
	var best = enemy.grid_position
	var min_dist = 99999
	for tile in reachable:
		var dist = abs(tile.x - target_pos.x) + abs(tile.y - target_pos.y)
		if dist < min_dist:
			min_dist = dist
			best = tile
	return best


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
		
		# NOVA LÓGICA: IA ataca estruturas se elas estiverem na mira! [1]
		elif grid_m.active_buildings.has(target):
			var building = grid_m.active_buildings[target]
			# Causa dano de captura (muda o domínio do prédio para a IA)
			building.capture(2, 1) # Inimigo (facção 2) captura com força de 1 [1]
				
		enemy.ai_attack_dir = Vector2i.ZERO
		enemy.ai_target_tile = Vector2i.ZERO


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


# AUXILIAR: Encontra a localização do QG do jogador no mapa [1]
func find_player_hq_position(active_buildings: Dictionary) -> Vector2i:
	for coords in active_buildings.keys():
		var b = active_buildings[coords]
		if b.faction == 1 and b.is_hq:
			return coords
	return Vector2i(-999, -999)
