extends Node3D

# --- SIGNALS ---
signal hp_changed(new_hp: int)

@export_group("Basic Stats")
@export var unit_name: String = "Recruit"
@export_range(1, 10) var max_hp: int = 3
@export_range(1, 10) var movement_range: int = 3

@export_group("Combat Stats")
@export var attack_damage: int = 1
@export_range(1, 5) var attack_range: int = 1

@export_group("Faction Settings")
@export var is_enemy: bool = false

var ai_attack_dir: Vector2i = Vector2i.ZERO
var ai_target_tile: Vector2i = Vector2i.ZERO

var current_hp: int
var grid_position: Vector2i = Vector2i.ZERO
var has_acted_this_turn: bool = false

func _ready() -> void:
	current_hp = max_hp
	var sprite = get_node_or_null("Sprite3D")
	if sprite and sprite is Sprite3D:
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y

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
