extends Resource
class_name BuildingData

@export_group("Identity")
@export var building_name: String = "City"
@export var sprite_texture: Texture2D # Arraste a pixel art do prédio aqui
## Escala de pixel do sprite 3D (0.025 é ideal para artes 32x32 em tiles de tamanho 1.0).
@export_range(0.005, 0.1, 0.001) var pixel_size: float = 0.025
## Deslocamento vertical Y (em unidades 3D) para ajustar a altura da estrutura no tabuleiro.
@export var sprite_offset_y: float = 0.0

@export_group("Stats")
@export var is_hq: bool = false
@export var max_capture_points: int = 10
@export var income_contribution: int = 50
