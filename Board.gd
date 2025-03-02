extends Node2D
const SPARKS = preload("res://sparks.tscn")
const DEFAULT_LAYER = preload("res://default_layer.tscn")
const TILEGLOW = preload("res://tileglow.tscn")
const MIN_TILES_TO_SCORE = 3
const MAX_PIECE_SIZE = 5
const HEIGHT = 12
const WIDTH = 16
const MAIN_SOURCE_ID = 0

const PLACABLE_MODULATION = Color(1, 1, 1, 0.9)
const UNPLACABLE_MODULATION = Color(1, 1, 1, 0.2)

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
	YELLOW_TILE, 
	GREEN_TILE, 
	ORANGE_TILE, 
	#BLUE_TILE, 
	#RED_TILE,
	#PURPLE_TILE
]

var border: TileMapLayer
var placed_tiles: TileMapLayer
var active_piece: TileMapLayer
var score = 0
var num_gravity_repeats = 0
var glow_coord = {}

const TILE_CLEAR_SOUNDS = [
	SoundEffect.SOUND_EFFECT_TYPE.ON_TILE_CLEAR_1,
	SoundEffect.SOUND_EFFECT_TYPE.ON_TILE_CLEAR_2,
	SoundEffect.SOUND_EFFECT_TYPE.ON_TILE_CLEAR_3,
]


func _ready():
	
	placed_tiles = DEFAULT_LAYER.instantiate()
	active_piece = DEFAULT_LAYER.instantiate()
	active_piece.modulate = Color(1, 1, 1, 0.6)
	border = DEFAULT_LAYER.instantiate()
	add_child(border)
	add_child(placed_tiles)
	add_child(active_piece)
	
	init_border()
	spawn_piece()


func _input(event) -> void:
	if event.is_action_pressed("spawn piece"):
		if is_piece_placable():
			place_piece()
			# clear_scored_pieces()
			spawn_piece()
	elif event.is_action_pressed("rotate anticlockwise"):
		rotate_anticlockwise()
	elif event.is_action_pressed("rotate clockwise"):
		rotate_clockwise()
	
func is_piece_placable() -> bool:
		for cell in get_piece_coords():
			if placed_tiles.get_cell_tile_data(cell):
				return false
		return true
	
		
func input_handler(event_or_input) -> void:
	if event_or_input.is_action_pressed("down"):
		move_piece(Vector2i(0, 1))
	if event_or_input.is_action_pressed("up"):
		move_piece(Vector2i(0, -1))
	if event_or_input.is_action_pressed("left"):
		move_piece(Vector2i(-1, 0))
	if event_or_input.is_action_pressed("right"):
		move_piece(Vector2i(1, 0))
	

var num_steps: int = 0
const MAX_STEPS: int = 8
func _process(delta) -> void:
	if (
		Input.is_action_pressed("down") 
		or Input.is_action_pressed("up") 
		or Input.is_action_pressed("left") 
		or Input.is_action_pressed("right")
	):
		num_steps += 1
		if num_steps >= MAX_STEPS:
			input_handler(Input)
			num_steps = 0
	
func color_of_tile(tile: Vector2i) -> Color:
	if tile == BLUE_TILE:
		return Color("24D")
	elif tile == GREEN_TILE:
		return Color("#0F0")
	elif tile == RED_TILE:
		return Color("#F00")
	elif tile == ORANGE_TILE:
		return Color("#FF7F00")
	elif tile == LIGHT_BLUE_TILE:
		return Color("#5AF")
	elif tile == YELLOW_TILE:
		return Color("#FF0")
	elif tile == PURPLE_TILE:
		return Color("#9A00CD")
	return Color(1, 1, 1)

func init_border() -> void:
	print("init_border")
	var half_height = int(HEIGHT / 2.0)
	var half_width = int(WIDTH / 2.0)
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
			
	draw_coords(border, Vector2i(half_width, half_height), GREY_TILE)
	draw_coords(border, Vector2i(half_width, -half_height), GREY_TILE)
	draw_coords(border, Vector2i(-half_width, half_height), GREY_TILE)
	draw_coords(border, Vector2i(-half_width, -half_height), GREY_TILE)
			
	pass
	
func scorable_pieces_for_tile(tile: Vector2i) -> Array[Vector2i]:
	var tiles_for_color = placed_tiles.get_used_cells_by_id(MAIN_SOURCE_ID, tile)
		
	if tiles_for_color.size() < MIN_TILES_TO_SCORE:
		return [] 
		
	var checked_tiles: Array[Vector2i] = []
	var scorable_pieces: Array[Vector2i] = []
	
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
			scorable_pieces.append_array(neighbors)
			
	return scorable_pieces
	
	
func stop_all_glows() -> void:
	for coord in glow_coord.keys():
		glow_coord[coord].stop_glow()
		glow_coord.erase(coord)
		
func clear_scored_pieces() -> bool:
	print("clear_scored_pieces")
	set_piece_alpha()
	var scored_tiles: Array[Vector2i] = []
	stop_all_glows()
	for color_to_check in TILES:
		print("checking for scored color, ", color_to_check)
		var scorable_pieces = scorable_pieces_for_tile(color_to_check)
		
		if scorable_pieces.size() == 0:
			continue
			
		var color = color_of_tile(color_to_check)
				
		for i in range(scorable_pieces.size()):
			var scored_tile = scorable_pieces[i]
			if scored_tile in scored_tiles:
				continue
				
			await get_tree().create_timer(0.15).timeout
			var to_check = scorable_pieces.duplicate()
			var neighbors = get_tile_flood_fill(scored_tile, to_check)
			var global_coord: Vector2 = Vector2.ZERO
			for j in range(neighbors.size()):
				await get_tree().create_timer(0.05).timeout
				var neighbor = neighbors[j]
				scored_tiles.append(neighbor)
				await get_tree().create_timer(0.03).timeout
				var sparks = SPARKS.instantiate()
				add_child(sparks)
				global_coord = placed_tiles.to_global(placed_tiles.map_to_local(neighbor))
				var sound_effect = TILE_CLEAR_SOUNDS[randi_range(0, TILE_CLEAR_SOUNDS.size()-1)]
				AudioManager.sound_effect_dict[sound_effect].pitch_scale = 0.8 + (j / 8.0)
				AudioManager.create_2d_audio_at_location(
					global_coord, 
					sound_effect)
				sparks.fire(global_coord, color)
				placed_tiles.erase_cell(neighbor)
			
			ScoreNumbers.display_number(
				neighbors.size(), 
				global_coord + Vector2(0, -80), 
				color,
			) 
		
			score += scorable_pieces.size()
			%Score.text = str(score)
							
	print("Total scored: ", scored_tiles.size())
	
	return scored_tiles.size() > 0


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
		
		if border.get_cell_tile_data(new_coord):
			print("unable to rotate ", c_x, c_y)
			return 
	
		new_coords.append(new_coord)
		
	active_piece.clear()
	for i in range(new_coords.size()):
		draw_coords(active_piece, new_coords[i], piece_colors[i])
		
	var shift_amount = anchor_point - active_piece.get_used_rect().get_center()
	if shift_amount != Vector2i.ZERO:
		active_piece.clear()
		for i in range(new_coords.size()):
			new_coords[i] = new_coords[i] + shift_amount
			if border.get_cell_tile_data(new_coords[i]):
				for j in range(piece_coords.size()):
					draw_coords(active_piece, piece_coords[i], piece_colors[i])
					
				return
		for i in range(new_coords.size()):
			draw_coords(active_piece, new_coords[i], piece_colors[i])
			
	set_piece_alpha()	
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
	AudioManager.create_2d_audio_at_location(
		Vector2(0,0),
		SoundEffect.SOUND_EFFECT_TYPE.ON_PLACE)
	
	for i in range(piece_cells.size()):
		draw_coords(
			placed_tiles,
			piece_cells[i],
			piece_colors[i]
		)
	
	active_piece.clear()
	glow_scorable_tiles()
		
		
func glow_scorable_tiles() -> void:
	var scorable_coords: Array[Vector2i]
	stop_all_glows()
	for tile in TILES:
		scorable_coords = scorable_pieces_for_tile(tile)
		var newly_glowing_coords
		for coord in scorable_coords:
			var global_coord = placed_tiles.to_global(placed_tiles.map_to_local(coord))
			var glow = TILEGLOW.instantiate()
			glow.glow(global_coord, color_of_tile(tile))
			glow_coord[coord] = glow
			add_child(glow)
	return

func spawn_piece() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	for n in range(randi_range(1, MAX_PIECE_SIZE)):
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
			
	set_piece_alpha()
	print("spawned piece")
	
func set_piece_alpha():
	active_piece.modulate = Color(1, 1, 1, 0.8)

	if is_piece_placable():
		placed_tiles.modulate = Color(1, 1, 1, 1)
	else:
		placed_tiles.modulate = UNPLACABLE_MODULATION
		
func can_move_in_direction(direction: Vector2i) -> bool:
	for cell in active_piece.get_used_cells():
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
		
	set_piece_alpha()
	
			
func roll_color() -> Vector2i:
	return pick_color(randi_range(0, TILES.size()-1))
			
func pick_color(roll: int) -> Vector2i:
	return TILES[roll]
	
	
func draw_coords(layer: TileMapLayer, coords: Vector2i, color: Vector2i):
	layer.set_cell(coords, MAIN_SOURCE_ID, color)


func _on_button_pressed() -> void:
	print("_on_button_pressed")
	AudioManager.create_2d_audio_at_location(
		Vector2(0,0),
		SoundEffect.SOUND_EFFECT_TYPE.GRAVITY)
	%GravityDownButton.queue_free()
	active_piece.clear()
	clear_scored_pieces()
	gravity_down()
	
	
	
func gravity_down() -> void:
	print("gravity down")
	var placed_coords = placed_tiles.get_used_cells()
	var per_x_coords: Dictionary = {}
	for coord in placed_coords:
		var x = coord.x
		if x not in per_x_coords.keys():
			per_x_coords[x] = [coord]
		else:
			per_x_coords[x].append(coord)
	
	var ordered_cols = per_x_coords.keys()
	ordered_cols.sort()
	for x in ordered_cols:
		var col_coords = per_x_coords[x]
		col_coords.sort_custom(sort_vectors_lowest_to_highest)
		
		var min_y = 100
		for coord in col_coords:
			if (min_y == null) or coord.y < min_y:
				min_y = coord.y
			
		if (int(HEIGHT / 2.0) - col_coords.size()) == min_y:
			continue
		
		for i in range(col_coords.size()):
			var old_coord = col_coords[i]
			
			var color = placed_tiles.get_cell_atlas_coords(old_coord)
			var new_coord = Vector2i(x, int(HEIGHT/2.0)-i-1)
			await get_tree().create_timer(0.001).timeout
			for j in range(old_coord.y, new_coord.y ):
				placed_tiles.erase_cell(Vector2i(x, j))
				draw_coords(placed_tiles, Vector2i(x, j+1), color)
				
	if await clear_scored_pieces():
		print("scored pieces after applying gravity! repeating")
		await get_tree().create_timer(0.2).timeout
		num_gravity_repeats += 1
		var msg: = "Again"
		if num_gravity_repeats > 1:
			for n in range(num_gravity_repeats):
				msg += "!"
			msg += " x" + str(num_gravity_repeats)
		var sound_effect= SoundEffect.SOUND_EFFECT_TYPE.ON_AGAIN
		AudioManager.sound_effect_dict[sound_effect].pitch_scale = 0.8 + (num_gravity_repeats / 10.0)
		AudioManager.create_2d_audio_at_location(
			Vector2(0,0),
			sound_effect)
		ScoreNumbers.display_str(
					msg, 
					Vector2(randi_range(-400, -100), randi_range(-100, 100)),
					"#FFF",
					40 + (12 * num_gravity_repeats)
				)
		await get_tree().create_timer(0.2).timeout
		gravity_down()
	else:
		num_gravity_repeats = 0
		await get_tree().create_timer(0.8).timeout
		%GameOver.visible = true
	pass

func sort_vectors_lowest_to_highest(a: Vector2i, b: Vector2i) -> bool:
	return a.y > b.y


func _on_randomly_populate_button_pressed() -> void:
	randomly_populate_grid()
	
func randomly_populate_grid() -> void:
	print("randomly populating grid")
	var half_height = int(HEIGHT / 2.0)
	var half_width = int(WIDTH / 2.0)
	for x in range(-half_width + 1, half_width):
		for y in range(-half_height + 1, half_height):
			draw_coords(placed_tiles, Vector2i(x, y), roll_color())
			
	glow_scorable_tiles()
