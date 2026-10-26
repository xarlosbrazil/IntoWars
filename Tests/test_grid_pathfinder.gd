extends GutTest

# Testes de movimentação e busca de caminho no grid (GridPathfinder)
# Verifica o alcance por BFS, limite de altura entre blocos (max_climb_height),
# conectividade de ilhas (Flood Fill) e busca de alvos inimigos no alcance.


# Distância máxima da movimentação em um terreno plano
func test_calculo_distancia_maxima() -> void:
	# Arrange: Grid 3x2 plano (altura 1.0), partindo de (0,0) com alcance 2
	var grid_cells: Dictionary = {
		Vector2i(0, 0): 1.0, Vector2i(1, 0): 1.0, Vector2i(2, 0): 1.0,
		Vector2i(0, 1): 1.0, Vector2i(1, 1): 1.0, Vector2i(2, 1): 1.0
	}
	var active_units: Dictionary = {}
	
	# Act
	var reachable: Array[Vector2i] = GridPathfinder.calculate_reachable_tiles(
		grid_cells, active_units, Vector2i(0, 0), 2, 1.1
	)
	
	# Assert: pode se mover até 2 tiles de distância
	assert_true(reachable.has(Vector2i(1, 0)), "pode mover (1,0) pois é 1 passo.")
	assert_true(reachable.has(Vector2i(2, 0)), "pode mover (2,0) pois é 2 passo.")
	assert_true(reachable.has(Vector2i(1, 1)), "pode mover (1,1) pois é 2 passo.")
	assert_false(reachable.has(Vector2i(2, 1)), "Não é possível mover (2,1) pois exige 3 passos.")


# Edge case: Bloco vizinho com degrau que ultrapassa max_climb_height
func test_edge_case_degrau_bloqueia_movimento() -> void:
	# Arrange: Origem (0,0) em 1.0; (1,0) tem altura 3.0 (degrau 2.0 > 1.1); (0,1) tem altura 2.0 (degrau 1.0 <= 1.1)
	var grid_cells: Dictionary = {
		Vector2i(0, 0): 1.0,
		Vector2i(1, 0): 3.0,
		Vector2i(0, 1): 2.0
	}
	var active_units: Dictionary = {}
	
	# Act
	var reachable: Array[Vector2i] = GridPathfinder.calculate_reachable_tiles(
		grid_cells, active_units, Vector2i(0, 0), 2, 1.1
	)
	
	# Assert
	assert_false(reachable.has(Vector2i(1, 0)), "Não é possível subir 2.0 quando o limite é 1.1.")
	assert_true(reachable.has(Vector2i(0, 1)), "É possível subir 1.0 pois está abaixo de limite 1.1.")


# Edge case: Destino isolado por água e unidade sem alcance (zero)
func test_edge_case_ponto_isolado() -> void:
	# Arrange: Bloco (0,3) separado por espaço vazio em (0,2)
	var grid_cells: Dictionary = {
		Vector2i(0, 0): 1.0,
		Vector2i(0, 1): 1.0,
		Vector2i(0, 3): 1.0
	}
	
	# Act
	var path_possible: bool = GridPathfinder.is_path_possible(grid_cells, Vector2i(0, 0), Vector2i(0, 3), 1.1)
	var reachable_zero: Array[Vector2i] = GridPathfinder.calculate_reachable_tiles(grid_cells, {}, Vector2i(0, 0), 0, 1.1)
	
	# Assert
	assert_false(path_possible, "Não existe caminho até a o ponto de destino.")
	assert_eq(reachable_zero.size(), 0, "Alcance 0.")


# Reconstrução do caminho desviando de uma construção ocupada por outra unidade
func test_reconstrucao_de_rota() -> void:
	# Arrange: Grid 2x2 com (1,0) ocupado, forçando o caminho por (0,1) -> (1,1)
	var grid_cells: Dictionary = {
		Vector2i(0, 0): 1.0, Vector2i(1, 0): 1.0,
		Vector2i(0, 1): 1.0, Vector2i(1, 1): 1.0
	}
	var active_units: Dictionary = {
		Vector2i(1, 0): {"is_enemy": true}
	}
	
	# Act
	var path: Array[Vector2i] = GridPathfinder.calculate_path_to_target(
		grid_cells, active_units, Vector2i(0, 0), Vector2i(1, 1), 3, 1.1
	)
	
	# Assert
	assert_eq(path.size(), 2, "A rota tem 2 passos.")
	assert_eq(path[0], Vector2i(0, 1), "O primeiro passo conrtorna por (0,1).")
	assert_eq(path[1], Vector2i(1, 1), "O passo final chega em (1,1).")


# Identificação de inimigos atacáveis a partir da posição da unidade
func test_identificar_alvos() -> void:
	# Arrange: Inimigo válido em (1,0), aliado em (0,1) e inimigo fora de alcance em (3,0)
	var grid_cells: Dictionary = {
		Vector2i(0, 0): 1.0, Vector2i(1, 0): 1.0, Vector2i(2, 0): 1.0, Vector2i(3, 0): 1.0,
		Vector2i(0, 1): 1.0
	}
	var active_units: Dictionary = {
		Vector2i(1, 0): {"is_enemy": true},
		Vector2i(0, 1): {"is_enemy": false},
		Vector2i(3, 0): {"is_enemy": true}
	}
	
	# Act
	var attackable: Array[Vector2i] = GridPathfinder.calculate_attackable_tiles(
		grid_cells, active_units, Vector2i(0, 0), 2
	)
	
	# Assert: Retorna apenas o inimigo em (1,0)
	assert_eq(attackable.size(), 1, "seleciona 1 alvo válido.")
	assert_true(attackable.has(Vector2i(1, 0)), "Inimigo em (1,0) é o alvo selecionado.")
	assert_false(attackable.has(Vector2i(0, 1)), "Aliado em (0,1) não é um alvo válido.")
	assert_false(attackable.has(Vector2i(3, 0)), "Inimigo em (3,0) está fora do alcance.")
