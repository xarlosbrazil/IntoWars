extends Object
class_name GridPathfinder

# NOVO: Validador estático de caminhos (Flood Fill) para impedir ilhas isoladas
static func is_path_possible(grid_cells: Dictionary, start: Vector2i, target: Vector2i, max_climb: float) -> bool:
	var queue: Array = [start]
	var visited: Dictionary = {start: true}
	var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	while not queue.is_empty():
		var current = queue.pop_front()
		if current == target:
			return true # Rota tática viável e escalável encontrada
			
		for dir in directions:
			var next: Vector2i = current + dir
			if grid_cells.has(next) and not visited.has(next):
				var h1: float = grid_cells[current].get_meta("height")
				var h2: float = grid_cells[next].get_meta("height")
				if abs(h1 - h2) <= max_climb:
					visited[next] = true
					queue.append(next)
					
	return false # Alvos isolados por mar ou penhascos intransponíveis


# Calculates reachable coordinates on the XZ grid using BFS with elevation checks
static func calculate_reachable_tiles(grid_cells: Dictionary, active_units: Dictionary, start: Vector2i, max_range: int, max_climb: float) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var queue: Array = [[start, 0]]
	var visited: Dictionary = {start: true}
	var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	while not queue.is_empty():
		var current = queue.pop_front()
		var current_coords: Vector2i = current[0]
		var current_cost: int = current[1]
		
		if current_cost > 0: 
			reachable.append(current_coords)
			
		if current_cost < max_range:
			for dir in directions:
				var next: Vector2i = current_coords + dir
				if grid_cells.has(next) and not visited.has(next):
					if not active_units.has(next):
						var h1: float = grid_cells[current_coords].get_meta("height")
						var h2: float = grid_cells[next].get_meta("height")
						if abs(h1 - h2) <= max_climb:
							visited[next] = true
							queue.append([next, current_cost + 1])
	return reachable


# Calculates orthogonally attackable targets in range
static func calculate_attackable_tiles(grid_cells: Dictionary, active_units: Dictionary, start: Vector2i, max_range: int) -> Array[Vector2i]:
	var attackable: Array[Vector2i] = []
	var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	for dir in directions:
		for step in range(1, max_range + 1):
			var target: Vector2i = start + (dir * step)
			if grid_cells.has(target) and active_units.has(target):
				var unit = active_units[target]
				if unit.is_enemy:
					attackable.append(target)
	return attackable


# Reconstructs the exact step-by-step path from start to target
static func calculate_path_to_target(grid_cells: Dictionary, active_units: Dictionary, start: Vector2i, target: Vector2i, max_range: int, max_climb: float) -> Array[Vector2i]:
	var queue: Array = [[start, 0]]
	var visited: Dictionary = {start: true}
	var parents: Dictionary = {}
	var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var found: bool = false
	
	while not queue.is_empty():
		var current = queue.pop_front()
		var current_coords: Vector2i = current[0]
		var current_cost: int = current[1]
		
		if current_coords == target:
			found = true
			break
			
		if current_cost < max_range:
			for dir in directions:
				var next: Vector2i = current_coords + dir
				if grid_cells.has(next) and not visited.has(next):
					if not active_units.has(next) or next == target:
						var h1: float = grid_cells[current_coords].get_meta("height")
						var h2: float = grid_cells[next].get_meta("height")
						if abs(h1 - h2) <= max_climb:
							visited[next] = true
							parents[next] = current_coords
							queue.append([next, current_cost + 1])
	
	var path: Array[Vector2i] = []
	if found:
		var curr: Vector2i = target
		while curr != start:
			path.append(curr)
			curr = parents[curr]
		path.reverse()
	return path
