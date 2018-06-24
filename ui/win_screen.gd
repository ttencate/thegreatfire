extends Node2D

signal start_level(level)

var percent_survived = 0
export (float) var counting_fraction = 0 setget set_counting_fraction

onready var percentage = find_node('percentage')

func _ready():
	$animation_player.play('fade_in')
	set_counting_fraction(counting_fraction)

func initialize(level, percent_survived, next_level):
	self.percent_survived = percent_survived
	find_node('retry_button').connect('pressed', self, 'on_start_level', [level])
	if next_level != null:
		find_node('next_button').connect('pressed', self, 'on_start_level', [next_level])
	else:
		find_node('next_button').queue_free()

func set_counting_fraction(f):
	counting_fraction = f
	if percentage != null:
		percentage.text = '%s%%' % round(counting_fraction * percent_survived)

func on_start_level(level):
	queue_free()
	emit_signal('start_level', level)