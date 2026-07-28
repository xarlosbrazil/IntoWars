extends Resource
class_name BuildingData

@export_group("Identity")
@export var building_name: String = "City"
@export var sprite_texture: Texture2D # Arraste a pixel art do prédio aqui

@export_group("Stats")
@export var is_hq: bool = false
@export var max_capture_points: int = 10
@export var income_contribution: int = 50
