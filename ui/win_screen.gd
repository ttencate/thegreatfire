extends Node2D

signal start_level(level)

var percent_survived = 0
var prev_highscore = 0
var is_new_highscore = false
export (float) var counting_fraction = 0 setget set_counting_fraction

var REMARKS = [
	'Baptism of fire.',
	'Full of hot air.',
	'Not too hot.',
	'Out of the frying pan into the fire.',
	'Like a moth to a flame.',
	'Playing with fire.',
	'Going cold turkey.',
	'Like a hot knife through butter.',
	'You\'re on fire!',
	'A cold day in hell.',
]

onready var percentage = find_node('percentage')
onready var highscore = find_node('highscore')
onready var remark = find_node('remark')

func _ready():
	$animation_player.play('fade_in')
	set_counting_fraction(counting_fraction)
	remark.text = REMARKS[clamp(floor(percent_survived / 100 * (len(REMARKS) - 1)), 0, len(REMARKS) - 1)]
	if is_new_highscore:
		if prev_highscore == null:
			highscore.text = ''
		else:
			highscore.text = 'New best! Previous best: %d*' % [round(prev_highscore)]
	else:
		highscore.text = 'Best: %d*' % [round(prev_highscore)]

func initialize(level, percent_survived, prev_highscore, is_new_highscore, next_level):
	self.percent_survived = percent_survived
	self.prev_highscore = prev_highscore
	self.is_new_highscore = is_new_highscore
	find_node('retry_button').connect('pressed', self, 'on_start_level', [level])
	if next_level != null:
		find_node('next_button').connect('pressed', self, 'on_start_level', [next_level])
	else:
		find_node('next_button').queue_free()

func set_counting_fraction(f):
	counting_fraction = f
	if percentage != null:
		percentage.text = '%d%%' % round(counting_fraction * percent_survived)

func on_start_level(level):
	queue_free()
	emit_signal('start_level', level)