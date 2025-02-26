extends Node2D

const ColorLayer = preload("res://ColorLayer.gd")
const Board = preload("res://Board.gd")

func _ready() -> void:
	add_child(Board)
	
	
func _process(delta: float) -> void:
	pass
