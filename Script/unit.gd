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
	# Programação Defensiva: Só consome do recurso se o valor não for nulo (Nil) [1, 2]
	if unit_data:
		var d_name = unit_data.get("unit_name")
		if d_name != null: unit_name = d_name
		
		var d_max_hp = unit_data.get("max_hp")
		if d_max_hp != null: max_hp = d_max_hp
		
		var d_move = unit_data.get("movement_range")
		if d_move != null: movement_range = d_move
		
		var d_dmg = unit_data.get("attack_damage")
		if d_dmg != null: attack_damage = d_dmg
		
		var d_range = unit_data.get("attack_range")
		if d_range != null: attack_range = d_range
		
		# Define a textura inicial (Frame A) se presente
		var d_tex_a = unit_data.get("sprite_frame_a")
		var sprite = get_node_or_null("Sprite3D")
		if sprite and sprite is Sprite3D and d_tex_a != null:
			sprite.texture = d_tex_a
			
	current_hp = max_hp
	
	var sprite = get_node_or_null("Sprite3D")
	if sprite and sprite is Sprite3D:
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		if sprite.texture:
			sprite.offset = Vector2(0, sprite.texture.get_size().y / 2.0)
			base_offset_y = sprite.offset.y


func _process(delta: float) -> void:
	# Executa o ciclo de animação de 2 frames de forma segura [2]
	if unit_data:
		var frame_a = unit_data.get("sprite_frame_a")
		var frame_b = unit_data.get("sprite_frame_b")
		
		if frame_a != null and frame_b != null:
			animation_timer += delta
			if animation_timer >= animation_interval:
				animation_timer = 0.0
				is_frame_a = not is_frame_a
				
				var sprite = get_node_or_null("Sprite3D")
				if sprite and sprite is Sprite3D:
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
