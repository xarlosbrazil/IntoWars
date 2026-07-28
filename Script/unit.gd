extends Node3D

# --- SIGNALS ---
signal hp_changed(new_hp: int)

@export var unit_data: Resource

# Fallback default values
var unit_name: String = "Recruit"
var max_hp: int = 3
var movement_range: int = 3
var attack_damage: int = 1
var attack_range: int = 1

@export var is_enemy: bool = false

var ai_attack_dir: Vector2i = Vector2i.ZERO
var ai_target_tile: Vector2i = Vector2i.ZERO

var current_hp: int
var grid_position: Vector2i = Vector2i.ZERO
var has_acted_this_turn: bool = false

# --- 2-FRAME ANIMATION VARIABLES ---
var animation_timer: float = 0.0
var animation_interval: float = 0.35 
var is_frame_a: bool = true
var base_offset_y: float = 0.0


func _ready() -> void:
	# GARANTIA FÍSICA: Força visibilidade e escala
	visible = true
	scale = Vector3.ONE

	var sprite: Sprite3D = _find_sprite_recursive(self)
	
	print("DEBUG [Unit ready]: Name = ", name, " | Resource = ", unit_data, " | Sprite3D found = ", sprite != null)
	
	if sprite:
		# GARANTIA DE POSICIONAMENTO E ESCALA
		sprite.position = Vector3.ZERO
		sprite.scale = Vector3.ONE
		sprite.pixel_size = 0.01
		
		# GARANTIA DE ILUMINAÇÃO: Desliga a reação à sombra
		sprite.shaded = false
		
		if unit_data:
			var d_name = unit_data.get("unit_name")
			if d_name != null and str(d_name) != "": 
				unit_name = str(d_name)
			
			var d_max_hp = unit_data.get("max_hp")
			if d_max_hp != null: 
				max_hp = int(d_max_hp)
			
			var d_move = unit_data.get("movement_range")
			if d_move != null: 
				movement_range = int(d_move)
			
			var d_dmg = unit_data.get("attack_damage")
			if d_dmg != null: 
				attack_damage = int(d_dmg)
			
			var d_range = unit_data.get("attack_range")
			if d_range != null: 
				attack_range = int(d_range)
			
			var d_tex_a = unit_data.get("sprite_frame_a")
			if d_tex_a != null and d_tex_a is Texture2D:
				sprite.texture = d_tex_a
				
		if sprite.texture == null:
			sprite.texture = load("res://icon.svg")
			
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		if sprite.texture:
			sprite.offset = Vector2(0, sprite.texture.get_size().y / 2.0)
			base_offset_y = sprite.offset.y
			
	current_hp = max_hp


# Função utilitária de busca recursiva profunda na árvore de nós
func _find_sprite_recursive(node: Node) -> Sprite3D:
	if node is Sprite3D:
		return node
	for child in node.get_children():
		var result = _find_sprite_recursive(child)
		if result:
			return result
	return null


func _process(delta: float) -> void:
	if unit_data:
		var frame_a = unit_data.get("sprite_frame_a")
		var frame_b = unit_data.get("sprite_frame_b")
		
		if frame_a != null and frame_b != null:
			animation_timer += delta
			if animation_timer >= animation_interval:
				animation_timer = 0.0
				is_frame_a = not is_frame_a
				
				var sprite = _find_sprite_recursive(self)
				if sprite:
					if is_frame_a:
						sprite.texture = frame_a
						sprite.offset.y = base_offset_y
					else:
						sprite.texture = frame_b
						sprite.offset.y = base_offset_y + 12.0 


func update_ai_target_tile() -> void:
	ai_target_tile = grid_position + ai_attack_dir


func take_damage(amount: int) -> void:
	current_hp = clamp(current_hp - amount, 0, max_hp)
	hp_changed.emit(current_hp)
	
	print(unit_name, " took ", amount, " damage. Current HP: ", current_hp)
	if current_hp <= 0:
		die()


func die() -> void:
	print(unit_name, " was defeated!")
	queue_free()
