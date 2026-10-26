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
				
			# Agora na nova posição, verifica se existe um ALVO REAL (unidade do jogador ou estrutura) adjacente
			var card_dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
			var attack_target_tile = Vector2i.ZERO
			var attack_dir = Vector2i.ZERO
			
			# Prioridade 1: Unidades do jogador adjacentes
			for d in card_dirs:
				var candidate = enemy.grid_position + d
				if grid_m.active_units.has(candidate):
					var u = grid_m.active_units[candidate]
					if not u.is_enemy:
						attack_target_tile = candidate
						attack_dir = d
						break
			
			# Prioridade 2: Prédios não-inimigos adjacentes (se não encontrou unidade)
			if attack_target_tile == Vector2i.ZERO:
				for d in card_dirs:
					var candidate = enemy.grid_position + d
					if grid_m.active_buildings.has(candidate):
						var b = grid_m.active_buildings[candidate]
						if b.faction != 2: # Não é da facção inimiga
							attack_target_tile = candidate
							attack_dir = d
							break
			
			# Só define direção e ilumina perigo se HOUVER um alvo real ao alcance
			if attack_target_tile != Vector2i.ZERO:
				enemy.ai_attack_dir = attack_dir
				enemy.ai_target_tile = attack_target_tile
				grid_m.set_tile_base_state(
					enemy.ai_target_tile, 
					grid_m.danger_highlight_color, 
					grid_m.danger_highlight_strength, 
					game_controller.current_hovered_tile
				)
			else:
				enemy.ai_attack_dir = Vector2i.ZERO
				enemy.ai_target_tile = Vector2i.ZERO


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
		if enemy.ai_target_tile == Vector2i.ZERO or enemy.ai_target_tile == Vector2i(-999, -999):
			continue
			
		var target = enemy.ai_target_tile
		grid_m.set_tile_base_state(target, Color.WHITE, 0.0, game_controller.current_hovered_tile)
		
		if grid_m.active_units.has(target):
			var victim = grid_m.active_units[target]
			if not victim.is_enemy:
				victim.take_damage(1)
				if victim == game_controller.selected_unit:
					game_controller.ui_manager.update_selection_visuals(game_controller.selected_unit, null)
				if victim.current_hp <= 0:
					grid_m.active_units.erase(target)
		elif grid_m.active_buildings.has(target):
			var building = grid_m.active_buildings[target]
			if building.faction != 2:
				building.capture(2, 1)
				
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
