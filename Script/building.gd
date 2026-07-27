extends Node3D

signal faction_changed(new_faction: int)

@export var building_data: Resource

# Fallback default values
var building_name: String = "City"
var is_hq: bool = false
var max_capture_points: int = 10
var income_contribution: int = 50

@export var faction: int = 0:
	set(val):
		faction = val
		faction_changed.emit(faction)

var grid_position: Vector2i = Vector2i.ZERO
var current_capture_points: int = 10


func _ready() -> void:
	# Programação Defensiva: Só consome do recurso se o valor não for nulo (Nil) [1, 2]
	if building_data:
		var d_name = building_data.get("building_name")
		if d_name != null: building_name = d_name
		
		var d_hq = building_data.get("is_hq")
		if d_hq != null: is_hq = d_hq
		
		var d_cap = building_data.get("max_capture_points")
		if d_cap != null: max_capture_points = d_cap
		
		var d_inc = building_data.get("income_contribution")
		if d_inc != null: income_contribution = d_inc
		
		var d_tex = building_data.get("sprite_texture")
		var sprite = get_node_or_null("Sprite3D")
		if sprite and sprite is Sprite3D and d_tex != null:
			sprite.texture = d_tex
			
	current_capture_points = max_capture_points
	
	var sprite = get_node_or_null("Sprite3D")
	if sprite and sprite is Sprite3D:
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		if sprite.texture:
			sprite.offset = Vector2(0, sprite.texture.get_size().y / 2.0)
			
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
