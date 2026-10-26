extends GutTest

# Testes de economia por turno e loja de unidades (EconomyRules)
# 1. Soma das rendas
# 2. Listas vazias e rendas negativas
# 3. Compra de unidade
# 4. Falha na compra (sem fundos)
# 5. Indice fora do catálogo (bate o cap)


# Somagem de renda da facção
func test_calculo_renda_multiplos_predios_aliados() -> void:
	
	# Arrange: # 0 = neutro, 1 = jogador, 2 = inimigo 
	var buildings_factions: Array = [1, 0, 1, 2, 1, 0] # Construções presentes no mapa e a associação delas
	var income_per_building: int = 50
	
	# Act
	var total_income: int = EconomyRules.calculate_turn_income(buildings_factions, 1, income_per_building)
	
	# Assert
	assert_eq(total_income, 150, "Renda total dos 3 soma 150.")


# Lista vazia e renda negativa
func test_renda_negativa_e_lista_vazia() -> void:
	
	# Arrange
	var only_neutral_and_enemy: Array = [0, 0, 2, 2]
	
	# Act
	var income_no_allies: int = EconomyRules.calculate_turn_income(only_neutral_and_enemy, 1, 50)
	var income_empty: int = EconomyRules.calculate_turn_income([], 1, 50)
	var income_negative_rate: int = EconomyRules.calculate_turn_income([1, 1], 1, -50)
	
	# Assert
	assert_eq(income_no_allies, 0, "Neutras não geram renda.")
	assert_eq(income_empty, 0, "Vazio retorna null.")
	assert_eq(income_negative_rate, 0, "Taxa não pode ser negativa.")


# Compra adequada de uma unidade, saldo disponível
func test_compra_adequada() -> void:
	
	# Arrange
	var current_funds: int = 250
	var catalog_costs: Array = [50, 100, 200]
	
	# Act
	var result: Dictionary = EconomyRules.process_unit_purchase(current_funds, catalog_costs, 1, false)
	
	# Assert: Aprova a compra e desconta 100 do saldo
	assert_true(result["can_purchase"], "Compra liberada se houver saldo")
	assert_eq(result["remaining_funds"], 150, "Redução do saldo para 150 (de 250)")
	assert_eq(result["cost"], 100, "Custo de 100 aplicado")


# Compra sem fundos
func test_compr_sem_fundos() -> void:
	
	# Arrange
	var current_funds: int = 80
	var catalog_costs: Array = [100]
	
	# Act
	var result: Dictionary = EconomyRules.process_unit_purchase(current_funds, catalog_costs, 0, false)
	
	# Assert
	assert_false(result["can_purchase"], "Não há saldo necessário")
	assert_eq(result["remaining_funds"], 80, "Não modifica saldo pois não houve compra")
	assert_eq(result["reason"], "INSUFFICIENT_FUNDS")


# Índice fora do catálogo
func test_indice_extremo_catalogo() -> void:
	
	# Arrange
	var catalog_costs: Array = [100, 150]
	
	# Act
	var res_neg_idx: Dictionary = EconomyRules.process_unit_purchase(500, catalog_costs, -1, false)
	var res_out_idx: Dictionary = EconomyRules.process_unit_purchase(500, catalog_costs, 99, false)
	var res_occupied: Dictionary = EconomyRules.process_unit_purchase(500, catalog_costs, 0, true)
	
	# Assert
	assert_false(res_neg_idx["can_purchase"], "Rejeitar indice negativo")
	assert_eq(res_neg_idx["reason"], "INVALID_INDEX")
	assert_false(res_out_idx["can_purchase"], "Rejeitar fora do catálogo")
	assert_false(res_occupied["can_purchase"], "Unidade precisa sair da estrutura para comprar outra.")
	assert_eq(res_occupied["reason"], "TILE_OCCUPIED")
