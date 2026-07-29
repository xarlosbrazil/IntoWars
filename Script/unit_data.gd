extends Resource
class_name UnitData

@export_group("Identity")

@export var unit_name: String = "Soldier"
# Arraste o Frame A da pixel art
@export var sprite_frame_a: Texture2D 
# Arraste o Frame B da pixel art (ligeiramente diferente para ciclar)
@export var sprite_frame_b: Texture2D 

@export_group("Stats")
@export_range(1, 10) var max_hp: int = 3
@export_range(1, 10) var movement_range: int = 3
@export_range(1, 10) var attack_damage: int = 1
@export_range(1, 5) var attack_range: int = 1

@export_group("Economy")
## Custo em funds para construir esta unidade na loja.
@export_range(0, 999, 5) var cost: int = 100
