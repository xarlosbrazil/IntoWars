extends GutTest

# Testes de combate e vida (CombatRules)
# 1. Dano aplicado
# 2. Dano elimina unidade
# 3. Vida negativa
# 4. Ataque à distância

# Ataque comum que tira vida mas não destrói a unidade
func test_aplicar_dano() -> void:
	
	# Arrange: cria "unidade"
	var current_hp: int = 5
	var max_hp: int = 5
	var damage: int = 2
	
	# Act
	var result: Dictionary = CombatRules.calculate_damage_result(current_hp, max_hp, damage)
	
	# Assert
	assert_eq(result["new_hp"], 1, "O HP cai de 5 para 3.")
	assert_eq(result["damage_applied"], 2, "O dano aplicado precisa ser 2.")
	assert_false(result["is_defeated"], "Unidade não morre")


# Dano letal
func test_dano_letal() -> void:
	
	# Arrange: cria unidade
	var current_hp: int = 2
	var max_hp: int = 3
	var damage: int = 2
	
	# Act
	var result: Dictionary = CombatRules.calculate_damage_result(current_hp, max_hp, damage)
	
	# Assert
	assert_eq(result["new_hp"], 0, "HP deve zerar")
	assert_true(result["is_defeated"], "Valida derrota do inimigo, is_defeated=true")


# HP não pode ficar negativo
func test_hp_negativo() -> void:
	
	# Arrange: 
	var current_hp: int = 3
	var max_hp: int = 3
	var damage: int = 100
	
	# Act
	var result: Dictionary = CombatRules.calculate_damage_result(current_hp, max_hp, damage)
	
	# Assert
	assert_eq(result["new_hp"], 0, "O HP não pode ficar inferior a 0")
	assert_true(result["is_defeated"], "Valida derrota do inimigo, is_defeated=true")

# Ataque à distância respeita regras de alcance
func test_ataque_a_distancia_valido() -> void:
	
	# Arrange
	var attacker_pos := Vector2i(2, 2)
	var target_pos := Vector2i(2, 4)
	var attack_range: int = 2
	
	# Act
	var can_attack: bool = CombatRules.can_unit_attack_target(attacker_pos, target_pos, attack_range, false, true)
	
	# Assert
	assert_true(can_attack, "Permite ataque")
