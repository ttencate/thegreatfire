var coord
var is_walkable = false
var is_mannable = false
var is_water = false
var is_flammable = false
var is_collapsed = false
var num_inhabitants = 0
var uninhabited_tile_name = null

var fire = null

var peeps = []
var manning = false
var manning_peep = null
var manning_marker = null

var destination = null
var arrow = null

func _init(coord, tile_name):
	self.coord = coord
	
	var idx = tile_name.find('_')
	var kind = tile_name.left(idx) if idx >= 0 else tile_name
	if kind == 'street':
		is_walkable = true
		is_mannable = true
	elif kind == 'water':
		is_water = true
	elif kind == 'house':
		is_flammable = true
		if tile_name.find('house_lit') == 0:
			num_inhabitants = 1
			uninhabited_tile_name = tile_name.replace('house_lit', 'house')
	elif kind == 'rubble':
		is_collapsed = true

func to_string():
	var flags = ''
	if is_walkable: flags += 'w'
	if is_mannable: flags += 'm'
	if is_water: flags += '~'
	if is_flammable: flags += 'f'
	return '%s[%s, destination=%s]' % [coord, flags, destination]