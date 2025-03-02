extends Node2D

func glow(coord: Vector2, mod: Color = Color(1, 1, 1, 1)) -> void:
	global_position = coord
	mod.a = 0.8
	$Glow.modulate = mod
	$Glow.emitting = true

func stop_glow():
	print("stopping glow at position ", global_position)
	await get_tree().create_timer(0.05).timeout
	$Glow.emitting = false
	queue_free()
	return
