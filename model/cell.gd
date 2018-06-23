var coord
var is_walkable = false
var is_water = true
var peeps = []

func _init(coord, tile_name):
	self.coord = coord
	
	var idx = tile_name.find('_')
	var kind = tile_name.left(idx) if idx >= 0 else tile_name
	if kind == 'street':
		is_walkable = true
	elif kind == 'water':
		is_water = true