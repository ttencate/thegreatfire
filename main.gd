extends Node2D

var LEVELS = [
	'res://levels/level_01.tscn',
]
var current_level = null

onready var level_root = find_node('level_root')
onready var prev_button = find_node('prev_button')
onready var next_button = find_node('next_button')

func _ready():
	start_level(LEVELS[0])

func start_level(level):
	for child in level_root.get_children():
		child.queue_free()
	
	current_level = level
	
	var level_scene = load(level).instance()
	level_root.add_child(level_scene)
	level_scene.connect('won', self, 'on_level_won')
	
	var re = RegEx.new()
	re.compile('[1-9]\\d*')
	find_node('level_text').text = 'Level %s' % re.search(level).get_string()
	
	prev_button.disconnect('pressed', self, 'start_level')
	prev_button.disabled = true
	next_button.disconnect('pressed', self, 'start_level')
	next_button.disabled = true
	var prev_level = get_prev_level(level)
	if prev_level:
		prev_button.disabled = false
		prev_button.connect('pressed', self, 'start_level', [prev_level])
	var next_level = get_next_level(level)
	if next_level:
		next_button.disabled = false
		next_button.connect('pressed', self, 'start_level', [next_level])

func on_level_won(percent_survived):
	var win_screen = preload('res://ui/win_screen.tscn').instance()
	win_screen.initialize(current_level, percent_survived, get_next_level(current_level))
	add_child(win_screen)
	win_screen.connect('start_level', self, 'start_level')

func get_level_index(level):
	for i in range(len(LEVELS)):
		if LEVELS[i] == level:
			return i
	return null

func get_next_level(level):
	var i = get_level_index(level)
	if i < len(LEVELS) - 1:
		return LEVELS[i + 1]
	else:
		return null

func get_prev_level(level):
	var i = get_level_index(level)
	if i > 0:
		return LEVELS[i - 1]
	else:
		return null