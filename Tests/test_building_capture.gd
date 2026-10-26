extends GutTest

# Testes de captura de construções e condição de derrota (BuildingRules)
# No jogo, cada cidade tem pontos de captura que diminuem conforme o HP da unidade que está capturando.
# Quando os pontos chegam a 0, a construção troca de facção e reseta os pontos para o máximo.


# Captura parcial ocorre quando o HP da construção não é suficiente para que ela seja capturada nesse turno (resulta apenas em redução de pontos)
func test_captura_parcial() -> void:
	# Arrange: Cidade neutra com 10/10 pontos e unidade do jogador com 4 de HP
	var current_faction: int = 0
	var capturing_faction: int = 1
	var current_points: int = 10
	var max_points: int = 10
	var unit_hp_power: int = 4
	
	# Act
	var result: Dictionary = BuildingRules.process_capture_step(
		current_faction, capturing_faction, current_points, max_points, unit_hp_power
	)
	
	# Assert: Quando os pontos caem para 6, a construção continua neutra
	assert_eq(result["capture_points"], 6, "Os pontos de captura devem cair de 10 para 6.")
	assert_eq(result["faction"], 0, "A cidade continua neutra (0) enquanto os pontos não zerarem.")
	assert_false(result["was_captured"], "A captura ainda não teve sucesso.")


# Captura completa quando a os pontos da construção caem para 0
func test_captura_completa() -> void:
	# Arrange: Construção neutra com 3 pontos restantes é capturada por unidade com 5 de HP
	var current_faction: int = 0
	var capturing_faction: int = 1
	var current_points: int = 3
	var max_points: int = 10
	var unit_hp_power: int = 5
	
	# Act
	var result: Dictionary = BuildingRules.process_capture_step(
		current_faction, capturing_faction, current_points, max_points, unit_hp_power
	)
	
	# Assert: Passa para a facção 1 (jogador) e restaura os pontos para 10
	assert_true(result["was_captured"], "a construção foi conquistado.")
	assert_eq(result["faction"], 1, "A facção da construção muda para o jogador (1).")
	assert_eq(result["capture_points"], 10, "Os pontos da construção devem voltar ao seu máximo de 10 após a captura.")


# Edge case: Tentar capturar uma construção que já pertence à própria facção
func test_edge_case_capturar_construcao_da_mesma_faccao() -> void:
	# Arrange & Act: Facção 1 (jogador) tentando capturar uma estrutura que já é da facção 1
	var result: Dictionary = BuildingRules.process_capture_step(1, 1, 10, 10, 5)
	
	# Assert: Ignora a ação. Nada muda
	assert_false(result["was_captured"], "A recaptura não acontece.")
	assert_eq(result["capture_points"], 10, "Os pontos da construção aliada não caem.")


# Edge case: Força de captura zero ou negativa não deve alterar nem regenerar os pontos
func test_edge_case_forca_de_captura_negativa_ou_zero() -> void:
	# Arrange & Act: Prédio com 8 pontos recebendo força -3 e 0
	var result_neg: Dictionary = BuildingRules.process_capture_step(0, 1, 8, 10, -3)
	var result_zero: Dictionary = BuildingRules.process_capture_step(0, 1, 8, 10, 0)
	
	# Assert
	assert_eq(result_neg["capture_points"], 8, "Força negativa não adiciona pontos à construção.")
	assert_eq(result_zero["capture_points"], 8, "Força zero não altera os pontos.")


# Verificação de derrota quando o QG do jogador é capturado pelo inimigo
func test_condicao_derrota() -> void:
	# Arrange: Cenário A com QG aliado ativo e Cenário B onde o QG foi tomado pela facção 2 (inimigo)
	var cenario_vivo: Array = [
		{"is_hq": true, "faction": 1},
		{"is_hq": false, "faction": 1},
		{"is_hq": true, "faction": 2}
	]
	var cenario_derrota: Array = [
		{"is_hq": true, "faction": 2},
		{"is_hq": false, "faction": 1},
		{"is_hq": true, "faction": 2}
	]
	
	# Act
	var derrotado_a: bool = BuildingRules.is_player_defeated(cenario_vivo)
	var derrotado_b: bool = BuildingRules.is_player_defeated(cenario_derrota)
	var derrotado_vazio: bool = BuildingRules.is_player_defeated([])
	
	# Assert
	assert_false(derrotado_a, "O jogador não perde enquanto tiver controle do proprio QG.")
	assert_true(derrotado_b, "O jogador perde assim que seu QG é tomado pelo inimigo.")
	assert_true(derrotado_vazio, "Se não há nenhuma construção no mapa, o jogador é derrotado.")
