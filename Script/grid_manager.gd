extends Node3D
class_name GridManager

# --- MAP LAYOUT CONFIGURATION ---
@export_group("Map Layout (ASCII)")
@export_multiline var map_layout: String = """
1.0 1.0 1.0 1.0 1.0 1.0
1.0 1.5 1.5 1.0 1.0 1.0
1.0 0.0 0.0 1.0 1.0 1.0
1.0 2.0 2.0 1.0 1.0 1.0
1.0 1.0 1.0 1.0 1.0 1.0
"""

# --- PROCEDURAL GENERATION ---
@export_group("Procedural Generation - General")
# If true, ignores ASCII layout and generates a random islands/hills map based on Simplex noise.
@export var use_procedural: bool = true
# The horizontal (X, Z) size of the procedurally generated grid.
@export var map_size: Vector2i = Vector2i(50, 50)
# The minimum acceptable ratio of solid land. 0.35 means at least 35% of the map must be land.
@export_range(0.1, 0.8, 0.05) var min_playable_ratio: float = 0.35
# Max attempts to generate random seeds before giving up if HQ paths are blocked.
@export_range(10, 200, 5) var max_generation_attempts: int = 100

@export_group("Procedural Generation - Seed")
# If true, generates a random seed every play. If false, uses the custom seed specified below.
@export var use_random_seed: bool = true
# Fixed seed for tactical testing.
@export var custom_seed: int = 12345

@export_group("Procedural Generation - Noise Settings")
# Noise frequency. Smaller values generate larger, smoother islands; larger values fragment the map into tiny archipelagos.
@export_range(0.01, 0.3, 0.005) var noise_frequency: float = 0.065
# Fractal octaves. Larger values add detailed, rugged mountain ridges.
@export_range(1, 6, 1) var noise_octaves: int = 4
# Fractal lacunarity. Controls the ruggedness of mountain peaks.
@export_range(1.0, 4.0, 0.1) var noise_lacunarity: float = 2.0
# Fractal gain. Larger values stretch the heights higher.
@export_range(0.1, 1.0, 0.05) var noise_gain: float = 0.45

@export_group("Procedural Generation - Height Thresholds")
# Noise below this limit is treated as deep water/abyss, skipping block generation.
@export_range(-1.0, 1.0, 0.01) var water_threshold: float = -0.22
# Noise threshold for generating a low hill (height 1.5).
@export_range(-1.0, 1.0, 0.01) var height_1_5_threshold: float = -0.05
# Noise threshold for generating a medium hill (height 2.0).
@export_range(-1.0, 1.0, 0.01) var height_2_0_threshold: float = 0.1
# Noise threshold for generating a medium-high hill (height 2.5).
@export_range(-1.0, 1.0, 0.01) var height_2_5_threshold: float = 0.22
# Noise threshold for generating a medium mountain (height 3.0).
@export_range(-1.0, 1.0, 0.01) var height_3_0_threshold: float = 0.35
# Noise threshold for generating a high mountain (height 3.5).
@export_range(-1.0, 1.0, 0.01) var height_3_5_threshold: float = 0.5
# Noise threshold for generating a peak mountain (height 4.0).
@export_range(-1.0, 1.0, 0.01) var height_4_0_threshold: float = 0.65

# --- VISUAL CONFIGURATIONS ---
@export_group("Block Visuals")
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
# Duration in seconds for a unit to walk from one tile to another.
@export_range(0.1, 2.0, 0.05) var move_duration: float = 0.45
# Maximum height of the jump arc when scaling elevations (0.0 slides flat).
@export_range(0.0, 2.0, 0.05) var jump_peak: float = 0.35
# Maximum step height difference a unit can climb (e.g., 1.1 allows 1.0 step, blocks 1.5).
@export_range(0.1, 3.0, 0.1) var max_climb_height: float = 1.1

# --- ECONOMY SETTINGS ---
@export_group("Economy (Advance Wars)")
# Starting funds available in the player's cofre.
@export var initial_player_funds: int = 100
# Amount of funds received at start of turn per owned city.
@export var income_per_building: int = 50
# Funds cost to deploy a new Mech on an empty factory.
@export var unit_spawn_cost: int = 100

# --- INSTANTIATION SCENES ---
@export_group("Instantiation Scenes")
@export var unit_scene: PackedScene
@export var building_scene: PackedScene


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


func create_grid_material() -> void:
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	render_mode blend_mix, depth_draw_always;
	
	uniform vec4 tile_color : source_color;
	uniform vec4 border_color : source_color;
	uniform float border_thickness;
	uniform float alpha : hint_range(0.0, 1.0) = 1.0;
	
	uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
	uniform float highlight_strength : hint_range(0.0, 1.0) = 0.0;
	
	varying vec3 local_pos;
	varying vec3 local_normal;
	void vertex() { local_pos = VERTEX; local_normal = NORMAL; }
	void fragment() {
		bool is_top_face = local_normal.y > 0.5;
		float half_size = 0.5;
		bool is_border = abs(local_pos.x) > (half_size - border_thickness) || abs(local_pos.z) > (half_size - border_thickness);
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
				
				# CONNECTIVITY VALIDATION (Flood Fill)
				if is_path_possible(p_hq, e_hq) and is_path_possible(p_hq, city):
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


# Flood Fill connectivity validator
func is_path_possible(start: Vector2i, target: Vector2i) -> bool:
	var queue: Array = [start]
	var visited: Dictionary = {start: true}
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	while not queue.is_empty():
		var current = queue.pop_front()
		if current == target:
			return true
			
		for dir in directions:
			var next = current + dir
			if grid_cells.has(next) and not visited.has(next):
				var h1 = grid_cells[current].get_meta("height")
				var h2 = grid_cells[next].get_meta("height")
				if abs(h1 - h2) <= max_climb_height:
					visited[next] = true
					queue.append(next)
					
	return false


func spawn_block(x: int, z: int, height: float) -> void:
	var block = StaticBody3D.new()
	block.position = Vector3(x, height / 2.0, z)
	block.set_meta("grid_pos", Vector2i(x, z))
	block.set_meta("base_color", Color.WHITE)
	block.set_meta("base_strength", 0.0)
	block.set_meta("height", height)
	
	add_child(block)
	grid_cells[Vector2i(x, z)] = block

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, height, 1)
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = block_material.duplicate()
	block.add_child(mesh_instance)

	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1, height, 1)
	collision_shape.shape = box_shape
	block.add_child(collision_shape)


func spawn_building(coords: Vector2i, name: String, faction: int, is_hq: bool):
	if not building_scene or not grid_cells.has(coords): return null
	var height = grid_cells[coords].get_meta("height")
	var b_instance = building_scene.instantiate()
	if b_instance:
		b_instance.position = Vector3(coords.x, height, coords.y)
		b_instance.grid_position = coords
		b_instance.building_name = name
		b_instance.faction = faction
		b_instance.is_hq = is_hq
		add_child(b_instance)
		active_buildings[coords] = b_instance
		return b_instance
	return null


# CORREÇÃO: Removida a tipagem estrita de retorno de classe "GridUnit"
func spawn_unit_node(coords: Vector2i, name: String, is_enemy: bool, hp: int):
	if not unit_scene or not grid_cells.has(coords): return null
	var height = grid_cells[coords].get_meta("height")
	var unit_instance = unit_scene.instantiate()
	if unit_instance:
		unit_instance.position = Vector3(coords.x, height, coords.y)
		unit_instance.grid_position = coords
		unit_instance.unit_name = name
		unit_instance.is_enemy = is_enemy
		unit_instance.max_hp = hp
		unit_instance.current_hp = hp
		add_child(unit_instance)
		active_units[coords] = unit_instance
		return unit_instance
	return null


# --- BFS ALGORITHMS (Dynamic Cast-Free) ---

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


# CORREÇÃO: Assinatura livre de tipo estrito de argumento ": GridUnit"
func move_unit_to_tile(unit, target_coords: Vector2i) -> Tween:
	var old_coords = unit.grid_position
	unit.grid_position = target_coords
	
	var start_height = grid_cells[old_coords].get_meta("height") if grid_cells.has(old_coords) else unit.position.y
	var target_height = grid_cells[target_coords].get_meta("height")
	var target_pos = Vector3(target_coords.x, target_height, target_coords.y)
	
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
