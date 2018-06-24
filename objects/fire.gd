extends AnimatedSprite

var MAX_SIZE = 5
var GROW_INTERVAL = 3
var GROW_INTERVAL_RANDOM = 0.3
var GROW_RANGES = [
	-1,
	0,
	0,
	1,
	1,
	2
]

signal spreading(coord, size)

var grid
var coord
var size = 1 setget set_size

var time_until_grow = 0

func initialize(grid, coord):
	self.grid = grid
	self.coord = coord
	grid.get(coord).fire = self
	position = grid.get_cell_center(coord)
	set_size(1)
	time_until_grow = GROW_INTERVAL * rand_range(1 - GROW_INTERVAL_RANDOM, 1 + GROW_INTERVAL_RANDOM)

func _physics_process(delta):
	time_until_grow -= delta
	if time_until_grow <= 0:
		grow()
		time_until_grow = GROW_INTERVAL * rand_range(1 - GROW_INTERVAL_RANDOM, 1 + GROW_INTERVAL_RANDOM)

func grow():
	var candidates = []
	var r = GROW_RANGES[size]
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var d = Vector2(dx, dy)
			if d.length() > r:
				continue
			candidates.push_back(coord + d)
	var candidate = Utils.random_item(candidates)
	var cell = grid.get(candidate)
	if cell.is_flammable:
		if cell.fire == null:
			emit_signal('spreading', candidate, 1)
		else:
			cell.fire.set_size(cell.fire.size + 1)

func set_size(size_):
	size_ = min(size_, MAX_SIZE)
	size = size_
	play(str(size))