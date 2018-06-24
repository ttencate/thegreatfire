extends Node2D

signal won(percent_survived)

const Cell = preload('res://model/cell.gd')
const Grid = preload('res://model/grid.gd')

onready var tile_map = find_node('tile_map')
onready var objects = find_node('objects')
onready var overlay = find_node('overlay')
onready var cursor = find_node('cursor')
var grid

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
		if tile_name == 'peep_1':
			spawn_peep(coord)
		elif tile_name.left(5) == 'fire_':
			spawn_fire(coord, int(tile_name[5]))
	init.get_parent().remove_child(init)
	init.queue_free()
	
	cursor.hide()

func spawn_peep(coord):
	var peep = preload('res://objects/peep.tscn').instance()
	objects.add_child(peep)
	peep.initialize(grid, coord)
	peep.connect('throwing', self, 'on_peep_throwing')

func spawn_fire(coord, size):
	var fire = preload('res://objects/fire.tscn').instance()
	objects.add_child(fire)
	fire.initialize(grid, coord)
	fire.size = size
	fire.connect('spreading', self, 'on_fire_spreading')
	fire.connect('collapsing', self, 'on_fire_collapsing')
	
	var cell = grid.get(coord)
	if cell.num_inhabitants > 0:
		tile_map.set_cell(coord.x, coord.y, tile_map.tile_set.find_tile_by_name(cell.uninhabited_tile_name))
		for i in range(cell.num_inhabitants):
			spawn_peep(cell.coord)

func on_fire_spreading(coord, size):
	spawn_fire(coord, size)

func on_fire_collapsing(coord):
	var cell = grid.get(coord)
	destroy_fire(cell)
	tile_map.set_cell(coord.x, coord.y, tile_map.tile_set.find_tile_by_name('rubble'))
	cell.is_flammable = false
	cell.is_collapsed = true

func reduce_fire(coord):
	var cell = grid.get(coord)
	if cell.fire != null:
		if cell.fire.size > 1:
			cell.fire.set_size(cell.fire.size - 1)
		else:
			destroy_fire(cell)

func destroy_fire(cell):
	if cell.fire != null:
		cell.fire.get_parent().remove_child(cell.fire)
		cell.fire.queue_free()
		cell.fire = null
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
						set_destination(from, coord)
				elif from.is_mannable and not from.manning and to.manning:
					unman_cell(to)
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