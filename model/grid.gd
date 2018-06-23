var size
var tile_size
var default
var coords
var cells

func _init(size, tile_size, default):
	self.size = size
	self.tile_size = tile_size
	self.default = default
	coords = []
	cells = []
	for y in range(size.y):
		for x in range(size.x):
			coords.append(Vector2(x, y))
			cells.append(null)

func has(coord):
	return coord.x >= 0 && coord.x < size.x && coord.y >= 0 && coord.y < size.y

func get(coord):
	if not has(coord):
		return default
	return cells[_idx(coord)]

func set(coord, value):
	assert(has(coord))
	cells[_idx(coord)] = value

func get_cell_center(coord):
	return Vector2(tile_size.x * coord.x + tile_size.x / 2, tile_size.y * coord.y + tile_size.y / 2)

func _idx(coord):
	return coord.y * size.x + coord.x

func neighbors(coord):
	var neigh = [
		Vector2(coord.x - 1, coord.y),
		Vector2(coord.x + 1, coord.y),
		Vector2(coord.x, coord.y - 1),
		Vector2(coord.x, coord.y + 1)
	]
	var i = 0
	while i < len(neigh):
		if not has(neigh[i]):
			neigh.remove(i)
		else:
			i += 1
	return neigh

func to_string():
	var lines = ""
	for y in range(size.y):
		for x in range(size.x):
			lines += "%d " % get(Vector2(x, y), null)
		if y != size.y - 1:
			lines += "\n"
	return lines
