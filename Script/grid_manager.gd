extends Node3D
class_name GridManager

# --- PRELOAD DIRETO ---
const Pathfinder = preload("res://Script/grid_pathfinder.gd")

# --- MAP LAYOUT CONFIGURATION ---
@export_group("Map Layout (ASCII)")
## Multiline text representation of the grid.
## Use float numbers (e.g. 1.0, 1.5, 2.0) for block heights, or '0' / '.' for empty abysses.
@export_multiline var map_layout: String = """
1.0 1.0 1.0 1.0 1.0 1.0
1.0 1.5 1.5 1.0 1.0 1.0
1.0 0.0 0.0 1.0 1.0 1.0
1.0 2.0 2.0 1.0 1.0 1.0
1.0 1.0 1.0 1.0 1.0 1.0
"""

# --- PROCEDURAL GENERATION ---
@export_group("Procedural Generation - General")
## If enabled, the generator ignores the ASCII layout and designs a random island-based landscape.
@export var use_procedural: bool = true
## The grid dimensions (Width, Depth) of the procedurally generated board.
@export var map_size: Vector2i = Vector2i(50, 50)
## The minimum required percentage of solid land on the board. Maps with too much water are rejected and regenerated.
@export_range(0.1, 0.8, 0.05) var min_playable_ratio: float = 0.35
## The maximum number of attempts the generator will make to find a fully connected map before giving up.
@export_range(10, 200, 5) var max_generation_attempts: int = 100

@export_group("Procedural Generation - Seed")
## If enabled, generates a completely random world seed every play. Disable to lock a specific seed below.
@export var use_random_seed: bool = true
## Fixed seed used for generation if Use Random Seed is disabled. Useful for securing a persistent map layout.
@export var custom_seed: int = 12345

@export_group("Procedural Generation - Noise Settings")
## Determines the scale of the terrain hills. Smaller values create massive continuous islands, larger values fragment landmass.
@export_range(0.01, 0.3, 0.005) var noise_frequency: float = 0.065
## Number of detailed layers of fractal noise. Higher values add jagged, rugged, and realistic mountain ridges.
@export_range(1, 6, 1) var noise_octaves: int = 4
## Fractal lacunarity. Controls the scale gap between detail octaves, adjusting the ruggedness of peak formations.
@export_range(1.0, 4.0, 0.1) var noise_lacunarity: float = 2.0
## Fractal gain. Controls the strength of high-frequency detail octaves, stretching mountain crests upwards.
@export_range(0.1, 1.0, 0.05) var noise_gain: float = 0.45

@export_group("Procedural Generation - Height Thresholds")
## Noise values below this threshold are treated as ocean/deep abysm, skipping block generation.
@export_range(-1.0, 1.0, 0.01) var water_threshold: float = -0.22
## Noise threshold for elevating a block to a low hill (Height 1.5).
@export_range(-1.0, 1.0, 0.01) var height_1_5_threshold: float = -0.05
## Noise threshold for elevating a block to a medium hill (Height 2.0).
@export_range(-1.0, 1.0, 0.01) var height_2_0_threshold: float = 0.1
## Noise threshold for elevating a block to a medium-high hill (Height 2.5).
@export_range(-1.0, 1.0, 0.01) var height_2_5_threshold: float = 0.22
## Noise threshold for elevating a block to a medium mountain (Height 3.0).
@export_range(-1.0, 1.0, 0.01) var height_3_0_threshold: float = 0.35
## Noise threshold for elevating a block to a high mountain (Height 3.5).
@export_range(-1.0, 1.0, 0.01) var height_3_5_threshold: float = 0.5
## Noise threshold for elevating a block to the highest peak mountain (Height 4.0).
@export_range(-1.0, 1.0, 0.01) var height_4_0_threshold: float = 0.65

# --- VISUAL CONFIGURATIONS ---
@export_group("Block Visuals")
## Tamanho dos tiles (largura e profundidade) no espaço 3D.
@export_range(0.5, 3.0, 0.05) var tile_size: float = 1.0:
	set(val):
		tile_size = val
		update_shader_settings()

@export var tile_color: Color = Color(0.35, 0.35, 0.35):
	set(val):
		tile_color = val
		update_shader_settings()

@export var border_color: Color = Color(0.15, 0.15, 0.15):
	set(val):
		border_color = val
		update_shader_settings()

@export_range(0.0, 0.2, 0.005) var border_thickness: float = 0.04:
	set(val):
		border_thickness = val
		update_shader_settings()

# --- HIGHLIGHT COLORS ---
@export_group("Highlight Colors")
@export var movement_highlight_color: Color = Color(0.18, 0.45, 0.85)
@export_range(0.0, 1.0, 0.05) var movement_highlight_strength: float = 0.5

@export var attack_highlight_color: Color = Color(0.9, 0.4, 0.1)
@export_range(0.0, 1.0, 0.05) var attack_highlight_strength: float = 0.6

@export var danger_highlight_color: Color = Color(1.0, 0.2, 0.2)
@export_range(0.0, 1.0, 0.05) var danger_highlight_strength: float = 0.6

# --- VISUAL MOVEMENT ---
@export_group("Visual Movement (Juice)")
## Duration in seconds for a unit to walk from one tile to another.
@export_range(0.1, 2.0, 0.05) var move_duration: float = 0.45
## Maximum height of the jump arc when scaling elevations (0.0 slides flat).
@export_range(0.0, 2.0, 0.05) var jump_peak: float = 0.35
## Maximum step height difference a unit can climb (e.g., 1.1 allows 1.0 step, blocks 1.5).
@export_range(0.1, 3.0, 0.1) var max_climb_height: float = 1.1

# --- ECONOMY SETTINGS ---
@export_group("Economy (Advance Wars)")
## Starting funds available in the player's cofre.
@export var initial_player_funds: int = 100
## Amount of funds received at start of turn per owned city.
@export var income_per_building: int = 50
## Funds cost to deploy a new Mech on an empty factory.
@export var unit_spawn_cost: int = 100

# --- INSTANTIATION SCENES ---
@export_group("Instantiation Scenes")
@export var unit_scene: PackedScene
@export var building_scene: PackedScene

# --- CUSTOM 2.5D TILE SPRITES ---
@export_group("Custom 2.5D Tile Sprites")
## Se ativo, oculta as caixas verdes 3D procedurais e exibe os sprites 2.5D artesanais completos.
@export var hide_procedural_boxes: bool = true
## Sprite 2.5D padrão para todos os tiles do tabuleiro (ex: Bloco de Grama 32x32).
@export var default_tile_sprite: Texture2D

# --- TILE TOP OVERLAYS ---
@export_group("Tile Top Overlays (Test)")
## Arraste aqui uma textura 2.5D de topo (ex: slime_pool.png) para testar no tabuleiro.
@export var test_tile_overlay_texture: Texture2D
## Coordenada de grid para aplicar a textura de teste de topo.
@export var test_tile_overlay_coords: Vector2i = Vector2i(2, 2)


# --- GRID DATA STRUCTURES ---
var grid_cells: Dictionary = {}
var active_units: Dictionary = {}
var active_buildings: Dictionary = {}
var block_material: ShaderMaterial


func _ready() -> void:
	create_grid_material()
	update_shader_settings()


func update_shader_settings() -> void:
	if block_material:
		block_material.set_shader_parameter("tile_color", tile_color)
		block_material.set_shader_parameter("border_color", border_color)
		block_material.set_shader_parameter("border_thickness", border_thickness)
		block_material.set_shader_parameter("tile_size", tile_size)
	for block in grid_cells.values():
		if block and is_instance_valid(block):
			var mesh_instance = block.get_node_or_null("MeshInstance3D")
			if mesh_instance and mesh_instance.material_override:
				var mat: ShaderMaterial = mesh_instance.material_override
				mat.set_shader_parameter("tile_color", tile_color)
				mat.set_shader_parameter("border_color", border_color)
				mat.set_shader_parameter("border_thickness", border_thickness)
				mat.set_shader_parameter("tile_size", tile_size)


func create_grid_material() -> void:
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	render_mode blend_mix, depth_draw_always;
	
	uniform vec4 tile_color : source_color;
	uniform vec4 border_color : source_color;
	uniform float border_thickness;
	uniform float tile_size = 1.0;
	uniform float alpha : hint_range(0.0, 1.0) = 1.0;
	
	uniform float neighbor_px = 0.0;
	uniform float neighbor_nx = 0.0;
	uniform float neighbor_pz = 0.0;
	uniform float neighbor_nz = 0.0;
	
	uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
	uniform float highlight_strength : hint_range(0.0, 1.0) = 0.0;
	
	varying vec3 local_pos;
	varying vec3 local_normal;
	void vertex() { local_pos = VERTEX; local_normal = NORMAL; }
	void fragment() {
		bool is_top_face = local_normal.y > 0.5;
		float half_size = tile_size * 0.5;
		
		float thick_px = mix(border_thickness, border_thickness * 0.5, neighbor_px);
		float thick_nx = mix(border_thickness, border_thickness * 0.5, neighbor_nx);
		float thick_pz = mix(border_thickness, border_thickness * 0.5, neighbor_pz);
		float thick_nz = mix(border_thickness, border_thickness * 0.5, neighbor_nz);

		bool is_border = (local_pos.x > half_size - thick_px) ||
		                 (local_pos.x < -half_size + thick_nx) ||
		                 (local_pos.z > half_size - thick_pz) ||
		                 (local_pos.z < -half_size + thick_nz);

		vec3 base_color = tile_color.rgb;
		if (is_top_face) { base_color = mix(base_color, highlight_color.rgb, highlight_strength * 0.6); }
		if (is_top_face && is_border) { ALBEDO = border_color.rgb; } else { ALBEDO = base_color; }
		ALPHA = alpha;
	}
	"""
	block_material = ShaderMaterial.new()
	block_material.shader = shader


# Validates map playability before generating the board
func generate_board() -> void:
	grid_cells.clear()
	active_units.clear()
	active_buildings.clear()
	
	if use_procedural:
		var attempts = 0
		while attempts < max_generation_attempts:
			generate_procedural_board()
			
			var valid_coords = grid_cells.keys()
			
			# Ensures map size meets minimum density requirement
			if valid_coords.size() > (map_size.x * map_size.y * min_playable_ratio):
				var p_hq = valid_coords[0]
				var e_hq = valid_coords[valid_coords.size() - 1]
				var middle_idx = valid_coords.size() / 2
				var city = valid_coords[middle_idx]
				
				# Connectivity check delegates tasks to GridPathfinder
				if Pathfinder.is_path_possible(grid_cells, p_hq, e_hq, max_climb_height) and Pathfinder.is_path_possible(grid_cells, p_hq, city, max_climb_height):
					print("Procedural map approved successfully after ", attempts, " attempts!")
					break
					
			# Discards map and regenerates with new seed if connectivity check fails
			print("Invalid map (trapped islands detected). Regenerating seed...")
			for block in get_children():
				block.free()
			grid_cells.clear()
			attempts += 1
	else:
		generate_ascii_board()

	update_all_block_neighbors()

	if test_tile_overlay_texture:
		set_tile_top_texture(test_tile_overlay_coords, test_tile_overlay_texture)


func update_all_block_neighbors() -> void:
	for coords in grid_cells.keys():
		var block = grid_cells[coords]
		if not block or not is_instance_valid(block):
			continue
			
		var height: float = block.get_meta("height")
		var mesh_instance = block.get_node_or_null("MeshInstance3D")
		if not mesh_instance or not mesh_instance.material_override:
			continue
			
		var mat: ShaderMaterial = mesh_instance.material_override
		
		var px = coords + Vector2i(1, 0)
		var nx = coords + Vector2i(-1, 0)
		var pz = coords + Vector2i(0, 1)
		var nz = coords + Vector2i(0, -1)
		
		var has_px = grid_cells.has(px) and abs(float(grid_cells[px].get_meta("height")) - height) < 0.01
		var has_nx = grid_cells.has(nx) and abs(float(grid_cells[nx].get_meta("height")) - height) < 0.01
		var has_pz = grid_cells.has(pz) and abs(float(grid_cells[pz].get_meta("height")) - height) < 0.01
		var has_nz = grid_cells.has(nz) and abs(float(grid_cells[nz].get_meta("height")) - height) < 0.01
		
		mat.set_shader_parameter("neighbor_px", 1.0 if has_px else 0.0)
		mat.set_shader_parameter("neighbor_nx", 1.0 if has_nx else 0.0)
		mat.set_shader_parameter("neighbor_pz", 1.0 if has_pz else 0.0)
		mat.set_shader_parameter("neighbor_nz", 1.0 if has_nz else 0.0)


# Aplica uma textura de topo (Overlay 2.5D deitada) sobre um tile do tabuleiro (ex: Slime Pool, Terrenos Especializados)
func set_tile_top_texture(coords: Vector2i, texture: Texture2D, pixel_size_override: float = 0.025) -> void:
	if not grid_cells.has(coords):
		return
		
	var block = grid_cells[coords]
	var top_sprite: Sprite3D = block.get_node_or_null("TopOverlaySprite")
	
	if not texture:
		if top_sprite:
			top_sprite.queue_free()
		return
		
	if not top_sprite:
		top_sprite = Sprite3D.new()
		top_sprite.name = "TopOverlaySprite"
		top_sprite.rotation_degrees = Vector3(-90, 0, 0) # Deitado plano sobre o topo do bloco
		top_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		top_sprite.shaded = false
		block.add_child(top_sprite)
		
	top_sprite.texture = texture
	top_sprite.pixel_size = pixel_size_override
	var height: float = block.get_meta("height")
	# Posiciona exatamente na superfície do topo do bloco 3D
	top_sprite.position = Vector3(0.0, height / 2.0 + 0.001, 0.0)


# Define um Sprite 2.5D Completo para um tile específico (ex: Slime Pool, Ruínas, Terrenos Customizados)
func set_custom_tile_sprite(coords: Vector2i, texture: Texture2D, pixel_size_override: float = 0.025) -> void:
	if not grid_cells.has(coords):
		return
	var block = grid_cells[coords]
	var mesh_instance = block.get_node_or_null("MeshInstance3D")
	var tile_sprite: Sprite3D = block.get_node_or_null("TileSprite")
	
	if texture and tile_sprite:
		tile_sprite.texture = texture
		tile_sprite.pixel_size = pixel_size_override
		tile_sprite.visible = true
		if mesh_instance and hide_procedural_boxes:
			mesh_instance.visible = false


func generate_ascii_board() -> void:
	var lines = map_layout.strip_edges().split("\n")
	for z in range(lines.size()):
		var line = z
		var tokens = lines[z].strip_edges().split(" ")
		for x in range(tokens.size()):
			var token = tokens[x]
			if token == "." or token == "0":
				continue
				
			var height: float = 1.0
			if token == "#":
				height = 1.0
			elif token.is_valid_float():
				height = token.to_float()
				
			spawn_block(x, z, height)


# Procedural generation
func generate_procedural_board() -> void:
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = noise_frequency
	
	if use_random_seed:
		noise.seed = randi()
	else:
		noise.seed = custom_seed
	
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = noise_octaves
	noise.fractal_lacunarity = noise_lacunarity
	noise.fractal_gain = noise_gain
	
	for x in range(map_size.x):
		for z in range(map_size.y):
			var n_val = noise.get_noise_2d(x, z)
			
			if n_val < water_threshold:
				continue
				
			var height = get_height_from_noise(n_val)
			spawn_block(x, z, height)


# Height translation helper
func get_height_from_noise(n_val: float) -> float:
	if n_val > height_4_0_threshold:
		return 4.0
	elif n_val > height_3_5_threshold:
		return 3.5
	elif n_val > height_3_0_threshold:
		return 3.0
	elif n_val > height_2_5_threshold:
		return 2.5
	elif n_val > height_2_0_threshold:
		return 2.0
	elif n_val > height_1_5_threshold:
		return 1.5
	else:
		return 1.0


func spawn_block(x: int, z: int, height: float) -> void:
	var block = StaticBody3D.new()
	block.position = Vector3(float(x) * tile_size, height / 2.0, float(z) * tile_size)
	block.set_meta("grid_pos", Vector2i(x, z))
	block.set_meta("base_color", Color.WHITE)
	block.set_meta("base_strength", 0.0)
	block.set_meta("height", height)
	
	add_child(block)
	grid_cells[Vector2i(x, z)] = block

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(tile_size, height, tile_size)
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = block_material.duplicate()
	block.add_child(mesh_instance)

	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(tile_size, height, tile_size)
	collision_shape.shape = box_shape
	block.add_child(collision_shape)

	# 3. Sprite 2.5D do Tile Completo (Ilusão de profundidade artesanal)
	var tile_sprite = Sprite3D.new()
	tile_sprite.name = "TileSprite"
	tile_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	tile_sprite.shaded = false
	tile_sprite.pixel_size = 0.025
	tile_sprite.position = Vector3(0.0, height / 2.0, 0.0)
	tile_sprite.visible = false
	block.add_child(tile_sprite)

	if default_tile_sprite:
		tile_sprite.texture = default_tile_sprite
		tile_sprite.visible = true
		if hide_procedural_boxes:
			mesh_instance.visible = false


# MODIFICADO: Função de spawn agora imprime alertas de diagnóstico se as cenas estiverem ausentes no editor
func spawn_building(coords: Vector2i, building_preset: Resource, faction: int, is_hq_override: bool = false) -> Node3D:
	if not building_scene:
		print_rich("[color=yellow]WARNING: 'building_scene' (Building.tscn) is NOT assigned in GridManager's Inspector![/color]")
		return null
		
	if not grid_cells.has(coords):
		print_rich("[color=yellow]WARNING: Cannot spawn building at ", coords, " because the tile does not exist![/color]")
		return null
		
	var height = grid_cells[coords].get_meta("height")
	var b_instance = building_scene.instantiate()
	if b_instance:
		b_instance.building_data = building_preset
		b_instance.position = Vector3(float(coords.x) * tile_size, height, float(coords.y) * tile_size)
		b_instance.grid_position = coords
		b_instance.faction = faction
		
		b_instance.is_hq = is_hq_override
		if is_hq_override:
			b_instance.building_name = "HQ"
			b_instance.max_capture_points = 20
			
		add_child(b_instance)
		active_buildings[coords] = b_instance
		print("Spawned structure: ", b_instance.building_name, " at ", coords)
		return b_instance
	return null


# MODIFICADO: Agora aceita e injeta dinamicamente o recurso UnitData [2]
func spawn_unit_node(coords: Vector2i, unit_preset: Resource, is_enemy: bool) -> Node3D:
	if not unit_scene or not grid_cells.has(coords): return null
	var height = grid_cells[coords].get_meta("height")
	
	var unit_instance = unit_scene.instantiate()
	if unit_instance:
		unit_instance.unit_data = unit_preset # Injeta o recurso
		unit_instance.position = Vector3(float(coords.x) * tile_size, height, float(coords.y) * tile_size)
		unit_instance.grid_position = coords
		unit_instance.is_enemy = is_enemy
		add_child(unit_instance)
		active_units[coords] = unit_instance
		return unit_instance
	return null


# --- BFS ALGORITHMS ---

func calculate_reachable_tiles(start_coords: Vector2i, max_range: int) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var queue: Array = []
	var visited: Dictionary = {}
	queue.append([start_coords, 0])
	visited[start_coords] = true
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not queue.is_empty():
		var current = queue.pop_front()
		var current_coords = current[0]
		var current_cost = current[1]
		if current_cost > 0: reachable.append(current_coords)
		if current_cost < max_range:
			for dir in directions:
				var next_coords = current_coords + dir
				if grid_cells.has(next_coords) and not visited.has(next_coords):
					if not active_units.has(next_coords):
						var current_height = grid_cells[current_coords].get_meta("height")
						var next_height = grid_cells[next_coords].get_meta("height")
						if abs(current_height - next_height) <= max_climb_height:
							visited[next_coords] = true
							queue.append([next_coords, current_cost + 1])
	return reachable


func calculate_attackable_tiles(start_coords: Vector2i, max_range: int) -> Array[Vector2i]:
	var attackable: Array[Vector2i] = []
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for dir in directions:
		for step in range(1, max_range + 1):
			var target = start_coords + (dir * step)
			if grid_cells.has(target) and active_units.has(target):
				var unit = active_units[target]
				if unit.is_enemy:
					attackable.append(target)
	return attackable


# --- VISUAL MANIPULATIONS ---

func apply_tile_visuals(coords: Vector2i, color: Color, strength: float) -> void:
	if grid_cells.has(coords):
		var block = grid_cells[coords]
		var mesh_instance = block.get_node("MeshInstance3D")
		if mesh_instance:
			var mat = mesh_instance.material_override as ShaderMaterial
			mat.set_shader_parameter("highlight_color", color)
			mat.set_shader_parameter("highlight_strength", strength)


func restore_tile_base_state(coords: Vector2i, current_hovered_tile: Vector2i) -> void:
	if grid_cells.has(coords):
		var block = grid_cells[coords]
		var base_color = block.get_meta("base_color")
		var base_strength = block.get_meta("base_strength")
		if coords != current_hovered_tile:
			apply_tile_visuals(coords, base_color, base_strength)


func set_tile_base_state(coords: Vector2i, color: Color, strength: float, current_hovered_tile: Vector2i) -> void:
	if grid_cells.has(coords):
		var block = grid_cells[coords]
		block.set_meta("base_color", color)
		block.set_meta("base_strength", strength)
		if coords != current_hovered_tile:
			apply_tile_visuals(coords, color, strength)


func move_unit_to_tile(unit, target_coords: Vector2i) -> Tween:
	var old_coords = unit.grid_position
	unit.grid_position = target_coords
	
	var start_height = grid_cells[old_coords].get_meta("height") if grid_cells.has(old_coords) else unit.position.y
	var target_height = grid_cells[target_coords].get_meta("height")
	var target_pos = Vector3(float(target_coords.x) * tile_size, target_height, float(target_coords.y) * tile_size)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(unit, "position:x", target_pos.x, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(unit, "position:z", target_pos.z, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if abs(start_height - target_height) > 0.01:
		var half_duration = move_duration / 2.0
		var peak_height = max(start_height, target_height) + jump_peak
		
		var y_tween = create_tween()
		y_tween.tween_property(unit, "position:y", peak_height, half_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		y_tween.tween_property(unit, "position:y", target_pos.y, half_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tween.tween_property(unit, "position:y", target_pos.y, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	return tween


# Backtracking route reconstruction
func calculate_path_to_target(start_coords: Vector2i, target_coords: Vector2i, max_range: int) -> Array[Vector2i]:
	var queue: Array = []
	var visited: Dictionary = {}
	var parents: Dictionary = {}
	
	queue.append([start_coords, 0])
	visited[start_coords] = true
	
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var found = false
	
	while not queue.is_empty():
		var current = queue.pop_front()
		var current_coords = current[0]
		var current_cost = current[1]
		
		if current_coords == target_coords:
			found = true
			break
			
		if current_cost < max_range:
			for dir in directions:
				var next_coords = current_coords + dir
				if grid_cells.has(next_coords) and not visited.has(next_coords):
					if not active_units.has(next_coords) or next_coords == target_coords:
						var current_height = grid_cells[current_coords].get_meta("height")
						var next_height = grid_cells[next_coords].get_meta("height")
						if abs(current_height - next_height) <= max_climb_height:
							visited[next_coords] = true
							parents[next_coords] = current_coords
							queue.append([next_coords, current_cost + 1])
	
	var path: Array[Vector2i] = []
	if found:
		var curr = target_coords
		while curr != start_coords:
			path.append(curr)
			curr = parents[curr]
		path.reverse()
		
	return path
