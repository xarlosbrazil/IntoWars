extends Node3D
class_name GameController

# --- LOCAL STATE MACHINE ---
enum TurnState { 
	PLAYER_TURN,
	ENEMY_RESOLVE,
	ENEMY_PLAN
}

var current_state: TurnState = TurnState.PLAYER_TURN


# --- COMPONENT REFERENCES ---
@onready var input_handler: GridInputHandler = $InputHandler
@onready var grid_manager: GridManager = $GridManager
@onready var ui_manager = $UIManager

# --- ORBITAL CAMERA CONFIGURATION ---
@export_group("Orbital Camera")
# 3D central node acting as orbital pivot for the camera (must be parent of Camera3D).
@export var camera_pivot: Node3D 

# --- FREE CAMERA CONFIGURATIONS ---
@export_group("Free Camera")
# If active, allows the player to navigate freely using WASD and dragging MMB.
@export var enable_free_camera: bool = true
# Camera panning speed when using WASD keys.
@export_range(1.0, 30.0, 0.5) var pan_speed: float = 12.0
# Middle mouse button (MMB) drag sensitivity.
@export_range(0.1, 10.0, 0.05) var drag_sensitivity: float = 3.0

# --- PERFORMANCE OPTIMIZATION ---
@export_group("Optimizations")
# Time interval in seconds between raycast occlusion checks. 
# Increasing this reduces CPU overhead but may cause a slight delay in fading blocking terrain.
@export_range(0.01, 0.5, 0.01) var occlusion_interval: float = 0.08


# --- ECONOMY AND ANIMATION VARIABLES ---
var player_funds: int = 0
var is_animating: bool = false

# Selection states
var selected_unit = null
var selected_building_coords: Vector2i = Vector2i(-999, -999)
var current_reachable_tiles: Array[Vector2i] = []
var current_attackable_tiles: Array[Vector2i] = []
var current_hovered_tile: Vector2i = Vector2i(-999, -999)

# Undo, occlusion history, and performance timers
var turn_history: Array = []
var occluded_blocks: Array = []
var is_dragging_camera: bool = false
var occlusion_timer: float = 0.0


func _ready() -> void:
	player_funds = grid_manager.initial_player_funds
	
	if not camera_pivot:
		camera_pivot = get_node_or_null("CameraPivot")
		if not camera_pivot:
			camera_pivot = find_child("CameraPivot")
			
	var camera = get_viewport().get_camera_3d()
	if camera:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 11.0 
	
	grid_manager.generate_board()
	setup_match_units_and_buildings()
	
	ui_manager.setup_hud(grid_manager.unit_spawn_cost)
	
	input_handler.tile_clicked.connect(_on_tile_clicked)
	input_handler.tile_hovered.connect(_on_tile_hovered)
	
	ui_manager.end_turn_requested.connect(_on_end_turn_requested)
	ui_manager.undo_requested.connect(undo_last_move)
	ui_manager.capture_requested.connect(execute_capture_action)
	ui_manager.deploy_requested.connect(execute_deploy_action)
	
	change_state(TurnState.ENEMY_PLAN)


func _process(delta: float) -> void:
	# Handles free keyboard pan if allowed
	if enable_free_camera and not is_animating:
		handle_keyboard_pan(delta)
		
	# Optimized: Run occlusion check under a strict timer threshold
	occlusion_timer += delta
	if occlusion_timer >= occlusion_interval:
		occlusion_timer = 0.0
		check_camera_occlusion()


func setup_match_units_and_buildings() -> void:
	# Spawna QGs e Cidades baseado nas coordenadas válidas lidas do gerador
	var p_hq_coord = grid_manager.grid_cells.keys()[0]
	grid_manager.spawn_building(p_hq_coord, "Player HQ", 1, true)
	
	var e_hq_coord = grid_manager.grid_cells.keys()[grid_manager.grid_cells.size() - 1]
	grid_manager.spawn_building(e_hq_coord, "Enemy HQ", 2, true)
	
	var middle_idx = grid_manager.grid_cells.size() / 2
	var city_coord = grid_manager.grid_cells.keys()[middle_idx]
	grid_manager.spawn_building(city_coord, "Neutral City", 0, false)
	
	# Spawna unidades iniciais
	var p_unit_coord = p_hq_coord + Vector2i(1, 0)
	if not grid_manager.grid_cells.has(p_unit_coord):
		p_unit_coord = p_hq_coord + Vector2i(0, 1)
	spawn_new_unit_at(p_unit_coord, "Player Mech", false, 3)
	
	var e_unit_coord = e_hq_coord + Vector2i(-1, 0)
	if not grid_manager.grid_cells.has(e_unit_coord):
		e_unit_coord = e_hq_coord + Vector2i(0, -1)
	var enemy = spawn_new_unit_at(e_unit_coord, "Alien Scout", true, 3)
	if enemy:
		enemy.movement_range = 2


func spawn_new_unit_at(coords: Vector2i, name: String, is_enemy: bool, hp: int) -> Node3D:
	var unit = grid_manager.spawn_unit_node(coords, name, is_enemy, hp)
	if unit:
		ui_manager.create_hp_bar_for_unit(unit)
	return unit


# --- MÁQUINA DE ESTADOS (MUDANÇA DE ESTADOS) ---
func change_state(new_state: TurnState) -> void:
	current_state = new_state
	
	var is_player = current_state == TurnState.PLAYER_TURN
	var state_name = "PLAYER TURN" if is_player else ("RESOLVING IA" if current_state == TurnState.ENEMY_RESOLVE else "IA PLANNING")
	ui_layer_state_update(state_name, is_player)
	
	match current_state:
		TurnState.PLAYER_TURN:
			turn_history.clear()
			ui_manager.update_undo_button(true)
			
			# Economia: Renda de propriedades
			var income = 0
			for b in grid_manager.active_buildings.values():
				if b.faction == 1: 
					income += grid_manager.income_per_building
			player_funds += income
			ui_layer_state_update(state_name, true)
			
			for u in grid_manager.active_units.values():
				if not u.is_enemy: 
					u.has_acted_this_turn = false
			update_sprites_visuals()
					
		TurnState.ENEMY_RESOLVE:
			turn_history.clear()
			ui_manager.update_undo_button(true)
			await get_tree().create_timer(0.4).timeout
			execute_enemy_attacks()
			change_state(TurnState.ENEMY_PLAN)
			
		TurnState.ENEMY_PLAN:
			await get_tree().create_timer(0.4).timeout
			await plan_enemy_attacks()
			change_state(TurnState.PLAYER_TURN)


func ui_layer_state_update(state_name: String, is_player: bool) -> void:
	ui_manager.update_state_visuals(state_name, player_funds, is_player)


# --- PROCESSADOR DE CLIQUES DE MOUSE (FORWARD DO INPUT_HANDLER) ---
func _on_tile_clicked(coords: Vector2i) -> void:
	if is_animating or current_state != TurnState.PLAYER_TURN: 
		return
	
	# 1. Ataque
	if selected_unit and current_attackable_tiles.has(coords):
		execute_player_attack(selected_unit, coords)
		clear_selection()
		return
		
	# 2. Movimentação Passo a Passo (Escalar Relevo)
	if selected_unit and current_reachable_tiles.has(coords):
		is_animating = true
		
		# Registra o destino final na história de desfazer
		record_player_move(selected_unit, selected_unit.grid_position, coords)
		
		clear_movement_highlights()
		current_reachable_tiles.clear()
		
		# Caminha fisicamente bloco por bloco acompanhando a elevação do solo
		var path = grid_manager.calculate_path_to_target(selected_unit.grid_position, coords, selected_unit.movement_range)
		await walk_unit_along_path(selected_unit, path)
		
		is_animating = false
		
		current_attackable_tiles = grid_manager.calculate_attackable_tiles(selected_unit.grid_position, selected_unit.attack_range)
		if not current_attackable_tiles.is_empty():
			highlight_attack_tiles(current_attackable_tiles)
		else:
			selected_unit.has_acted_this_turn = true
			clear_selection()
		return
		
	# 3. Pular movimento
	if selected_unit and coords == selected_unit.grid_position:
		clear_movement_highlights()
		current_reachable_tiles.clear()
		current_attackable_tiles = grid_manager.calculate_attackable_tiles(selected_unit.grid_position, selected_unit.attack_range)
		if not current_attackable_tiles.is_empty():
			highlight_attack_tiles(current_attackable_tiles)
		else:
			selected_unit.has_acted_this_turn = true
			clear_selection()
		return
		
	# 4. Selecionar Aliado
	if grid_manager.active_units.has(coords):
		var unit = grid_manager.active_units[coords]
		if not unit.is_enemy and not unit.has_acted_this_turn:
			clear_selection()
			selected_unit = unit
			current_reachable_tiles = grid_manager.calculate_reachable_tiles(selected_unit.grid_position, selected_unit.movement_range)
			highlight_move_tiles(current_reachable_tiles)
			ui_manager.update_selection_visuals(selected_unit, null)
			ui_manager.update_capture_button(not is_unit_over_capturable_property())
			return
			
	# 5. Selecionar Fábrica vazia própria para Spawn
	if grid_manager.active_buildings.has(coords) and not grid_manager.active_units.has(coords):
		var building = grid_manager.active_buildings[coords]
		if building.faction == 1:
			clear_selection()
			selected_building_coords = coords
			ui_manager.update_deploy_button(player_funds < grid_manager.unit_spawn_cost)
			ui_manager.update_selection_visuals(null, building)
			grid_manager.set_tile_base_state(coords, Color(0.2, 0.8, 0.2), 0.35, current_hovered_tile)
			return
			
	clear_selection()


# --- PROCESSADOR DE HOVER DE MOUSE (FORWARD DO INPUT_HANDLER) ---
func _on_tile_hovered(coords: Vector2i) -> void:
	if current_state != TurnState.PLAYER_TURN: 
		return
		
	if coords != current_hovered_tile:
		if current_hovered_tile != Vector2i(-999, -999):
			grid_manager.restore_tile_base_state(current_hovered_tile, coords)
			
		if coords != Vector2i(-999, -999):
			grid_manager.apply_tile_visuals(coords, ui_manager.hover_color, ui_manager.hover_intensity)
			
		current_hovered_tile = coords


func is_unit_over_capturable_property() -> bool:
	if not selected_unit: 
		return false
	var coords = selected_unit.grid_position
	if grid_manager.active_buildings.has(coords):
		var building = grid_manager.active_buildings[coords]
		return building.faction != 1
	return false


# --- ATALHOS DE TECLADO, TECLAS DE CÂMERA E ARRASTAR MOUSE ---
func _unhandled_input(event: InputEvent) -> void:
	# Clique do botão do meio do mouse (MMB) para arrastar
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			is_dragging_camera = true
		else:
			is_dragging_camera = false
			
	# Processa o arraste físico caso o botão do meio esteja pressionado
	if event is InputEventMouseMotion and is_dragging_camera and enable_free_camera:
		handle_camera_drag(event.relative)
		return

	if current_state != TurnState.PLAYER_TURN:
		return
		
	# Rotação Orbital de Câmera (Q roda para Esquerda, E roda para Direita)
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_Q:
			rotate_camera_pivot(90)
			return
		elif event.keycode == KEY_E:
			rotate_camera_pivot(-90)
			return

	# End Turn Hotkey (Spacebar)
	if event.is_action_pressed("ui_accept"):
		_on_end_turn_requested()
		return

	# Undo Move Hotkey (Key R)
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_R:
		undo_last_move()
		return

	# Capture Action Hotkey (Key C)
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_C:
		execute_capture_action()
		return


# Rotaciona o pivô orbital suavemente
func rotate_camera_pivot(angle_degrees: float) -> void:
	if not camera_pivot or is_animating:
		return
		
	is_animating = true
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var target_rot = camera_pivot.rotation.y + deg_to_rad(angle_degrees)
	tween.tween_property(camera_pivot, "rotation:y", target_rot, 0.4)
	
	await tween.finished
	is_animating = false
	
	input_handler.tile_hovered.emit(input_handler.get_tile_at_mouse_position(get_viewport().get_mouse_position()))


# Desliza o foco da câmera (Pan) suavemente para centrar no bloco alvo (Inibido se câmera livre estiver ativa)
func pan_camera_to_coords(coords: Vector2i) -> void:
	if not camera_pivot or enable_free_camera:
		return
	var target_pos = Vector3(coords.x, 0.0, coords.y)
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera_pivot, "position", target_pos, 0.3)


# Movimentação WASD
func handle_keyboard_pan(delta: float) -> void:
	if not camera_pivot:
		return
		
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_S):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
		
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		
		# Projeta os vetores Forward e Right do pivô de câmera no plano do chão (XZ)
		var forward = -camera_pivot.global_transform.basis.z
		var right = camera_pivot.global_transform.basis.x
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		
		# O vetor de movimento é a soma das projeções relativas
		var move_dir = forward * input_dir.y + right * input_dir.x
		camera_pivot.global_position += move_dir * pan_speed * delta


# Arraste de mouse estilo "Agarrar e Puxar o Chão"
func handle_camera_drag(relative: Vector2) -> void:
	if not camera_pivot:
		return
		
	var forward = -camera_pivot.global_transform.basis.z
	var right = camera_pivot.global_transform.basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var camera = get_viewport().get_camera_3d()
	var zoom_scale = 1.0
	if camera and camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		zoom_scale = camera.size / 300.0
		
	var drag_dir = (right * -relative.x + forward * relative.y) * drag_sensitivity * zoom_scale
	camera_pivot.global_position += drag_dir


# Camera obstruction raycast check (X-Ray effect)
func check_camera_occlusion() -> void:
	for block in occluded_blocks:
		if is_instance_valid(block):
			var mesh = block.get_node_or_null("MeshInstance3D")
			if mesh:
				var mat = mesh.material_override as ShaderMaterial
				mat.set_shader_parameter("alpha", 1.0)
	occluded_blocks.clear()
	
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
		
	for unit in grid_manager.active_units.values():
		if is_instance_valid(unit) and not unit.is_enemy:
			var start_pos = camera.global_position
			var end_pos = unit.global_position + Vector3(0, 0.3, 0)
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
			
			var result = space_state.intersect_ray(query)
			if result:
				var hit_collider = result.collider
				if hit_collider and hit_collider.has_meta("grid_pos"):
					var block_coords = hit_collider.get_meta("grid_pos")
					if block_coords != unit.grid_position:
						var mesh = hit_collider.get_node_or_null("MeshInstance3D")
						if mesh:
							var mat = mesh.material_override as ShaderMaterial
							mat.set_shader_parameter("alpha", 0.25)
							occluded_blocks.append(hit_collider)


# --- BUTTON EVENTS (UI -> Controller) ---

func _on_end_turn_requested() -> void:
	clear_selection()
	change_state(TurnState.ENEMY_RESOLVE)


func execute_capture_action() -> void:
	if not selected_unit or selected_unit.has_acted_this_turn: 
		return
	var coords = selected_unit.grid_position
	if grid_manager.active_buildings.has(coords):
		var building = grid_manager.active_buildings[coords]
		building.capture(1, selected_unit.current_hp)
		selected_unit.has_acted_this_turn = true
		turn_history.clear()
		ui_manager.update_undo_button(true)
		clear_selection()


func execute_deploy_action() -> void:
	if selected_building_coords == Vector2i(-999, -999) or player_funds < grid_manager.unit_spawn_cost: 
		return
	var new_mech = spawn_new_unit_at(selected_building_coords, "Player Mech", false, 3)
	if new_mech:
		new_mech.attack_damage = 1
		new_mech.movement_range = 3
		new_mech.has_acted_this_turn = true
		player_funds -= grid_manager.unit_spawn_cost
	clear_selection()


# --- PATHFINDING MOVEMENT, WALK AND UNDO ---

func walk_unit_along_path(unit, path: Array[Vector2i]) -> void:
	if path.is_empty():
		return
		
	for i in range(path.size()):
		var next_step = path[i]
		var is_first = (i == 0)
		var is_last = (i == path.size() - 1)
		
		var old_coords = unit.grid_position
		var start_height = grid_manager.grid_cells[old_coords].get_meta("height")
		var target_height = grid_manager.grid_cells[next_step].get_meta("height")
		var target_pos = Vector3(next_step.x, target_height, next_step.y)
		
		# Modulations de aceleração e frenagem (Speed Profile)
		var trans = Tween.TRANS_SINE
		var ease_type = Tween.EASE_IN_OUT
		
		if is_first and is_last:
			trans = Tween.TRANS_SINE
			ease_type = Tween.EASE_IN_OUT
		elif is_first:
			trans = Tween.TRANS_SINE
			ease_type = Tween.EASE_IN
		elif is_last:
			trans = Tween.TRANS_SINE
			ease_type = Tween.EASE_OUT
		else:
			trans = Tween.TRANS_LINEAR
			ease_type = Tween.EASE_IN_OUT
		
		var step_tween = create_tween().set_parallel(true)
		step_tween.tween_property(unit, "position:x", target_pos.x, grid_manager.move_duration).set_trans(trans).set_ease(ease_type)
		step_tween.tween_property(unit, "position:z", target_pos.z, grid_manager.move_duration).set_trans(trans).set_ease(ease_type)
		
		if abs(start_height - target_height) > 0.01:
			var half_dur = grid_manager.move_duration / 2.0
			var peak = max(start_height, target_height) + grid_manager.jump_peak
			
			var y_tween = create_tween()
			y_tween.tween_property(unit, "position:y", peak, half_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			y_tween.tween_property(unit, "position:y", target_pos.y, half_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		else:
			step_tween.tween_property(unit, "position:y", target_pos.y, grid_manager.move_duration).set_trans(trans).set_ease(ease_type)
		
		step_tween.finished.connect(func():
			grid_manager.active_units.erase(unit.grid_position)
			grid_manager.active_units[next_step] = unit
			unit.grid_position = next_step
			pan_camera_to_coords(next_step)
		)
		
		await step_tween.finished


func move_unit_on_board(unit, target: Vector2i) -> Tween:
	grid_manager.active_units.erase(unit.grid_position)
	grid_manager.active_units[target] = unit
	return grid_manager.move_unit_to_tile(unit, target)


func record_player_move(unit, from: Vector2i, to: Vector2i) -> void:
	turn_history.append({"unit": unit, "from": from, "to": to})
	ui_manager.update_undo_button(false)


func undo_last_move() -> void:
	if turn_history.is_empty() or is_animating or current_state != TurnState.PLAYER_TURN: 
		return
	var last_move = turn_history.pop_back()
	var unit = last_move["unit"]
	var from = last_move["from"]
	var to = last_move["to"]
	if is_instance_valid(unit):
		is_animating = true
		grid_manager.active_units.erase(to)
		grid_manager.active_units[from] = unit
		unit.grid_position = from
		unit.has_acted_this_turn = false
		
		var tween = grid_manager.move_unit_to_tile(unit, from)
		pan_camera_to_coords(from) 
		
		await tween.finished
		is_animating = false
		
		clear_selection()
		update_unit_sprites_modulations()


# Modulações estéticas de cores das peças
func update_unit_sprites_modulations() -> void:
	for unit in grid_manager.active_units.values():
		if is_instance_valid(unit):
			var sprite = unit.get_node_or_null("Sprite3D")
			if sprite:
				if unit.is_enemy:
					sprite.modulate = Color(1.0, 0.4, 0.4)
				else:
					if unit.has_acted_this_turn:
						sprite.modulate = Color(0.4, 0.4, 0.4)
					else:
						sprite.modulate = Color(1.0, 1.0, 1.0)


# --- COMBATE E IA ---

func execute_player_attack(attacker, target: Vector2i) -> void:
	if grid_manager.active_units.has(target):
		var victim = grid_manager.active_units[target]
		victim.take_damage(attacker.attack_damage)
		if victim.current_hp <= 0:
			grid_manager.active_units.erase(target)
		attacker.has_acted_this_turn = true
		turn_history.clear()
		ui_manager.update_undo_button(true)


func plan_enemy_attacks() -> void:
	var enemies: Array = []
	for unit in grid_manager.active_units.values():
		if unit.is_enemy: enemies.append(unit)
	for enemy in enemies:
		var player = find_closest_player(enemy.grid_position)
		if player:
			var best = find_best_tile_for_enemy(enemy, player.grid_position)
			if best != enemy.grid_position:
				var path = grid_manager.calculate_path_to_target(enemy.grid_position, best, enemy.movement_range)
				await walk_unit_along_path(enemy, path)
				
			var diff = player.grid_position - enemy.grid_position
			var dir = Vector2i.ZERO
			if abs(diff.x) > abs(diff.y): dir.x = sign(diff.x)
			else: dir.y = sign(diff.y)
			enemy.ai_attack_dir = dir
			enemy.update_ai_target_tile()
			grid_manager.set_tile_base_state(enemy.ai_target_tile, grid_manager.danger_highlight_color, grid_manager.danger_highlight_strength, current_hovered_tile)


func find_best_tile_for_enemy(enemy, player_pos: Vector2i) -> Vector2i:
	var reachable = grid_manager.calculate_reachable_tiles(enemy.grid_position, enemy.movement_range)
	reachable.append(enemy.grid_position)
	var best = enemy.grid_position
	var min_dist = 99999
	for tile in reachable:
		var dist = abs(tile.x - player_pos.x) + abs(tile.y - player_pos.y)
		if dist < min_dist:
			min_dist = dist
			best = tile
	return best


func execute_enemy_attacks() -> void:
	var enemies: Array = []
	for unit in grid_manager.active_units.values():
		if unit.is_enemy: enemies.append(unit)
	for enemy in enemies:
		enemy.update_ai_target_tile()
		var target = enemy.ai_target_tile
		grid_manager.set_tile_base_state(target, Color.WHITE, 0.0, current_hovered_tile)
		if grid_manager.active_units.has(target):
			var victim = grid_manager.active_units[target]
			victim.take_damage(1)
			if victim == selected_unit:
				ui_manager.update_selection_visuals(selected_unit, null)
			if victim.current_hp <= 0:
				grid_manager.active_units.erase(target)
		enemy.ai_attack_dir = Vector2i.ZERO
		enemy.ai_target_tile = Vector2i.ZERO


func find_closest_player(enemy_pos: Vector2i):
	var closest = null
	var min_dist = 99999
	for unit in grid_manager.active_units.values():
		if not unit.is_enemy:
			var dist = abs(unit.grid_position.x - enemy_pos.x) + abs(unit.grid_position.y - enemy_pos.y)
			if dist < min_dist:
				min_dist = dist
				closest = unit
	return closest


# --- GENERAL HELPERS ---

func highlight_move_tiles(tiles: Array[Vector2i]) -> void:
	for tile in tiles:
		grid_manager.set_tile_base_state(tile, grid_manager.movement_highlight_color, grid_manager.movement_highlight_strength, current_hovered_tile)


func highlight_attack_tiles(tiles: Array[Vector2i]) -> void:
	for tile in tiles:
		grid_manager.set_tile_base_state(tile, grid_manager.attack_highlight_color, grid_manager.attack_highlight_strength, current_hovered_tile)


func clear_movement_highlights() -> void:
	for tile in current_reachable_tiles:
		grid_manager.set_tile_base_state(tile, Color.WHITE, 0.0, current_hovered_tile)


func update_sprites_visuals() -> void:
	update_unit_sprites_modulations()


func clear_selection() -> void:
	clear_movement_highlights()
	for tile in current_attackable_tiles:
		grid_manager.set_tile_base_state(tile, Color.WHITE, 0.0, current_hovered_tile)
	if selected_building_coords != Vector2i(-999, -999):
		grid_manager.set_tile_base_state(selected_building_coords, Color.WHITE, 0.0, current_hovered_tile)
		selected_building_coords = Vector2i(-999, -999)
	selected_unit = null
	current_reachable_tiles.clear()
	current_attackable_tiles.clear()
	ui_manager.update_selection_visuals(null, null)
	update_unit_sprites_modulations()
	ui_manager.update_deploy_button(true)
	ui_manager.update_capture_button(true)
