extends Node2D

func fire(coord: Vector2) -> void:
	global_position = coord
	$Rocket.emitting = true
