extends Node2D

const CONFIG_FILE = 'user://settings.cfg'

var LEVELS = []
var current_level = null
var max_level = null

onready var level_root = find_node('level_root')
onready var pause_button = find_node('pause_button')
onready var prev_button = find_node('prev_button')
onready var next_button = find_node('next_button')

func _ready():
	var i = 1
	while true:
		var level = 'res://levels/level_%02d.tscn' % i
		if not File.new().file_exists(level):
			break
		LEVELS.push_back(level)
		i += 1
	
	pause_button.connect('pressed', self, 'toggle_pause')
	
	load_config()
	start_level(current_level)

func load_config():
	current_level = LEVELS[0]
	max_level = LEVELS[0]
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE)
	if err == OK:
		current_level = check_level(config.get_value('progress', 'current_level'), current_level)
		max_level = check_level(config.get_value('progress', 'max_level'), max_level)

func save_config():
	var config = ConfigFile.new()
	config.set_value('progress', 'current_level', current_level)
	config.set_value('progress', 'max_level', max_level)
	config.save(CONFIG_FILE)

func check_level(level, fallback):
	if LEVELS.find(level) >= 0:
		return level
	return fallback

func start_level(level):
	for child in level_root.get_children():
		child.queue_free()
	
	current_level = level
	save_config()
	
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
	
	if get_tree().paused:
		toggle_pause()

func toggle_pause():
	get_tree().paused = !get_tree().paused
	if get_tree().paused:
		pause_button.icon = preload('res://ui/play.png')
	else:
		pause_button.icon = preload('res://ui/pause.png')

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.scancode == KEY_SPACE:
		toggle_pause()

func on_level_won(percent_survived):
	var next_level = get_next_level(current_level)
	if current_level == max_level and next_level != null:
		max_level = next_level
		save_config()
	
	var win_screen = preload('res://ui/win_screen.tscn').instance()
	win_screen.initialize(current_level, percent_survived, next_level)
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