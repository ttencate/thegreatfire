extends Node2D

signal won(percent_survived)
signal idle_peeps_changed(idle_peeps)

const Cell = preload('res://model/cell.gd')
const Grid = preload('res://model/grid.gd')

onready var tile_map = find_node('tile_map')
onready var objects = find_node('objects')
onready var overlay = find_node('overlay')
onready var cursor = find_node('cursor')
onready var crackling = find_node('crackling')
onready var click = find_node('click')
onready var pop = find_node('pop')
var grid
var peeps = []
var tutorials = []

var is_won = false

func _ready():
	var default_cell = Cell.new(Vector2(-1, -1), 'grass_1')
	grid = Grid.new(tile_map.get_used_rect().size, tile_map.cell_size, default_cell)
	for coord in grid.coords:
		grid.set(coord, Cell.new(coord, tile_map.tile_set.tile_get_name(tile_map.get_cell(coord.x, coord.y))))
	
	var init = find_node('init')
	for coord in grid.coords:
		var tile_id = init.get_cell(coord.x, coord.y)
		if tile_id < 0:
			continue
		var tile_name = init.tile_set.tile_get_name(tile_id)
		if tile_name.left(5) == 'peep_':
			spawn_peep(coord)
		elif tile_name.left(5) == 'fire_':
			spawn_fire(coord, int(tile_name[5]))
	update_peep_counter()
	init.get_parent().remove_child(init)
	init.queue_free()
	
	cursor.hide()
	
	crackling.play()
	crackling.connect('finished', crackling, 'play')
	update_crackling_volume()
	
	$bell.play()
	
	$tutorial_timer.connect('timeout', self, 'show_next_tutorial')
	for child in get_children():
		if child.name.left(9) == 'tutorial_' and child is TileMap:
			child.hide()
			tutorials.push_back(child)
	$tutorial_timer.start()

func show_next_tutorial():
	if len(tutorials) == 0:
		return
	tutorials[0].show()

func check_tutorial_completed(from_cell, to_cell):
	if len(tutorials) == 0:
		return
	var tutorial = tutorials[0]
	if tutorial.name.find('_unset') >= 0:
		if from_cell.destination != null:
			return
	else:
		if from_cell.destination != to_cell.coord:
			return
	var tile_id = tutorial.get_cell(to_cell.coord.x, to_cell.coord.y)
	if tile_id < 0:
		return
	var tile_name = tutorial.tile_set.tile_get_name(tile_id)
	match [tile_name, to_cell.coord - from_cell.coord]:
		['tutorial_5', Vector2(0, -1)], ['tutorial_7', Vector2(1, 0)], ['tutorial_8', Vector2(-1, 0)]:
			tutorials.pop_front().queue_free()
			$tutorial_timer.start()

func spawn_peep(coord):
	var peep = preload('res://objects/peep.tscn').instance()
	objects.add_child(peep)
	peep.initialize(grid, coord)
	peep.connect('throwing', self, 'on_peep_throwing')
	peep.connect('state_changed', self, 'update_peep_counter')
	peeps.push_back(peep)
	update_peep_counter()
	return peep

func update_peep_counter():
	var idle_peeps = 0
	for peep in peeps:
		if peep.state == peep.PANIC:
			idle_peeps += 1
	emit_signal('idle_peeps_changed', idle_peeps)

var fire_yells = 0

func _physics_process(delta):
	fire_yells = 0
	if not $bell.playing and randf() / delta < 0.1:
		$bell.play()

func spawn_fire(coord, size):
	var cell = grid.get(coord)
	if cell.is_explosive:
		explode(cell)
		return
	
	var fire = preload('res://objects/fire.tscn').instance()
	objects.add_child(fire)
	fire.initialize(grid, coord)
	fire.size = size
	fire.connect('spreading', self, 'on_fire_spreading')
	fire.connect('collapsing', self, 'on_fire_collapsing')
	
	update_crackling_volume()
	
	if cell.num_inhabitants > 0:
		for i in range(cell.num_inhabitants):
			var peep = spawn_peep(cell.coord)
			if fire_yells == 0:
				peep.yell_fire()
				fire_yells += 1
		tile_map.set_cell(coord.x, coord.y, tile_map.tile_set.find_tile_by_name(cell.uninhabited_tile_name))
		cell.num_inhabitants = 0

func update_crackling_volume():
	var total_fire = 0
	for coord in grid.coords:
		var cell = grid.get(coord)
		if cell.fire != null:
			total_fire += cell.fire.size
	if total_fire == 0:
		crackling.stop()
	else:
		crackling.volume_db = linear2db(float(total_fire) / 50) - 3

func explode(cell):
	cell.is_explosive = false
	for n in grid.neighbors(cell.coord):
		var nc = grid.get(n)
		if nc.is_flammable:
			if nc.fire == null:
				spawn_fire(n, 3)
			else:
				nc.fire.set_size(nc.fire.size + 2)
	on_fire_collapsing(cell.coord)

func on_fire_spreading(coord, size):
	spawn_fire(coord, size)

func on_fire_collapsing(coord):
	var cell = grid.get(coord)
	destroy_fire(cell)
	tile_map.set_cell(coord.x, coord.y, tile_map.tile_set.find_tile_by_name('rubble'))
	cell.is_walkable = true
	cell.is_mannable = true
	cell.is_flammable = false
	cell.is_collapsed = true

func reduce_fire(coord):
	var cell = grid.get(coord)
	if cell.fire != null:
		if cell.fire.size > 1:
			cell.fire.set_size(cell.fire.size - 1)
		else:
			destroy_fire(cell)
	update_crackling_volume()

func destroy_fire(cell):
	if cell.fire != null:
		cell.fire.get_parent().remove_child(cell.fire)
		cell.fire.queue_free()
		cell.fire = null
	update_crackling_volume()
	check_win()

func on_peep_throwing(from, to):
	var thrown_water = preload('res://objects/thrown_water.tscn').instance()
	thrown_water.position = grid.get_cell_center(to)
	thrown_water.rotation = (to - from).angle()
	objects.add_child(thrown_water)
	
	reduce_fire(to)

func check_win():
	if is_won:
		return
	var num_flammable = 0
	var num_collapsed = 0
	for c in grid.coords:
		var cell = grid.get(c)
		if cell.fire != null:
			return
		if cell.is_flammable:
			num_flammable += 1
		if cell.is_collapsed:
			num_collapsed += 1
	is_won = true
	cursor.hide()
	for c in grid.coords:
		var cell = grid.get(c)
		set_destination(cell, null)
		for peep in cell.peeps:
			peep.cheer()
	emit_signal('won', float(num_flammable) / (num_flammable + num_collapsed) * 100)

var drag_from_coord = null

func _input(event):
	if is_won:
		return
	if event is InputEventMouse:
		var coord = tile_map.world_to_map(tile_map.to_local(event.global_position))
		if not grid.has(coord):
			cursor.hide()
			return
		var cell = grid.get(coord)
		cursor.show()
		cursor.position = grid.get_cell_center(coord)
		# print(cell.to_string())
		
		if drag_from_coord != null and coord != drag_from_coord:
			if (coord - drag_from_coord).length_squared() == 1:
				var from = grid.get(drag_from_coord)
				var to = grid.get(coord)
				if from.is_water or from.manning:
					if to.is_mannable and not to.manning:
						man_cell(to)
					if (from.is_water and to.manning) or (from.manning and (to.is_flammable or to.manning)):
						click.pitch_scale = rand_range(0.9, 1.1)
						click.play()
						set_destination(from, coord)
				elif not from.manning and to.manning:
					pop.pitch_scale = rand_range(0.9, 1.1)
					pop.play()
					unman_cell(to)
				check_tutorial_completed(from, to)
			drag_from_coord = coord
		
		if event is InputEventMouseButton:
			if event.is_pressed() and event.button_index == BUTTON_LEFT:
				drag_from_coord = coord
			else:
				drag_from_coord = null
			if OS.has_feature("debug") and event.is_pressed() and event.button_index == BUTTON_RIGHT:
				destroy_fire(cell)

func man_cell(cell):
	var peep = find_nearest_idle_peep(cell.coord)
	if peep == null:
		# TODO show useful message
		return
	cell.manning_peep = peep
	peep.man_cell(cell.coord)
	cell.manning = true
	var marker = preload('res://objects/manning_marker.tscn').instance()
	marker.position = grid.get_cell_center(cell.coord)
	cell.manning_marker = marker
	overlay.add_child(marker)

func unman_cell(cell):
	cell.manning = false
	if cell.manning_marker != null:
		cell.manning_marker.get_parent().remove_child(cell.manning_marker)
		cell.manning_marker.queue_free()
		cell.manning_marker = null
	if cell.manning_peep != null:
		cell.manning_peep.panic()
		cell.manning_peep = null
	set_destination(cell, null)
	
	for n in grid.neighbors(cell.coord):
		var neighbor = grid.get(n)
		if neighbor.destination == cell.coord:
			set_destination(neighbor, null)

func set_destination(cell, destination):
	cell.destination = destination
	if cell.destination != null:
		if cell.arrow == null:
			cell.arrow = preload('res://objects/arrow.tscn').instance()
			overlay.add_child(cell.arrow)
			cell.arrow.position = grid.get_cell_center(cell.coord)
		cell.arrow.set_direction(cell.destination - cell.coord)
	else:
		if cell.arrow != null:
			cell.arrow.get_parent().remove_child(cell.arrow)
			cell.arrow.queue_free()
			cell.arrow = null

func find_nearest_idle_peep(coord):
	var queue = [coord]
	var visited = {}
	while len(queue) > 0:
		var c = queue.pop_front()
		if visited.has(c):
			continue
		visited[c] = true
		var cell = grid.get(c)
		if not cell.is_walkable:
			continue
		for peep in cell.peeps:
			if peep.state == peep.PANIC:
				return peep
		for n in grid.neighbors(c):
			queue.push_back(n)
	return null