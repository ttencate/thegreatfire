extends Node2D

signal throwing

var grid
var coord

var PANIC_SPEED = 1
var MANNING_SPEED = 2
var BUCKET_SPEED = 1
var THROW_SPEED = 3
var FILL_BUCKET_INTERVAL = 0

enum State { PANIC, MANNING, PASSING, CHEERING }
enum BucketDirection { IN, OUT }

var state = PANIC
var route = []
var fill_bucket_cooldown = 0
var bucket = null
var bucket_origin = null
var bucket_direction = null

onready var body = $body
onready var head = $head

func _ready():
	body.modulate = ColorN(Utils.random_item(["aliceblue", "antiquewhite", "aqua", "aquamarine", "azure", "beige", "bisque", "black", "blanchedalmond", "blue", "blueviolet", "brown", "burlywood", "cadetblue", "chartreuse", "chocolate", "coral", "cornflower", "cornsilk", "crimson", "cyan", "darkblue", "darkcyan", "darkgoldenrod", "darkgray", "darkgreen", "darkkhaki", "darkmagenta", "darkolivegreen", "darkorange", "darkorchid", "darkred", "darksalmon", "darkseagreen", "darkslateblue", "darkslategray", "darkturquoise", "darkviolet", "deeppink", "deepskyblue", "dimgray", "dodgerblue", "firebrick", "floralwhite", "forestgreen", "fuchsia", "gainsboro", "ghostwhite", "gold", "goldenrod", "gray", "webgray", "green", "webgreen", "greenyellow", "honeydew", "hotpink", "indianred", "indigo", "ivory", "khaki", "lavender", "lavenderblush", "lawngreen", "lemonchiffon", "lightblue", "lightcoral", "lightcyan", "lightgoldenrod", "lightgray", "lightgreen", "lightpink", "lightsalmon", "lightseagreen", "lightskyblue", "lightslategray", "lightsteelblue", "lightyellow", "lime", "limegreen", "linen", "magenta", "maroon", "webmaroon", "mediumaquamarine", "mediumblue", "mediumorchid", "mediumpurple", "mediumseagreen", "mediumslateblue", "mediumspringgreen", "mediumturquoise", "mediumvioletred", "midnightblue", "mintcream", "mistyrose", "moccasin", "navajowhite", "navyblue", "oldlace", "olive", "olivedrab", "orange", "orangered", "orchid", "palegoldenrod", "palegreen", "paleturquoise", "palevioletred", "papayawhip", "peachpuff", "peru", "pink", "plum", "powderblue", "purple", "webpurple", "rebeccapurple", "red", "rosybrown", "royalblue", "saddlebrown", "salmon", "sandybrown", "seagreen", "seashell", "sienna", "silver", "skyblue", "slateblue", "slategray", "snow", "springgreen", "steelblue", "tan", "teal", "thistle", "tomato", "turquoise", "violet", "wheat", "white", "whitesmoke", "yellow", "yellowgreen"]))

func initialize(grid, coord):
	self.grid = grid
	set_coord(coord)
	position = grid.get_cell_center(coord)

func _physics_process(delta):
	if state == PANIC and len(route) == 0:
		randomize_route()
	
	if len(route) > 0:
		var dest = grid.get_cell_center(route[0])
		if move_towards(self, dest, MANNING_SPEED if state == MANNING else PANIC_SPEED, delta):
			set_coord(route.pop_front())
	
	if state == MANNING and len(route) == 0:
		state = PASSING
		fill_bucket_cooldown = FILL_BUCKET_INTERVAL / 2
		var cell = grid.get(coord)
		if cell.manning_marker != null:
			cell.manning_marker.get_parent().remove_child(cell.manning_marker)
			cell.manning_marker.queue_free()
			cell.manning_marker = null
	
	if state == PASSING:
		if bucket == null:
			var water_cell = get_neighbor_water_cell()
			if water_cell != null:
				fill_bucket_cooldown -= delta
				if fill_bucket_cooldown <= 0:
					fill_bucket_cooldown += FILL_BUCKET_INTERVAL
					fill_bucket_from(water_cell)
		if bucket != null:
			if bucket_direction == OUT:
				var dest_coord = find_bucket_destination()
				if dest_coord != null:
					var dest = 0.5 * (grid.get_cell_center(dest_coord) - position)
					var throwing = grid.get(dest_coord).is_flammable
					var speed = THROW_SPEED if throwing else BUCKET_SPEED
					if throwing:
						bucket.rotation = -(dest_coord - coord).angle() + PI / 2
					else:
						bucket.rotation = 0
					if move_towards(bucket, dest, speed, delta):
						if throwing:
							throw_bucket(dest_coord)
						else:
							grid.get(dest_coord).manning_peep.receive_bucket_from(bucket, coord)
						bucket = null
				else:
					bucket_direction = IN
			if bucket_direction == IN:
				if move_towards(bucket, Vector2(0, 0), BUCKET_SPEED, delta):
					bucket_direction = OUT

func move_towards(node, dest, speed, delta):
	var dist = node.position.distance_to(dest)
	var frame_dist = delta * speed * grid.tile_size.x
	if dist > frame_dist:
		node.position += (dest - node.position).normalized() * frame_dist
		return false
	else:
		node.position = dest
		return true

func panic():
	destroy_bucket()
	state = PANIC

func cheer():
	destroy_bucket()
	route.clear()
	state = CHEERING

func man_cell(coord):
	state = MANNING
	route = find_route(self.coord, coord)

func get_neighbor_water_cell():
	for n in grid.neighbors(coord):
		if grid.get(n).is_water:
			return n
	return null

func fill_bucket_from(coord):
	bucket = preload('res://objects/bucket.tscn').instance()
	bucket.position = 0.5 * (grid.get_cell_center(coord) - position)
	add_child(bucket)
	bucket_origin = coord
	bucket_direction = IN

func receive_bucket_from(bucket, coord):
	self.bucket = bucket
	var prev_parent = bucket.get_parent()
	prev_parent.remove_child(bucket)
	bucket.position = (transform.inverse() * prev_parent.transform).xform(bucket.position)
	add_child(bucket)
	bucket_origin = coord
	bucket_direction = IN

func throw_bucket(dest):
	emit_signal('throwing', coord, dest)
	destroy_bucket()

func destroy_bucket():
	if bucket != null:
		bucket.get_parent().remove_child(bucket)
		bucket.queue_free()
		bucket = null

func find_bucket_destination():
	var cell = grid.get(coord)
	if cell.destination == null:
		return null
	var dest_cell = grid.get(cell.destination)
	if dest_cell.manning_peep != null and dest_cell.manning_peep.state == PASSING and dest_cell.manning_peep.bucket == null:
		return cell.destination
	elif dest_cell.is_flammable:
		return cell.destination
	return null

func set_coord(coord):
	if self.coord != null:
		grid.get(self.coord).peeps.erase(self)
	self.coord = coord
	grid.get(self.coord).peeps.push_back(self)

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