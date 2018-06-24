extends AnimatedSprite

func _ready():
	connect('animation_finished', self, 'destroy')
	play('throw')

func destroy():
	get_parent().remove_child(self)
	queue_free()