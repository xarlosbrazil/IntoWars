extends Resource
class_name UnitData

@export_group("Identity")

@export var unit_name: String = "Soldier"
# Arraste o Frame A da pixel art
@export var sprite_frame_a: Texture2D 
# Arraste o Frame B da pixel art (ligeiramente diferente para ciclar)
@export var sprite_frame_b: Texture2D 
## Escala de pixel do sprite 3D (0.025 é ideal para artes 32x32 em tiles de tamanho 1.0).
@export_range(0.005, 0.1, 0.001) var pixel_size: float = 0.025 
## Deslocamento vertical Y (em unidades 3D) para ajustar a altura do sprite sobre a casa do tabuleiro.
@export var sprite_offset_y: float = 0.0 

@export_group("Animation (Idle Hop)")
## Intervalo em segundos entre a troca do Frame A e Frame B (padrão: 0.35s).
@export_range(0.05, 2.0, 0.05) var animation_interval: float = 0.35
## Elevação extra em pixels (offset Y) no Frame B para a animação de pulo (0.0 desativa a elevação física).
@export_range(0.0, 20.0, 0.5) var hop_pixel_offset: float = 2.0 

@export_group("Stats")
@export_range(1, 10) var max_hp: int = 3
@export_range(1, 10) var movement_range: int = 3
@export_range(1, 10) var attack_damage: int = 1
@export_range(1, 5) var attack_range: int = 1

@export_group("Economy")
## Custo em funds para construir esta unidade na loja.
@export_range(0, 999, 5) var cost: int = 100
