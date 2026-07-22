extends Node
class_name GridUIManager

# Sinais de intenção de interface
signal end_turn_requested()
signal undo_requested()
signal capture_requested()
signal deploy_requested()

# Rastreamento das barras de vida ativas na interface
var hp_bars: Dictionary = {}

# Parâmetros de Hover expostos para o GameController ler
var hover_color: Color = Color(1.0, 1.0, 1.0)
var hover_intensity: float = 0.35


func _process(_delta: float) -> void:
	update_hp_bar_positions()


# Desenha os nós de interface programaticamente
func setup_hud(spawn_cost: int) -> void:
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	add_child(ui_layer)
	
	var state_label = Label.new()
	state_label.name = "StateLabel"
	state_label.text = "Turn: Player"
	state_label.position = Vector2(24, 24)
	ui_layer.add_child(state_label)
	
	var end_turn_btn = Button.new()
	end_turn_btn.name = "EndTurnButton"
	end_turn_btn.text = "End Turn (Space)"
	end_turn_btn.position = Vector2(24, 64)
	end_turn_btn.size = Vector2(180, 28)
	end_turn_btn.pressed.connect(func(): end_turn_requested.emit())
	ui_layer.add_child(end_turn_btn)
	
	var undo_btn = Button.new()
	undo_btn.name = "UndoButton"
	undo_btn.text = "Undo Move (R)"
	undo_btn.position = Vector2(24, 100)
	undo_btn.size = Vector2(180, 28)
	undo_btn.disabled = true 
	undo_btn.pressed.connect(func(): undo_requested.emit())
	ui_layer.add_child(undo_btn)
	
	var capture_btn = Button.new()
	capture_btn.name = "CaptureButton"
	capture_btn.text = "Capture (C)"
	capture_btn.position = Vector2(24, 136)
	capture_btn.size = Vector2(180, 28)
	capture_btn.disabled = true
	capture_btn.pressed.connect(func(): capture_requested.emit())
	ui_layer.add_child(capture_btn)
	
	var deploy_btn = Button.new()
	deploy_btn.name = "DeployButton"
	deploy_btn.text = "Deploy Mech ($" + str(spawn_cost) + ")"
	deploy_btn.position = Vector2(24, 172)
	deploy_btn.size = Vector2(180, 28)
	deploy_btn.disabled = true
	deploy_btn.pressed.connect(func(): deploy_requested.emit())
	ui_layer.add_child(deploy_btn)
	
	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "No unit selected"
	info_label.position = Vector2(24, 216)
	ui_layer.add_child(info_label)


# CORREÇÃO: Argumento 'unit' agora é dinâmico (Duck Typing), sem restrição de classe
func create_hp_bar_for_unit(unit) -> void:
	var ui_layer = get_node_or_null("UI")
	if not ui_layer:
		return
		
	var hp_bar = ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.min_value = 0
	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.current_hp
	hp_bar.size = Vector2(40, 6)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	hp_bar.add_theme_stylebox_override("background", sb_bg)
	
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.9, 0.2, 0.2) if unit.is_enemy else Color(0.2, 0.8, 0.2)
	hp_bar.add_theme_stylebox_override("fill", sb_fg)
	
	ui_layer.add_child(hp_bar)
	hp_bars[unit] = hp_bar
	
	unit.hp_changed.connect(func(new_hp): hp_bar.value = new_hp)
	unit.tree_exiting.connect(func():
		hp_bars.erase(unit)
		if is_instance_valid(hp_bar):
			hp_bar.queue_free()
	)


# Converte a coordenada 3D em 2D para as barras acompanharem as peças
func update_hp_bar_positions() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
		
	var units = hp_bars.keys()
	for unit in units:
		if is_instance_valid(unit) and hp_bars.has(unit):
			var bar = hp_bars[unit]
			if is_instance_valid(bar):
				var pos_3d = unit.global_position + Vector3(0, 0.8, 0)
				if camera.is_position_behind(pos_3d):
					bar.visible = false
				else:
					bar.visible = true
					var pos_2d = camera.unproject_position(pos_3d)
					bar.global_position = pos_2d - Vector2(20, 0)


# Atualizadores visuais chamados pelo Mediador (GameController)
func update_state_visuals(state_name: String, funds: int, is_player_turn: bool) -> void:
	var state_label = get_node_or_null("UI/StateLabel")
	var end_turn_btn = get_node_or_null("UI/EndTurnButton")
	if state_label:
		state_label.text = "PHASE: " + state_name + "\nFunds: $" + str(funds)
	if end_turn_btn:
		end_turn_btn.disabled = not is_player_turn


# CORREÇÃO: Argumentos 'unit' e 'building' dinâmicos (Duck Typing)
func update_selection_visuals(unit, building) -> void:
	var info_label = get_node_or_null("UI/InfoLabel")
	if not info_label:
		return
		
	if unit:
		info_label.text = "SELECTED UNIT:\n" + \
						  "Name: " + unit.unit_name + "\n" + \
						  "HP: " + str(unit.current_hp) + "/" + str(unit.max_hp) + "\n" + \
						  "Movement: " + str(unit.movement_range) + "\n" + \
						  "Damage: " + str(unit.attack_damage)
	elif building:
		var faction_name = "Neutral" if building.faction == 0 else ("Player" if building.faction == 1 else "Enemy")
		info_label.text = "SELECTED PROPERTY:\n" + \
						  "Name: " + building.building_name + "\n" + \
						  "Faction: " + faction_name + "\n" + \
						  "Capture points: " + str(building.current_capture_points) + "/" + str(building.max_capture_points)
	else:
		info_label.text = "No selection\nClick on active ally, owned base or city"


func update_undo_button(is_disabled: bool) -> void:
	var undo_btn = get_node_or_null("UI/UndoButton")
	if undo_btn:
		undo_btn.disabled = is_disabled


func update_capture_button(is_disabled: bool) -> void:
	var capture_btn = get_node_or_null("UI/CaptureButton")
	if capture_btn:
		capture_btn.disabled = is_disabled


func update_deploy_button(is_disabled: bool) -> void:
	var deploy_btn = get_node_or_null("UI/DeployButton")
	if deploy_btn:
		deploy_btn.disabled = is_disabled
