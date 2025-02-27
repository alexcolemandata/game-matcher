extends Node2D

const DEFAULT_LAYER = preload("res://default_layer.tscn")
const MIN_TILES_TO_SCORE = 4
const MAX_PIECE_SIZE = 5
const HEIGHT = 18
const WIDTH = 40
const MAIN_SOURCE_ID = 0

const LIGHT_BLUE_TILE = Vector2i(0, 0)
const PURPLE_TILE = Vector2i(1, 0)
const YELLOW_TILE = Vector2i(2, 0)
const RED_TILE = Vector2i(3, 0)
const GREEN_TILE = Vector2i(4, 0)
const ORANGE_TILE = Vector2i(5, 0)
const BLUE_TILE = Vector2i(6, 0)
const GREY_TILE = Vector2i(7, 0)
const TILES = [
	LIGHT_BLUE_TILE, 
	PURPLE_TILE, 
	YELLOW_TILE, 
	RED_TILE, 
	GREEN_TILE, 
	ORANGE_TILE, 
	BLUE_TILE, 
]

var border: TileMapLayer
var placed_tiles: TileMapLayer
var active_piece: TileMapLayer
var score = 0


func _ready():
	placed_tiles = DEFAULT_LAYER.instantiate()
	active_piece = DEFAULT_LAYER.instantiate()
	border = DEFAULT_LAYER.instantiate()
	add_child(border)
	add_child(placed_tiles)
	add_child(active_piece)
	
	init_border()
	spawn_piece()


func _input(event) -> void:
	if event.is_action_pressed("spawn piece"):
		place_piece()
		clear_scored_pieces()
		spawn_piece()
	elif event.is_action_pressed("down"):
		move_piece(Vector2i(0, 1))
	elif event.is_action_pressed("up"):
		move_piece(Vector2i(0, -1))
	elif event.is_action_pressed("left"):
		move_piece(Vector2i(-1, 0))
	elif event.is_action_pressed("right"):
		move_piece(Vector2i(1, 0))
	elif event.is_action_pressed("rotate anticlockwise"):
		rotate_anticlockwise()
	elif event.is_action_pressed("rotate clockwise"):
		rotate_clockwise()

var num_steps: int = 0
const MAX_STEPS: int = 10
func _process(delta) -> void:
	if (
		Input.is_action_pressed("down") 
		or Input.is_action_pressed("up") 
		or Input.is_action_pressed("left") 
		or Input.is_action_pressed("right")
	):
		num_steps += 1
		if num_steps >= MAX_STEPS:
			_input(Input)
			num_steps = 0
	

func init_border() -> void:
	print("init_border")
	var half_height = int(HEIGHT / 2)
	var half_width = int(WIDTH / 2)
	for x in range(half_width):
		draw_coords(border, Vector2i(x, half_height), GREY_TILE)
		draw_coords(border, Vector2i(x, -half_height), GREY_TILE)

		if x > 0:
			draw_coords(border, Vector2i(-x, half_height), GREY_TILE)
			draw_coords(border, Vector2i(-x, -half_height), GREY_TILE)
	
	for y in range(half_height):
		draw_coords(border, Vector2i(half_width, y), GREY_TILE)
		draw_coords(border, Vector2i(-half_width, y), GREY_TILE)
		
		if y > 0:
			draw_coords(border, Vector2i(half_width, -y), GREY_TILE)
			draw_coords(border, Vector2i(-half_width, -y), GREY_TILE)
			
	draw_coords(border, Vector2i(half_height, half_width), GREY_TILE)
	draw_coords(border, Vector2i(half_height, -half_width), GREY_TILE)
	draw_coords(border, Vector2i(-half_height, half_width), GREY_TILE)
	draw_coords(border, Vector2i(-half_height, -half_width), GREY_TILE)
			
	pass
			
		
func clear_scored_pieces() -> void:
	print("clear_scored_pieces")
	var scored_tiles: Array[Vector2i] = []
	for color_to_check in TILES:
		
		var tiles_for_color = placed_tiles.get_used_cells_by_id(MAIN_SOURCE_ID, color_to_check)
		
		if tiles_for_color.size() < MIN_TILES_TO_SCORE:
			continue 
		
		print("checking for scored color, ", color_to_check)
		var checked_tiles: Array[Vector2i] = []
				
		for tile_to_check in tiles_for_color:
			if (tile_to_check in checked_tiles):
				continue
				
			var tiles_to_check: Array[Vector2i] = []
			for t in tiles_for_color:
				if t not in checked_tiles:
					tiles_to_check.append(t)
				
			var neighbors = get_tile_flood_fill(tile_to_check, tiles_to_check)
			checked_tiles.append_array(neighbors)
			
			if neighbors.size() >= MIN_TILES_TO_SCORE:
				print("Scored! ", neighbors.size())
				scored_tiles.append_array(neighbors)
				
				
			continue
							
	print("Total scored: ", scored_tiles.size())
	score += scored_tiles.size()
	%Score.text = str(score)
	for scored_tile in scored_tiles:
		placed_tiles.erase_cell(scored_tile)
	
	return


func get_tile_flood_fill(coord: Vector2i, tiles: Array[Vector2i], flooded: Array[Vector2i] = []) -> Array[Vector2i]:
	var idx = tiles.find(coord)
	if idx < 0:
		return flooded
		
	flooded.append(coord)
	tiles.pop_at(idx)
	
	for neighbor in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		flooded = get_tile_flood_fill(coord + neighbor, tiles, flooded)
		
	return flooded


func rotate_anticlockwise() -> void:
	print('anticlockwise')
	rotate_piece(1,-1)
	return

func rotate_clockwise() -> void:
	print('anticlockwise')
	rotate_piece(-1,1)
	return	
	
func rotate_piece(c_x: int, c_y: int) -> void:
	var anchor_point: Vector2i = active_piece.get_used_rect().get_center()
	var piece_coords = get_piece_coords()
	var piece_colors = get_layer_colors(active_piece)
	
	var new_coords: Array[Vector2i] = []
	
	for coord in piece_coords:
		var relative_coord = coord - anchor_point
		var new_coord = Vector2i(
			c_x * relative_coord.y,
			c_y * relative_coord.x
		) + anchor_point
		
		if placed_tiles.get_cell_tile_data(new_coord) or border.get_cell_tile_data(new_coord):
			print("unable to rotate ", c_x, c_y)
			return 
	
		new_coords.append(new_coord)
		
	active_piece.clear()
	for i in range(new_coords.size()):
		draw_coords(active_piece, new_coords[i], piece_colors[i])
		
	pass
	

func get_layer_colors(layer: TileMapLayer) -> Array[Vector2i]:
	var colors: Array[Vector2i] = []
	for coord in layer.get_used_cells():
		colors.append(layer.get_cell_atlas_coords(coord))
	
	return colors
	
func get_piece_coords() -> Array[Vector2i]:
	return active_piece.get_used_cells()

func place_piece() -> void:
	var piece_cells = get_piece_coords()
	var piece_colors = get_layer_colors(active_piece)
		
	for i in range(piece_cells.size()):
		draw_coords(
			placed_tiles,
			piece_cells[i],
			piece_colors[i]
		)
	
	active_piece.clear()
		

func spawn_piece() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	for n in range(MAX_PIECE_SIZE):
		var direction = randi_range(0, 3)
		if direction == 0:
			coords.append(coords[-1] + Vector2i(0, 1))
		if direction == 1:
			coords.append(coords[-1] + Vector2i(0, -1))
		if direction == 2:
			coords.append(coords[-1] + Vector2i(1, 0))
		if direction == 3:
			coords.append(coords[-1] + Vector2i(-1, 0))
	
	for coord in coords:
		draw_coords(active_piece, coord, roll_color())
			
	print("spawned piece")
		
func can_move_in_direction(direction: Vector2i) -> bool:
	for cell in active_piece.get_used_cells():
		if placed_tiles.get_cell_tile_data(cell + direction):
			return false
		if border.get_cell_tile_data(cell + direction):
			return false
	
	return true
		
func move_piece(direction: Vector2i) -> void:
	var current_cells = active_piece.get_used_cells()
	var colors: Array[Vector2i] = []
	
	if not can_move_in_direction(direction):
		return
	
	for cell in current_cells:
		colors.append(active_piece.get_cell_atlas_coords(cell))
	
	active_piece.clear()
	for i in range(current_cells.size()):
		var old_coords = current_cells[i]
		var color = colors[i]
		draw_coords(active_piece, old_coords + direction, color)
	
			
func roll_color() -> Vector2i:
	return pick_color(randi_range(0, TILES.size()-1))
			
func pick_color(roll: int) -> Vector2i:
	return TILES[roll]
	
	
func draw_coords(layer: TileMapLayer, coords: Vector2i, color: Vector2i):
	layer.set_cell(coords, MAIN_SOURCE_ID, color)
