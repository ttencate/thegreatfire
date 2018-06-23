extends Node2D

export (int) var initial_peeps = 0

const Cell = preload('res://model/cell.gd')
const Grid = preload('res://model/grid.gd')

onready var tile_map = find_node('tile_map')
onready var objects = find_node('objects')
var grid

func _ready():
	var default_cell = Cell.new(Vector2(-1, -1), 'grass_1')
	grid = Grid.new(tile_map.get_used_rect().size, tile_map.cell_size, default_cell)
	for coord in grid.coords:
		grid.set(coord, Cell.new(coord, tile_map.tile_set.tile_get_name(tile_map.get_cell(coord.x, coord.y))))
	
	var street_cells = []
	for cell in grid.cells:
		if cell.is_walkable:
			street_cells.push_back(cell)
	for i in range(initial_peeps):
		spawn_peep(Utils.random_item(street_cells).coord)

func spawn_peep(coord):
	var peep = preload('res://objects/peep.tscn').instance()
	objects.add_child(peep)
	peep.initialize(grid, coord)