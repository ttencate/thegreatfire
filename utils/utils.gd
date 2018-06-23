extends Node

static func random_item(array):
	return array[randi() % len(array)]