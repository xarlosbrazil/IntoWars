extends Node3D

signal faction_changed(new_faction: int)

@export_group("Building Stats")
@export var building_name: String = "City"
@export var is_hq: bool = false
@export var max_capture_points: int = 10

# Factions: 0 = Neutral, 1 = Player, 2 = Enemy
@export var faction: int = 0:
	set(val):
		faction = val
		faction_changed.emit(faction)

var grid_position: Vector2i = Vector2i.ZERO
var current_capture_points: int = 10

func _ready() -> void:
	current_capture_points = max_capture_points
	var sprite = get_node_or_null("Sprite3D")
	if sprite and sprite is Sprite3D:
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	update_visuals()

func capture(capturing_faction: int, amount: int) -> void:
	if faction == capturing_faction:
		return
		
	current_capture_points = clamp(current_capture_points - amount, 0, max_capture_points)
	print(building_name, " capture progress: ", current_capture_points, "/", max_capture_points)
	
	if current_capture_points <= 0:
		faction = capturing_faction
		current_capture_points = max_capture_points
		print(building_name, " CAPTURED BY FACTION ", faction)
		
	update_visuals()

func update_visuals() -> void:
	var sprite = get_node_or_null("Sprite3D")
	if sprite and sprite is Sprite3D:
		match faction:
			0: sprite.modulate = Color(0.8, 0.8, 0.8) # Neutral
			1: sprite.modulate = Color(0.4, 0.6, 1.0) # Player
			2: sprite.modulate = Color(1.0, 0.4, 0.4) # Enemy
