extends Node3D
class_name GameController

# --- PRELOAD DIRETO ---
const Pathfinder = preload("res://Script/grid_pathfinder.gd")

# --- LOCAL STATE MACHINE ---
enum TurnState { 
	PLAYER_TURN,
	ENEMY_RESOLVE,
	ENEMY_PLAN
}

var current_state: TurnState = TurnState.PLAYER_TURN


# --- COMPONENT REFERENCES ---
@onready var input_handler = $InputHandler
@onready var grid_manager = $GridManager
@onready var ui_manager = $UIManager
@onready var ai_controller = $AIController

# --- ORBITAL CAMERA CONFIGURATION ---
@export_group("Orbital Camera")
@export var camera_pivot: Node3D 

# --- FREE CAMERA CONFIGURATIONS ---
@export_group("Free Camera")
@export var enable_free_camera: bool = true
@export_range(1.0, 30.0, 0.5) var pan_speed: float = 12.0
@export_range(0.1, 10.0, 0.05) var drag_sensitivity: float = 3.0

# --- PERFORMANCE OPTIMIZATION ---
@export_group("Optimizations")
@export_range(0.01, 0.5, 0.01) var occlusion_interval: float = 0.08

# --- EXPORTED PRESETS (RESOURCES) ---
@export_group("Faction Presets (Resources)")
@export var player_mech_preset: Resource
@export var enemy_scout_preset: Resource
@export var player_hq_preset: Resource
@export var enemy_hq_preset: Resource
@export var neutral_city_preset: Resource


# --- GAMEPLAY & STATE VARIABLES ---
var player_funds: int = 0
var is_animating: bool = false
var turn_count: int = 0

# Selections
var selected_unit = null
var selected_building_coords: Vector2i = Vector2i(-999, -999)
var current_reachable_tiles: Array[Vector2i] = []
var current_attackable_tiles: Array[Vector2i] = []
var current_hovered_tile: Vector2i = Vector2i(-999, -999)

# Undo and occlusion history
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
	if enable_free_camera and not is_animating:
		handle_keyboard_pan(delta)
		
	occlusion_timer += delta
	if occlusion_timer >= occlusion_interval:
		occlusion_timer = 0.0
		check_camera_occlusion()


# MODIFICADO: Calcula o centro e força o pivô da câmera a se teletransportar para lá na inicialização
func setup_match_units_and_buildings() -> void:
	var valid_coords = grid_manager.grid_cells.keys()
	if valid_coords.is_empty():
		return
		
	# 1. Encontra o CENTRO exato das coordenadas geradas
	var middle_idx = valid_coords.size() / 2
	var p_hq_coord = valid_coords[middle_idx] # Coordenada do centro do mapa
	
	# CENTRALIZAÇÃO INICIAL DA CÂMERA: Teleporta o pivô de câmera diretamente para o local do spawn do jogador
	if camera_pivot:
		camera_pivot.global_position = Vector3(p_hq_coord.x, 0.0, p_hq_coord.y)
	
	# Spawna o QG do jogador no CENTRO do tabuleiro
	grid_manager.spawn_building(p_hq_coord, player_hq_preset, 1, true)
	
	# Spawna o Mech aliado adjacente ao QG no centro do mapa
	var p_unit_coord = p_hq_coord + Vector2i(1, 0)
	if not grid_manager.grid_cells.has(p_unit_coord):
		p_unit_coord = p_hq_coord + Vector2i(0, 1)
	spawn_new_unit_at(p_unit_coord, player_mech_preset, false)
	
	# 2. Spawna o QG inimigo na ponta final (canto oposto do mapa)
	var e_hq_coord = valid_coords[valid_coords.size() - 1]
	grid_manager.spawn_building(e_hq_coord, enemy_hq_preset, 2, true)
	
	# Spawna o monstro inicial perto do QG dele
	var e_unit_coord = e_hq_coord + Vector2i(-1, 0)
	if not grid_manager.grid_cells.has(e_unit_coord):
		e_unit_coord = e_hq_coord + Vector2i(0, -1)
	var enemy = spawn_new_unit_at(e_unit_coord, enemy_scout_preset, true)
	if enemy:
		enemy.movement_range = 2
		
	# 3. Spawna uma cidade neutra disputada no meio do caminho entre o jogador e a IA
	var city_idx = (middle_idx + valid_coords.size() - 1) / 2
	var city_coord = valid_coords[city_idx]
	grid_manager.spawn_building(city_coord, neutral_city_preset, 0, false)


func spawn_new_unit_at(coords: Vector2i, preset: Resource, is_enemy: bool) -> Node3D:
	var unit = grid_manager.spawn_unit_node(coords, preset, is_enemy)
	if unit:
		ui_manager.create_hp_bar_for_unit(unit)
	return unit


# --- TURN STATE MACHINE ---
func change_state(new_state: TurnState) -> void:
	current_state = new_state
	
	var is_player = current_state == TurnState.PLAYER_TURN
	var state_name = "PLAYER TURN" if is_player else ("RESOLVING IA" if current_state == TurnState.ENEMY_RESOLVE else "IA PLANNING")
	ui_layer_state_update(state_name, is_player)
	
	match current_state:
		TurnState.PLAYER_TURN:
			turn_count += 1
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
			await ai_controller.execute_enemy_attacks()
			
			check_defeat_conditions()
			
			change_state(TurnState.ENEMY_PLAN)
			
		TurnState.ENEMY_PLAN:
			await get_tree().create_timer(0.4).timeout
			
			if turn_count > 0 and turn_count % 3 == 0:
				spawn_enemy_invasion_wave()
				
			await ai_controller.plan_enemy_attacks()
			change_state(TurnState.PLAYER_TURN)


func ui_layer_state_update(state_name: String, is_player: bool) -> void:
	var display_text = "TURN: " + str(turn_count) + " (" + state_name + ")"
	ui_manager.update_state_visuals(display_text, player_funds, is_player)


# --- SPAWNER DA INVASÃO INIMIGA (WAVE SYSTEM) ---
func spawn_enemy_invasion_wave() -> void:
	var e_hq_coord = Vector2i(-999, -999)
	for coords in grid_manager.active_buildings.keys():
		var b = grid_manager.active_buildings[coords]
		if b.faction == 2 and b.is_hq:
			e_hq_coord = coords
			break
			
	if e_hq_coord != Vector2i(-999, -999):
		var spawn_dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		for dir in spawn_dirs:
			var candidate = e_hq_coord + dir
			if grid_manager.grid_cells.has(candidate) and not grid_manager.active_units.has(candidate):
				var new_alien = spawn_new_unit_at(candidate, enemy_scout_preset, true)
				if new_alien:
					new_alien.movement_range = 2
					print("NEW WAVE: Enemy spawned at ", candidate, " marching to your HQ!")
				break


# --- CHECAGEM DE DERROTA ---
func check_defeat_conditions() -> void:
	var player_hq_alive = false
	for b in grid_manager.active_buildings.values():
		if b.is_hq and b.faction == 1:
			player_hq_alive = true
			break
			
	if not player_hq_alive:
		print("GAME OVER: Your HQ has been captured or destroyed!")


# --- PROCESSADOR DE CLIQUES DE MOUSE ---
func _on_tile_clicked(coords: Vector2i) -> void:
	if is_animating or current_state != TurnState.PLAYER_TURN: 
		return
	
	if _try_attack(coords):
		return
		
	if await _try_movement(coords):
		return
		
	if _try_skip_movement(coords):
		return
		
	if _try_select_unit(coords):
		return
			
	if _try_select_building(coords):
		return
			
	clear_selection()


# --- DECOMPOSED INTERACTION METHODS ---

func _try_attack(coords: Vector2i) -> bool:
	if selected_unit and current_attackable_tiles.has(coords):
		execute_player_attack(selected_unit, coords)
		clear_selection()
		return true
	return false


func _try_movement(coords: Vector2i) -> bool:
	if selected_unit and current_reachable_tiles.has(coords):
		is_animating = true
		record_player_move(selected_unit, selected_unit.grid_position, coords)
		clear_movement_highlights()
		current_reachable_tiles.clear()
		
		var path = Pathfinder.calculate_path_to_target(
			grid_manager.grid_cells, grid_manager.active_units, 
			selected_unit.grid_position, coords, 
			selected_unit.movement_range, grid_manager.max_climb_height
		)
		
		await walk_unit_along_path(selected_unit, path)
		is_animating = false 
		
		current_attackable_tiles = Pathfinder.calculate_attackable_tiles(
			grid_manager.grid_cells, grid_manager.active_units, 
			selected_unit.grid_position, selected_unit.attack_range
		)
		
		if not current_attackable_tiles.is_empty():
			highlight_attack_tiles(current_attackable_tiles)
		else:
			selected_unit.has_acted_this_turn = true
			clear_selection()
		return true
	return false


func _try_skip_movement(coords: Vector2i) -> bool:
	if selected_unit and coords == selected_unit.grid_position:
		clear_movement_highlights()
		current_reachable_tiles.clear()
		current_attackable_tiles = Pathfinder.calculate_attackable_tiles(
			grid_manager.grid_cells, grid_manager.active_units, 
			selected_unit.grid_position, selected_unit.attack_range
		)
		if not current_attackable_tiles.is_empty():
			highlight_attack_tiles(current_attackable_tiles)
		else:
			selected_unit.has_acted_this_turn = true
			clear_selection()
		return true
	return false


func _try_select_unit(coords: Vector2i) -> bool:
	if grid_manager.active_units.has(coords):
		var unit = grid_manager.active_units[coords]
		if not unit.is_enemy and not unit.has_acted_this_turn:
			clear_selection()
			selected_unit = unit
			current_reachable_tiles = Pathfinder.calculate_reachable_tiles(
				grid_manager.grid_cells, grid_manager.active_units, 
				selected_unit.grid_position, selected_unit.movement_range, grid_manager.max_climb_height
			)
			highlight_move_tiles(current_reachable_tiles)
			ui_manager.update_selection_visuals(selected_unit, null)
			ui_manager.update_capture_button(not is_unit_over_capturable_property())
			return true
	return false


func _try_select_building(coords: Vector2i) -> bool:
	if grid_manager.active_buildings.has(coords) and not grid_manager.active_units.has(coords):
		var building = grid_manager.active_buildings[coords]
		if building.faction == 1:
			clear_selection()
			selected_building_coords = coords
			ui_manager.update_deploy_button(player_funds < grid_manager.unit_spawn_cost)
			ui_manager.update_selection_visuals(null, building)
			grid_manager.set_tile_base_state(coords, Color(0.2, 0.8, 0.2), 0.35, current_hovered_tile)
			return true
	return false


# --- HOVER HANDLING ---
func _on_tile_hovered(coords: Vector2i) -> void:
	if current_state != TurnState.PLAYER_TURN: 
		return
		
	if coords != current_hovered_tile:
		if current_hovered_tile != Vector2i(-999, -999):
			grid_manager.restore_tile_base_state(current_hovered_tile, coords)
			
		if coords != Vector2i(-999, -999):
			grid_manager.apply_tile_visuals(coords, ui_manager.hover_color, ui_manager.hover_intensity)
			
			if grid_manager.active_units.has(coords):
				ui_manager.show_unit_tooltip(grid_manager.active_units[coords])
			else:
				if selected_unit:
					ui_manager.show_unit_tooltip(selected_unit)
				else:
					ui_manager.hide_unit_tooltip()
		else:
			if selected_unit:
				ui_manager.show_unit_tooltip(selected_unit)
			else:
				ui_manager.hide_unit_tooltip()
			
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			is_dragging_camera = true
		else:
			is_dragging_camera = false
			
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


# Rotates the orbital pivot
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


# Slides the camera pivot to center on target coordinates
func pan_camera_to_coords(coords: Vector2i) -> void:
	if not camera_pivot or enable_free_camera:
		return
	var target_pos = Vector3(coords.x, 0.0, coords.y)
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera_pivot, "position", target_pos, 0.3)


# WASD Keyboard Pan
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
		
		var forward = -camera_pivot.global_transform.basis.z
		var right = camera_pivot.global_transform.basis.x
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		
		var move_dir = forward * input_dir.y + right * input_dir.x
		camera_pivot.global_position += move_dir * pan_speed * delta


# MMB Drag
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
		
		# Speed profile modulations
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
		
		# Espera a movimentação física terminar por completo
		await step_tween.finished
		
		# Atualiza a lógica de dados exatamente após a conclusão física do passo [2]
		grid_manager.active_units.erase(unit.grid_position)
		grid_manager.active_units[next_step] = unit
		unit.grid_position = next_step
		pan_camera_to_coords(next_step)


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


# Aesthetic modulations
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

# MODIFICADO: Agora trava cliques de mouse, executa a investida rápida e só então causa dano [2]
func execute_player_attack(attacker, target_coords: Vector2i) -> void:
	if grid_manager.active_units.has(target_coords):
		var victim = grid_manager.active_units[target_coords]
		
		is_animating = true # Trava cliques do jogador durante a colisão física
		
		# Executa a investida física do Mech batendo no monstro inimigo
		var anim_tween = ui_manager.play_combat_animation(attacker, victim)
		await anim_tween.finished
		
		# Só desconta o HP quando o golpe de investida física conecta!
		victim.take_damage(attacker.attack_damage)
		
		is_animating = false # Destrava o mouse
		
		if victim.current_hp <= 0:
			grid_manager.active_units.erase(target_coords)
			
		attacker.has_acted_this_turn = true
		
		turn_history.clear()
		ui_manager.update_undo_button(true)


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
	var new_mech = spawn_new_unit_at(selected_building_coords, player_mech_preset, false)
	if new_mech:
		new_mech.has_acted_this_turn = true
		player_funds -= grid_manager.unit_spawn_cost
	clear_selection()


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
