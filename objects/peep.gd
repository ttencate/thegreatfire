extends Node2D

var grid
var coord

enum State { PANIC, MANNING, PASSING }

var state = PANIC
var route = []
var speed = 2

func initialize(grid, coord):
	self.grid = grid
	set_coord(coord)
	position = grid.get_cell_center(coord)

func _physics_process(delta):
	if state == PANIC and len(route) == 0:
		randomize_route()
	
	var remaining_dist = delta * speed * grid.tile_size.x
	while remaining_dist > 0:
		if len(route) == 0:
			break
		var dest = grid.get_cell_center(route[0])
		var dist = position.distance_to(dest)
		if dist > remaining_dist:
			position += (dest - position).normalized() * remaining_dist
			break
		else:
			position = dest
			remaining_dist -= dist
			set_coord(route.pop_front())
	
	if state == MANNING and len(route) == 0:
		state = PASSING
		var cell = grid.get(coord)
		if cell.manning_marker != null:
			cell.manning_marker.get_parent().remove_child(cell.manning_marker)
			cell.manning_marker = null

func randomize_route():
	var at = coord
	for i in range(4 + randi() % 4):
		var walkable_neighbors = []
		for coord in grid.neighbors(at):
			if grid.get(coord).is_walkable and not (coord in route):
				walkable_neighbors.push_back(coord)
		if len(walkable_neighbors) == 0:
			break
		var next = Utils.random_item(walkable_neighbors)
		route.push_back(next)
		at = next

func panic():
	state = PANIC

func man_cell(coord):
	state = MANNING
	route = find_route(self.coord, coord)

func set_coord(coord):
	if self.coord != null:
		grid.get(self.coord).peeps.erase(self)
	self.coord = coord
	grid.get(self.coord).peeps.push_back(self)

func find_route(from, to):
	var queue = [from]
	var visited = {}
	var came_from = {}
	while len(queue) > 0:
		var c = queue.pop_front()
		if visited.has(c):
			continue
		visited[c] = true
		var cell = grid.get(c)
		if not cell.is_walkable:
			continue
		if c == to:
			var route = [to]
			while c != from:
				c = came_from[c]
				route.push_front(c)
			return route
		for n in grid.neighbors(c):
			if not came_from.has(n):
				came_from[n] = c
			queue.push_back(n)
	return null