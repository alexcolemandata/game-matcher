extends Node

func display_str(str, position: Vector2, color: String, font_size: int):
	var lbl = Label.new()
	lbl.global_position = position
	lbl.text = str(str)
	lbl.z_index = 5
	lbl.label_settings = LabelSettings.new()
	
	lbl.label_settings.font_size = font_size
	lbl.label_settings.font_color = color
	lbl.label_settings.outline_color = "#000"
	lbl.label_settings.outline_size = 1
	
	call_deferred("add_child", lbl)
	
	await lbl.resized
	lbl.pivot_offset = Vector2(lbl.size / 2)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		lbl, "position:y", lbl.position.y - 80, 0.25
	).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(
		lbl, "position:y", lbl.position.y, 0.5
	).set_ease(Tween.EASE_IN).set_delay(0.22 + (font_size/120))
	
	tween.tween_property(
		lbl, "scale", Vector2.ZERO, 0.25
	).set_ease(Tween.EASE_IN).set_delay(0.4 + (font_size/120))
		
	await tween.finished
	lbl.queue_free()
	return
	

func display_number(value: int, position: Vector2, color: String):
	display_str("+"+str(value), position, color, value * 10)
	
	
