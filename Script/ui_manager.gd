extends Node
class_name GridUIManager

# Sinais de intenção de interface
signal end_turn_requested()
signal undo_requested()
signal capture_requested()
signal deploy_requested()
signal shop_purchase_requested(catalog_index: int)


# --- CONFIGURAÇÕES DE CUSTOMIZAÇÃO DO HOVER CARD (Inspector) ---

@export_group("Tooltip - Panel Style")
## Background color of the fixed tooltip card.
@export var tooltip_bg_color: Color = Color(0.12, 0.12, 0.12, 0.95)
## Border outline color of the fixed tooltip card.
@export var tooltip_border_color: Color = Color(0.35, 0.35, 0.35)
## Width of the border outline surrounding the card.
@export_range(0, 10, 1) var tooltip_border_width: int = 2
## Inner horizontal padding margin (X) for the tooltip content.
@export_range(0, 30, 1) var tooltip_content_margin_x: int = 8
## Inner vertical padding margin (Y) for the tooltip content.
@export_range(0, 30, 1) var tooltip_content_margin_y: int = 6
## Minimum size of the overall tooltip container.
@export var tooltip_minimum_size: Vector2 = Vector2(180, 80)
## Margin padding in pixels from the bottom-right corner of the window.
@export var tooltip_offset: Vector2 = Vector2(24, 24)

@export_group("Tooltip - Sprite Box")
## Background color of the square holding the unit's texture.
@export var sprite_box_bg_color: Color = Color(0.35, 0.35, 0.35, 1.0)
## Minimum dimensions of the square sprite preview box.
@export var sprite_box_minimum_size: Vector2 = Vector2(64, 64)

@export_group("Tooltip - Spacing")
## Horizontal spacing between the sprite box and the text info area.
@export_range(0, 30, 1) var hbox_separation: int = 10
## Horizontal spacing between stat labels (e.g., HP) and their values.
@export_range(0, 30, 1) var grid_h_separation: int = 12
## Vertical spacing between the stats rows.
@export_range(0, 15, 1) var grid_v_separation: int = 1

@export_group("Tooltip - Fonts & Colors")
## Font color of the unit's name title.
@export var text_name_color: Color = Color(1.0, 1.0, 1.0)
## Font color of the stat labels (e.g., HP, Att, Mov).
@export var text_label_color: Color = Color(0.6, 0.6, 0.6)
## Font color of the stat values (e.g., HP amount, damage number).
@export var text_value_color: Color = Color(0.9, 0.9, 0.9)


# --- NOVA SEÇÃO: CONFIGURAÇÕES DA TELA DE COMBATE 2D (Inspector) ---

@export_group("Combat UI - Style")
## Background color of the central combat overlay card.
@export var combat_ui_bg_color: Color = Color(0.12, 0.12, 0.12, 0.98)
## Total width and height dimensions of the centered combat card.
@export var combat_ui_size: Vector2 = Vector2(340, 160)
## Width and height dimensions of the two identical sprite preview boxes.
@export var combat_sprite_size: Vector2 = Vector2(80, 80)
## Horizontal spacing in pixels separating the two sprite boxes.
@export var combat_spacing: float = 100.0

@export_group("Combat UI - Animation")
## Total duration in seconds for the quick lunge-and-return combat animation.
@export_range(0.05, 1.5, 0.05) var combat_anim_duration: float = 0.35
## Horizontal distance in pixels the left sprite (attacker) lunges towards the victim.
@export_range(5.0, 120.0, 1.0) var combat_lunge_distance_2d: float = 45.0


# --- HUD PANEL (BASE) - CONFIGURAÇÕES (Inspector) ---

@export_group("HUD Panel Style")
## Posição do canto superior esquerdo do painel de HUD, em pixels de tela.
@export var hud_panel_position: Vector2 = Vector2(12, 12)
## Largura fixa do painel de HUD (a altura se ajusta ao conteúdo).
@export_range(120, 400, 1) var hud_panel_width: int = 220
## Espaçamento vertical entre os elementos dentro do painel (botões, labels).
@export_range(0, 20, 1) var hud_panel_separation: int = 6
## Margem interna (padding) do painel em todos os lados.
@export_range(0, 30, 1) var hud_panel_content_margin: int = 10
## Cor de fundo do painel de HUD.
@export var hud_panel_bg_color: Color = Color(0.12, 0.12, 0.12, 0.95)
## Cor da borda do painel de HUD.
@export var hud_panel_border_color: Color = Color(0.35, 0.35, 0.35)
## Espessura da borda do painel de HUD.
@export_range(0, 10, 1) var hud_panel_border_width: int = 2


# --- SHOP POPUP (BASE) - CONFIGURAÇÕES (Inspector) ---

@export_group("Shop Popup - Style")
## Largura fixa do popup da loja (a altura se ajusta ao número de itens).
@export_range(120, 400, 1) var shop_popup_width: int = 200
## Espaçamento vertical entre os botões da loja, dentro do popup.
@export_range(0, 20, 1) var shop_button_separation: int = 4
## Altura de cada botão da loja.
@export_range(20, 60, 1) var shop_button_height: int = 28
## Tamanho máximo do ícone/miniatura da unidade no botão da loja.
@export_range(16, 48, 1) var shop_button_icon_size: int = 24
## Margem interna (padding) do popup em todos os lados.
@export_range(0, 30, 1) var shop_popup_content_margin: int = 8
## Cor de fundo do popup da loja.
@export var shop_popup_bg_color: Color = Color(0.12, 0.12, 0.12, 0.95)
## Cor da borda do popup da loja.
@export var shop_popup_border_color: Color = Color(0.35, 0.35, 0.35)
## Espessura da borda do popup da loja.
@export_range(0, 10, 1) var shop_popup_border_width: int = 2
## Título mostrado no topo do popup da loja.
@export var shop_popup_title: String = "BUILD UNIT"

@export_group("Shop Popup - World Anchor")
## Deslocamento em espaço 3D (relativo à construção) usado para posicionar o popup acima dela.
@export var shop_popup_world_offset: Vector3 = Vector3(0, 2.2, 0)
## Deslocamento extra em pixels de tela, aplicado depois da projeção 3D->2D (ajuste fino).
@export var shop_popup_pixel_offset: Vector2 = Vector2(0, 0)


# --- FONT SIZES (BASE) - CONFIGURAÇÕES (Inspector) ---
# Controle central de tamanho de fonte por área da UI, sem precisar mexer em código.

@export_group("Font Sizes")
## Tamanho de fonte usado no painel de HUD (Funds/Phase, botões de ação, info label).
@export_range(8, 40, 1) var hud_font_size: int = 16
## Tamanho de fonte usado no popup da loja (título e botões de unidade).
@export_range(8, 40, 1) var shop_popup_font_size: int = 15
## Tamanho de fonte usado no tooltip de unidade/prédio (nome e stats).
@export_range(8, 40, 1) var tooltip_font_size: int = 14

@export_group("HP Bar Overlay")
## Altura em unidades 3D (eixo Y) para posicionar a barra de vida acima da unidade.
@export_range(0.5, 4.0, 0.1) var hp_bar_y_offset: float = 1.8
## Largura em pixels de cada bloco/pip de HP individual (estilo Into the Breach).
@export_range(4, 30, 1) var hp_pip_width: int = 10
## Altura em pixels de cada bloco/pip de HP individual.
@export_range(4, 20, 1) var hp_pip_height: int = 6
## Espaçamento em pixels entre cada bloco de HP.
@export_range(0, 10, 1) var hp_pip_separation: int = 2
## Cor do bloco preenchido (vida ativa) para unidades aliadas.
@export var hp_pip_player_color: Color = Color(0.2, 0.85, 0.25)
## Cor do bloco preenchido (vida ativa) para unidades inimigas.
@export var hp_pip_enemy_color: Color = Color(0.95, 0.25, 0.25)
## Cor do bloco vazio (vida perdida).
@export var hp_pip_empty_color: Color = Color(0.12, 0.12, 0.12, 0.75)
## Cor da borda em volta de cada bloco de HP.
@export var hp_pip_border_color: Color = Color(0.0, 0.0, 0.0, 0.9)

# --- CUSTOM VISUAL SKINS (ASSETS OVERRIDES) ---
@export_group("Custom Visual Skins (Assets Overrides)")
## Tema global opcional do Godot (.theme). Se atribuído, sobrescreve o estilo geral de toda a interface.
@export var custom_ui_theme: Theme
## Fonte global opcional (.ttf / .otf / .font) para substituir a fonte padrão dos rótulos e botões.
@export var custom_font: Font

@export_subgroup("HUD Panel Skin")
## Textura de moldura customizada para o painel de HUD no canto superior esquerdo (suporta 9-Slice).
@export var hud_panel_skin_texture: Texture2D
## Margens de 9-Slice (Esquerda, Topo, Direita, Fundo) para a moldura do painel de HUD.
@export var hud_panel_skin_margins: Rect2i = Rect2i(4, 4, 4, 4)

@export_subgroup("Shop Popup Skin")
## Textura de moldura customizada para o popup da loja ancorado no mundo 3D (suporta 9-Slice).
@export var shop_popup_skin_texture: Texture2D
## Margens de 9-Slice para a moldura do popup da loja.
@export var shop_popup_skin_margins: Rect2i = Rect2i(4, 4, 4, 4)

@export_subgroup("Tooltip Skin")
## Textura de fundo customizada para o card de inspeção (Tooltip de hover) (suporta 9-Slice).
@export var tooltip_skin_texture: Texture2D
## Margens de 9-Slice para a moldura do tooltip.
@export var tooltip_skin_margins: Rect2i = Rect2i(4, 4, 4, 4)

@export_subgroup("HP Bar Skins & Override")
## Cena customizada (.tscn) opcional para substituir fisicamente a barra de vida flutuante.
@export var custom_hp_bar_scene: PackedScene
## Textura de fundo/trilho para a barra de vida flutuante.
@export var hp_bar_bg_texture: Texture2D
## Textura de preenchimento para a barra de vida das unidades do Jogador (Aliadas).
@export var hp_bar_player_fill_texture: Texture2D
## Textura de preenchimento para a barra de vida das unidades do Inimigo.
@export var hp_bar_enemy_fill_texture: Texture2D


# --- INTERNAL VARIABLES ---
var hp_bars: Dictionary = {}
var hover_color: Color = Color(1.0, 1.0, 1.0)
var hover_intensity: float = 0.35

# Loja: guarda o custo de cada botão criado, na mesma ordem do shop_catalog, pra
# podermos habilitar/desabilitar sem precisar re-consultar o GameController.
var shop_button_costs: Array[int] = []

# HUD Panel node references (evita get_node_or_null repetido pelos caminhos)
var hud_panel: PanelContainer
var state_label: Label
var end_turn_btn: Button
var undo_btn: Button
var capture_btn: Button
var deploy_btn: Button
var info_label: Label

# Shop Popup node references (BASE): popup ancorado no mundo 3D, acima da construção selecionada
var shop_popup_panel: PanelContainer
var shop_popup_title_label: Label
var shop_popup_vbox: VBoxContainer
var shop_popup_anchor: Node3D = null

# Tooltip node references
var tooltip_panel: PanelContainer
var tooltip_texture: TextureRect
var tooltip_name: Label
var tooltip_hp: Label
var tooltip_att: Label
var tooltip_mov: Label

# Combat UI node references
var combat_panel: PanelContainer
var attacker_rect_panel: PanelContainer
var victim_rect_panel: PanelContainer
var attacker_texture: TextureRect
var victim_texture: TextureRect


func _ready() -> void:
	# Garante que o processamento do _process não quebre se o combate estiver rodando
	pass


func _process(_delta: float) -> void:
	update_hp_bar_positions()
	update_shop_popup_position()


# Desenha os nós de interface programaticamente
func setup_hud(spawn_cost: int) -> void:
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	if custom_ui_theme:
		ui_layer.theme = custom_ui_theme
	add_child(ui_layer)

	create_hud_panel(ui_layer, spawn_cost)
	create_shop_popup(ui_layer)
	create_tooltip_ui(ui_layer)
	create_combat_ui(ui_layer) # Inicializa fisicamente o painel 2D de combate


# --- HUD PANEL (BASE): monta a caixa fixa no canto superior esquerdo ---
func create_hud_panel(parent: CanvasLayer, spawn_cost: int) -> void:
	hud_panel = PanelContainer.new()
	hud_panel.name = "HUDPanel"
	hud_panel.position = hud_panel_position
	hud_panel.custom_minimum_size = Vector2(hud_panel_width, 0)

	var style = _create_stylebox_skin(
		hud_panel_skin_texture,
		hud_panel_skin_margins,
		hud_panel_bg_color,
		hud_panel_border_color,
		hud_panel_border_width,
		hud_panel_content_margin,
		hud_panel_content_margin,
		hud_panel_content_margin,
		hud_panel_content_margin
	)
	hud_panel.add_theme_stylebox_override("panel", style)

	parent.add_child(hud_panel)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", hud_panel_separation)
	hud_panel.add_child(vbox)

	state_label = Label.new()
	state_label.name = "StateLabel"
	state_label.text = "Turn: Player"
	_set_font_size(state_label, hud_font_size)
	vbox.add_child(state_label)

	end_turn_btn = Button.new()
	end_turn_btn.name = "EndTurnButton"
	end_turn_btn.text = "End Turn (Space)"
	end_turn_btn.custom_minimum_size = Vector2(0, 28)
	_set_font_size(end_turn_btn, hud_font_size)
	end_turn_btn.pressed.connect(func(): end_turn_requested.emit())
	vbox.add_child(end_turn_btn)

	undo_btn = Button.new()
	undo_btn.name = "UndoButton"
	undo_btn.text = "Undo Move (R)"
	undo_btn.custom_minimum_size = Vector2(0, 28)
	_set_font_size(undo_btn, hud_font_size)
	undo_btn.disabled = true
	undo_btn.pressed.connect(func(): undo_requested.emit())
	vbox.add_child(undo_btn)

	capture_btn = Button.new()
	capture_btn.name = "CaptureButton"
	capture_btn.text = "Capture (C)"
	capture_btn.custom_minimum_size = Vector2(0, 28)
	_set_font_size(capture_btn, hud_font_size)
	capture_btn.disabled = true
	capture_btn.pressed.connect(func(): capture_requested.emit())
	vbox.add_child(capture_btn)

	deploy_btn = Button.new()
	deploy_btn.name = "DeployButton"
	deploy_btn.text = "Deploy Mech ($" + str(spawn_cost) + ")"
	deploy_btn.custom_minimum_size = Vector2(0, 28)
	_set_font_size(deploy_btn, hud_font_size)
	deploy_btn.disabled = true
	deploy_btn.pressed.connect(func(): deploy_requested.emit())
	vbox.add_child(deploy_btn)

	info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "No unit selected"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_font_size(info_label, hud_font_size)
	vbox.add_child(info_label)


# --- SHOP POPUP (BASE): cria o popup flutuante, ancorado no mundo 3D acima da construção ---
func create_shop_popup(parent: CanvasLayer) -> void:
	shop_popup_panel = PanelContainer.new()
	shop_popup_panel.name = "ShopPopup"
	shop_popup_panel.visible = false
	shop_popup_panel.custom_minimum_size = Vector2(shop_popup_width, 0)

	var style = _create_stylebox_skin(
		shop_popup_skin_texture,
		shop_popup_skin_margins,
		shop_popup_bg_color,
		shop_popup_border_color,
		shop_popup_border_width,
		shop_popup_content_margin,
		shop_popup_content_margin,
		shop_popup_content_margin,
		shop_popup_content_margin
	)
	shop_popup_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", shop_button_separation)
	shop_popup_panel.add_child(vbox)

	shop_popup_title_label = Label.new()
	shop_popup_title_label.name = "TitleLabel"
	shop_popup_title_label.text = shop_popup_title
	shop_popup_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font_size(shop_popup_title_label, shop_popup_font_size)
	vbox.add_child(shop_popup_title_label)

	shop_popup_vbox = VBoxContainer.new()
	shop_popup_vbox.name = "ShopContainer"
	shop_popup_vbox.add_theme_constant_override("separation", shop_button_separation)
	vbox.add_child(shop_popup_vbox)

	parent.add_child(shop_popup_panel)


# --- SHOP (BASE): gera um botão por item do shop_catalog dentro do popup ---
func setup_shop(catalog: Array) -> void:
	if not shop_popup_vbox:
		return

	# Remove botões antigos, caso setup_shop seja chamado de novo (ex: catálogo trocado em runtime)
	for child in shop_popup_vbox.get_children():
		child.queue_free()

	shop_button_costs.clear()

	for i in range(catalog.size()):
		var preset = catalog[i]
		if not preset:
			continue

		var unit_name = preset.get("unit_name")
		if unit_name == null or str(unit_name) == "":
			unit_name = "Unit " + str(i + 1)

		var unit_cost = preset.get("cost")
		if unit_cost == null:
			unit_cost = 0
		unit_cost = int(unit_cost)

		var shop_btn = Button.new()
		shop_btn.name = "ShopButton_" + str(i)
		shop_btn.text = str(unit_name) + " ($" + str(unit_cost) + ")"
		shop_btn.custom_minimum_size = Vector2(0, shop_button_height)
		_set_font_size(shop_btn, shop_popup_font_size)
		shop_btn.disabled = true

		var sprite_tex = preset.get("sprite_frame_a")
		if sprite_tex and sprite_tex is Texture2D:
			shop_btn.icon = sprite_tex
			shop_btn.expand_icon = true
			shop_btn.add_theme_constant_override("icon_max_width", shop_button_icon_size)

		var index_captured := i
		shop_btn.pressed.connect(func(): shop_purchase_requested.emit(index_captured))

		shop_popup_vbox.add_child(shop_btn)
		shop_button_costs.append(unit_cost)


# Habilita/desabilita cada botão da loja conforme os funds atuais do jogador
func update_shop_affordability(funds: int) -> void:
	if not shop_popup_vbox:
		return

	for i in range(shop_button_costs.size()):
		if i < shop_popup_vbox.get_child_count():
			var shop_btn = shop_popup_vbox.get_child(i)
			shop_btn.disabled = funds < shop_button_costs[i]


# --- SHOP POPUP (BASE): abre o popup ancorado num nó 3D (a construção selecionada) ---
func show_shop_popup(anchor: Node3D) -> void:
	shop_popup_anchor = anchor
	if shop_popup_panel:
		shop_popup_panel.visible = true
		update_shop_popup_position() # Evita 1 frame de "flash" na posição antiga


func hide_shop_popup() -> void:
	shop_popup_anchor = null
	if shop_popup_panel:
		shop_popup_panel.visible = false


# Reprojeta o popup a cada frame para acompanhar a câmera orbital/zoom
func update_shop_popup_position() -> void:
	if not shop_popup_panel or not shop_popup_panel.visible:
		return

	if not shop_popup_anchor or not is_instance_valid(shop_popup_anchor):
		shop_popup_panel.visible = false
		return

	var camera = get_viewport().get_camera_3d()
	if not camera:
		return

	var world_pos = shop_popup_anchor.global_position + shop_popup_world_offset
	if camera.is_position_behind(world_pos):
		shop_popup_panel.visible = false
		return

	var screen_pos = camera.unproject_position(world_pos)
	# Ancora a BASE do popup no ponto projetado, centralizado horizontalmente
	var popup_size = shop_popup_panel.size
	shop_popup_panel.position = screen_pos - Vector2(popup_size.x / 2.0, popup_size.y) + shop_popup_pixel_offset


# Cria fisicamente a estrutura do painel de hover mapeando as propriedades de âncora
func create_tooltip_ui(parent: CanvasLayer) -> void:
	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "UnitTooltip"
	tooltip_panel.visible = false
	tooltip_panel.custom_minimum_size = tooltip_minimum_size

	var style = _create_stylebox_skin(
		tooltip_skin_texture,
		tooltip_skin_margins,
		tooltip_bg_color,
		tooltip_border_color,
		tooltip_border_width,
		tooltip_content_margin_x,
		tooltip_content_margin_x,
		tooltip_content_margin_y,
		tooltip_content_margin_y
	)
	tooltip_panel.add_theme_stylebox_override("panel", style)

	# Ancoragem fixa no canto direito inferior
	tooltip_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tooltip_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tooltip_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN

	# Aplica os offsets/margens baseando-se no tamanho da caixa e do recuo
	tooltip_panel.offset_left = -tooltip_minimum_size.x - tooltip_offset.x
	tooltip_panel.offset_top = -tooltip_minimum_size.y - tooltip_offset.y
	tooltip_panel.offset_right = -tooltip_offset.x
	tooltip_panel.offset_bottom = -tooltip_offset.y

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", hbox_separation)
	tooltip_panel.add_child(hbox)

	# Área do Sprite (Esquerda)
	var sprite_panel = PanelContainer.new()
	var sprite_style = StyleBoxFlat.new()
	sprite_style.bg_color = sprite_box_bg_color
	sprite_panel.add_theme_stylebox_override("panel", sprite_style)

	tooltip_texture = TextureRect.new()
	tooltip_texture.custom_minimum_size = sprite_box_minimum_size
	tooltip_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tooltip_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_panel.add_child(tooltip_texture)
	hbox.add_child(sprite_panel)

	# Área de Texto e Atributos (Direita)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Nome da Unidade (Topo)
	tooltip_name = Label.new()
	tooltip_name.text = "NAME"
	tooltip_name.add_theme_color_override("font_color", text_name_color)
	_set_font_size(tooltip_name, tooltip_font_size)
	vbox.add_child(tooltip_name)

	# Grid de Atributos alinhado por colunas
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", grid_h_separation)
	grid.add_theme_constant_override("v_separation", grid_v_separation)
	vbox.add_child(grid)

	# HP
	var hp_lbl = Label.new()
	hp_lbl.text = "HP"
	hp_lbl.add_theme_color_override("font_color", text_label_color)
	_set_font_size(hp_lbl, tooltip_font_size)
	grid.add_child(hp_lbl)
	tooltip_hp = Label.new()
	tooltip_hp.add_theme_color_override("font_color", text_value_color)
	_set_font_size(tooltip_hp, tooltip_font_size)
	grid.add_child(tooltip_hp)

	# Attack (Att)
	var att_lbl = Label.new()
	att_lbl.text = "Att"
	att_lbl.add_theme_color_override("font_color", text_label_color)
	_set_font_size(att_lbl, tooltip_font_size)
	grid.add_child(att_lbl)
	tooltip_att = Label.new()
	tooltip_att.add_theme_color_override("font_color", text_value_color)
	_set_font_size(tooltip_att, tooltip_font_size)
	grid.add_child(tooltip_att)

	# Movement (Mov)
	var mov_lbl = Label.new()
	mov_lbl.text = "Mov"
	mov_lbl.add_theme_color_override("font_color", text_label_color)
	_set_font_size(mov_lbl, tooltip_font_size)
	grid.add_child(mov_lbl)
	tooltip_mov = Label.new()
	tooltip_mov.add_theme_color_override("font_color", text_value_color)
	_set_font_size(tooltip_mov, tooltip_font_size)
	grid.add_child(tooltip_mov)

	parent.add_child(tooltip_panel)


# --- NOVO: GERADOR DA TELA DE COMBATE 2D ---
# Constrói o painel de colisão central mapeando os parâmetros exportados do Inspector
func create_combat_ui(parent: CanvasLayer) -> void:
	combat_panel = PanelContainer.new()
	combat_panel.name = "CombatUI"
	combat_panel.visible = false
	combat_panel.custom_minimum_size = combat_ui_size

	# Ancoragem estrita de travamento no CENTRO da janela [1]
	combat_panel.set_anchors_preset(Control.PRESET_CENTER)
	combat_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	combat_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style = StyleBoxFlat.new()
	style.bg_color = combat_ui_bg_color
	style.border_color = Color(0.35, 0.35, 0.35)
	style.set_border_width_all(2)
	combat_panel.add_theme_stylebox_override("panel", style)

	# Usamos um nó Control genérico interno para podermos deslocar as caixas livremente via Tween
	var container = Control.new()
	combat_panel.add_child(container)

	# Caixa de Sprite do Atacante (Esquerda)
	attacker_rect_panel = PanelContainer.new()
	attacker_rect_panel.custom_minimum_size = combat_sprite_size
	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.35, 0.35, 0.35, 1.0)
	attacker_rect_panel.add_theme_stylebox_override("panel", box_style)

	attacker_texture = TextureRect.new()
	attacker_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	attacker_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	attacker_rect_panel.add_child(attacker_texture)
	container.add_child(attacker_rect_panel)

	# Caixa de Sprite do Defensor (Direita)
	victim_rect_panel = PanelContainer.new()
	victim_rect_panel.custom_minimum_size = combat_sprite_size
	victim_rect_panel.add_theme_stylebox_override("panel", box_style)

	victim_texture = TextureRect.new()
	victim_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	victim_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	victim_rect_panel.add_child(victim_texture)
	container.add_child(victim_rect_panel)

	parent.add_child(combat_panel)


# --- NOVO: EXECUÇÃO DA ANIMAÇÃO DE COMBATE 2D ---
# Injeta as texturas, abre o painel, executa a investida do frame esquerdo contra o direito e fecha [1]
# --- EXECUÇÃO DA ANIMAÇÃO DE COMBATE 2D ---
func play_combat_animation(attacker, victim) -> Tween:
	var tex_a = attacker.unit_data.get("sprite_frame_a") if attacker.unit_data else null
	var tex_v = victim.unit_data.get("sprite_frame_a") if victim.unit_data else null

	if not tex_a:
		var sprite = attacker.get_node_or_null("Sprite3D")
		if sprite: tex_a = sprite.texture
	if not tex_v:
		var sprite = victim.get_node_or_null("Sprite3D")
		if sprite: tex_v = sprite.texture

	attacker_texture.texture = tex_a
	victim_texture.texture = tex_v

	combat_panel.visible = true

	var center = combat_ui_size / 2.0

	var attacker_start_pos = Vector2(
		center.x - (combat_spacing / 2.0) - (combat_sprite_size.x / 2.0),
		center.y - (combat_sprite_size.y / 2.0)
	)
	var victim_start_pos = Vector2(
		center.x + (combat_spacing / 2.0) - (combat_sprite_size.x / 2.0),
		center.y - (combat_sprite_size.y / 2.0)
	)

	attacker_rect_panel.position = attacker_start_pos
	victim_rect_panel.position = victim_start_pos

	var lunge_pos_x = attacker_start_pos.x + combat_lunge_distance_2d

	# CORREÇÃO: Removido o .set_sequence() que causava a quebra na engine 4.7
	var tween = create_tween()

	var lunge_time = combat_anim_duration * 0.35
	tween.tween_property(attacker_rect_panel, "position:x", lunge_pos_x, lunge_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var return_time = combat_anim_duration * 0.65
	tween.tween_property(attacker_rect_panel, "position:x", attacker_start_pos.x, return_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		combat_panel.visible = false
	)

	return tween


# Mostra e popula os dados lendo diretamente do Recurso unit_data
func show_unit_tooltip(unit) -> void:
	if not tooltip_panel or not is_instance_valid(unit):
		return

	# 1. Resolve Name Safely
	var final_name: String = "RECRUIT"
	if unit.get("unit_name") != null:
		final_name = unit.unit_name
	if unit.get("unit_data") != null and unit.unit_data != null:
		var data_name = unit.unit_data.get("unit_name")
		if data_name != null:
			final_name = str(data_name)
	tooltip_name.text = final_name.to_upper()

	# 2. Resolve Texture Safely
	var final_texture: Texture2D = null
	if unit.get("unit_data") != null and unit.unit_data != null:
		var data_tex = unit.unit_data.get("sprite_frame_a")
		if data_tex != null and data_tex is Texture2D:
			final_texture = data_tex

	if final_texture == null:
		var sprite = unit.get_node_or_null("Sprite3D")
		if sprite and sprite is Sprite3D:
			final_texture = sprite.texture

	tooltip_texture.texture = final_texture

	# 3. Resolve Stats Safely
	tooltip_hp.text = str(unit.current_hp) + "/" + str(unit.max_hp)
	tooltip_att.text = str(unit.attack_damage)
	tooltip_mov.text = str(unit.movement_range)

	tooltip_panel.visible = true


func hide_unit_tooltip() -> void:
	if tooltip_panel:
		tooltip_panel.visible = false


# Cria dinamicamente a mini barra de vida para a unidade
func create_hp_bar_for_unit(unit) -> void:
	if not unit or not is_instance_valid(unit):
		return

	var ui_layer = get_node_or_null("UI")
	if not ui_layer:
		setup_hud(100)
		ui_layer = get_node_or_null("UI")

	if not ui_layer:
		return

	if custom_hp_bar_scene:
		var custom_bar = custom_hp_bar_scene.instantiate()
		ui_layer.add_child(custom_bar)
		hp_bars[unit] = custom_bar
		if custom_bar.has_signal("hp_changed"):
			unit.hp_changed.connect(func(new_hp): custom_bar.emit_signal("hp_changed", new_hp))
		unit.tree_exiting.connect(func():
			hp_bars.erase(unit)
			if is_instance_valid(custom_bar):
				custom_bar.queue_free()
		)
		return

	# BARRA DE VIDA SEGMENTADA EM PIPS (Estilo Into the Breach)
	var bar_container = HBoxContainer.new()
	bar_container.name = "SegmentedHPBar"
	bar_container.add_theme_constant_override("separation", hp_pip_separation)
	_build_hp_pips(bar_container, unit)

	ui_layer.add_child(bar_container)
	hp_bars[unit] = bar_container

	unit.hp_changed.connect(func(new_hp): _update_hp_pips(bar_container, unit, new_hp))
	unit.tree_exiting.connect(func():
		hp_bars.erase(unit)
		if is_instance_valid(bar_container):
			bar_container.queue_free()
	)


func _build_hp_pips(container: HBoxContainer, unit) -> void:
	for child in container.get_children():
		child.queue_free()

	var fill_color = hp_pip_enemy_color if unit.is_enemy else hp_pip_player_color
	var max_hp = unit.max_hp if unit.max_hp > 0 else 1

	for i in range(max_hp):
		var pip = PanelContainer.new()
		pip.name = "Pip_" + str(i)
		pip.custom_minimum_size = Vector2(hp_pip_width, hp_pip_height)
		
		var is_filled = i < unit.current_hp
		var style = StyleBoxFlat.new()
		style.bg_color = fill_color if is_filled else hp_pip_empty_color
		style.border_color = hp_pip_border_color
		style.set_border_width_all(1)
		pip.add_theme_stylebox_override("panel", style)
		
		container.add_child(pip)


func _update_hp_pips(container: HBoxContainer, unit, new_hp: int) -> void:
	if not container or not is_instance_valid(container):
		return

	var pips = container.get_children()
	if pips.size() != unit.max_hp:
		_build_hp_pips(container, unit)
		return

	var fill_color = hp_pip_enemy_color if unit.is_enemy else hp_pip_player_color
	for i in range(pips.size()):
		var pip = pips[i]
		if pip and pip is PanelContainer:
			var is_filled = i < new_hp
			var style = StyleBoxFlat.new()
			style.bg_color = fill_color if is_filled else hp_pip_empty_color
			style.border_color = hp_pip_border_color
			style.set_border_width_all(1)
			pip.add_theme_stylebox_override("panel", style)


func _update_all_hp_bar_sizes() -> void:
	for unit in hp_bars.keys():
		if is_instance_valid(unit) and hp_bars.has(unit):
			var bar = hp_bars[unit]
			if bar and bar is HBoxContainer:
				_build_hp_pips(bar, unit)


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
				var pos_3d = unit.global_position + Vector3(0, hp_bar_y_offset, 0)
				if camera.is_position_behind(pos_3d):
					bar.visible = false
				else:
					bar.visible = true
					var pos_2d = camera.unproject_position(pos_3d)
					var total_w = unit.max_hp * hp_pip_width + (unit.max_hp - 1) * hp_pip_separation
					bar.global_position = pos_2d - Vector2(total_w / 2.0, hp_pip_height / 2.0)


# Atualizadores visuais chamados pelo Mediador (GameController)
func update_state_visuals(state_name: String, funds: int, is_player_turn: bool, income: int = 0) -> void:
	if state_label:
		var income_str = " (+" + str(income) + ")" if income > 0 else ""
		state_label.text = "PHASE: " + state_name + "\nFunds: $" + str(funds) + income_str
	if end_turn_btn:
		end_turn_btn.disabled = not is_player_turn


func update_selection_visuals(unit, building) -> void:
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
	if undo_btn:
		undo_btn.disabled = is_disabled


func update_capture_button(is_disabled: bool) -> void:
	if capture_btn:
		capture_btn.disabled = is_disabled


func update_deploy_button(is_disabled: bool) -> void:
	if deploy_btn:
		deploy_btn.disabled = is_disabled


# --- HELPER (BASE): aplica o tamanho de fonte e fonte customizada num Control ---
func _set_font_size(control: Control, size: int) -> void:
	if custom_font:
		control.add_theme_font_override("font", custom_font)
	control.add_theme_font_size_override("font_size", size)


# --- HELPER (SKINS): cria um StyleBoxTexture (9-slice) se houver textura, ou StyleBoxFlat se vazia ---
func _create_stylebox_skin(custom_tex: Texture2D, margins: Rect2i, fallback_bg: Color, fallback_border: Color, fallback_border_w: int, content_l: int, content_r: int, content_t: int, content_b: int) -> StyleBox:
	if custom_tex:
		var sb_tex = StyleBoxTexture.new()
		sb_tex.texture = custom_tex
		sb_tex.texture_margin_left = margins.position.x
		sb_tex.texture_margin_top = margins.position.y
		sb_tex.texture_margin_right = margins.size.x
		sb_tex.texture_margin_bottom = margins.size.y
		sb_tex.content_margin_left = content_l
		sb_tex.content_margin_right = content_r
		sb_tex.content_margin_top = content_t
		sb_tex.content_margin_bottom = content_b
		return sb_tex
	else:
		var sb_flat = StyleBoxFlat.new()
		sb_flat.bg_color = fallback_bg
		sb_flat.border_color = fallback_border
		sb_flat.set_border_width_all(fallback_border_w)
		sb_flat.content_margin_left = content_l
		sb_flat.content_margin_right = content_r
		sb_flat.content_margin_top = content_t
		sb_flat.content_margin_bottom = content_b
		return sb_flat
