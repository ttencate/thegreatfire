extends Node

func _ready():
	pause_mode = PAUSE_MODE_PROCESS

func _unhandled_input(event):
	if OS.has_feature("debug"):
		if event is InputEventKey and event.pressed:
			match event.scancode:
				KEY_ESCAPE:
					get_tree().quit()
					return