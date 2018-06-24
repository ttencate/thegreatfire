extends ColorRect

signal proceed

func _ready():
	$animation_player.play('fade_in')

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		emit_signal('proceed')
		$animation_player.play('fade_out')