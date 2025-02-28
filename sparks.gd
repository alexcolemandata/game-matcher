extends Node2D

func fire(coord: Vector2, mod: Color = Color(1, 1, 1, 1)) -> void:
	global_position = coord
	modulate = mod
	$Blast.emitting = true
