extends Node3D
class_name GridInputHandler

signal tile_clicked(coords: Vector2i)
signal tile_hovered(coords: Vector2i)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var coords = get_tile_at_mouse_position(event.position)
		if coords != Vector2i(-999, -999):
			tile_clicked.emit(coords)
			
	elif event is InputEventMouseMotion:
		var coords = get_tile_at_mouse_position(event.position)
		# Emitimos SEMPRE o sinal de hover para que o controlador saiba quando o mouse saiu [1]
		tile_hovered.emit(coords)


func get_tile_at_mouse_position(mouse_pos: Vector2) -> Vector2i:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return Vector2i(-999, -999)
		
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.has_meta("grid_pos"):
		if result.normal.y < 0.9:
			return Vector2i(-999, -999)
			
		return result.collider.get_meta("grid_pos")
		
	return Vector2i(-999, -999)
