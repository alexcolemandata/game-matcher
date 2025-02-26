extends Node2D

const DEFAULT_LAYER = preload("res://default_layer.tscn")
const MAIN_SOURCE_ID = 0
const GREEN_TILE = Vector2i(4, 0)
const ORANGE_TILE = Vector2i(5, 0)
const BLUE_TILE = Vector2i(6, 0)

var tile: Vector2i
var layer: TileMapLayer

func _init(color: String):
	if color.to_lower() == "green":
		self.tile = GREEN_TILE
	elif color.to_lower() == "orange":
		self.tile = ORANGE_TILE
	else:
		self.tile = BLUE_TILE
		
	self.layer = DEFAULT_LAYER.instantiate()
	add_child(self.layer)
	
func draw_coords(coords: Vector2i):
	self.layer.set_cell(coords, MAIN_SOURCE_ID, self.tile)
