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
	# GARANTIA FÍSICA: Força o nó do prédio a estar visível e em escala padrão de fábrica
	visible = true
	scale = Vector3.ONE

	# BUSCA RECURSIVA: Encontra o Sprite3D em qualquer profundidade da árvore
	var sprite: Sprite3D = _find_sprite_recursive(self)
	
	print("DEBUG [Building ready]: Name = ", name, " | Resource = ", building_data, " | Sprite3D found = ", sprite != null)
	
	if sprite:
		# GARANTIA DE POSICIONAMENTO E ESCALA: Corrige qualquer erro de offset/escala salvo no editor por engano
		sprite.position = Vector3.ZERO
		sprite.scale = Vector3.ONE
		sprite.pixel_size = 0.01 # Padrão de escala da engine
		
		# GARANTIA DE ILUMINAÇÃO: Desliga a reação à sombra para o sprite não ficar preto no vazio do cenário
		sprite.shaded = false
		
		if building_data:
			building_name = building_data.get("building_name")
			
			if not is_hq:
				var d_hq = building_data.get("is_hq")
				if d_hq != null:
					is_hq = bool(d_hq)
			
			var d_cap = building_data.get("max_capture_points")
			if d_cap != null: 
				max_capture_points = int(d_cap)
			
			var d_inc = building_data.get("income_contribution")
			if d_inc != null: 
				income_contribution = int(d_inc)
			
			var d_tex = building_data.get("sprite_texture")
			if d_tex != null and d_tex is Texture2D:
				sprite.texture = d_tex
				
		# GARANTIA VISUAL: Se estiver sem textura, tenta o icon.svg ou gera um castelo 3D de fallback
		if sprite.texture == null:
			var fallback_tex = load("res://icon.svg")
			if fallback_tex:
				sprite.texture = fallback_tex
			else:
				# GERAÇÃO 3D DE RESERVA: Cria um cilindro/cone de castelo físico se o projeto não tiver imagens
				var fallback_mesh = MeshInstance3D.new()
				var cylinder = CylinderMesh.new()
				cylinder.top_radius = 0.0
				cylinder.bottom_radius = 0.3
				cylinder.height = 0.6
				fallback_mesh.mesh = cylinder
				
				var mat = StandardMaterial3D.new()
				match faction:
					0: mat.albedo_color = Color(0.8, 0.8, 0.8)
					1: mat.albedo_color = Color(0.4, 0.6, 1.0)
					2: mat.albedo_color = Color(1.0, 0.4, 0.4)
				fallback_mesh.material_override = mat
				
				fallback_mesh.position.y = 0.3
				add_child(fallback_mesh)
			
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		if sprite.texture:
			sprite.offset = Vector2(0, sprite.texture.get_size().y / 2.0)
			
	current_capture_points = max_capture_points
	update_visuals()


func _find_sprite_recursive(node: Node) -> Sprite3D:
	if node is Sprite3D:
		return node
	for child in node.get_children():
		var result = _find_sprite_recursive(child)
		if result:
			return result
	return null


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
	var sprite: Sprite3D = _find_sprite_recursive(self)
	if sprite:
		match faction:
			0: sprite.modulate = Color(0.8, 0.8, 0.8) # Neutral
			1: sprite.modulate = Color(0.4, 0.6, 1.0) # Player
			2: sprite.modulate = Color(1.0, 0.4, 0.4) # Enemy
