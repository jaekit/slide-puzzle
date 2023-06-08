extends Control


enum Colour {
	RED, ORANGE, BLUE, GREEN,
}


const TILE_WIDTH := 20
const MARGIN := 1
const SIZE := 5
#onready var OFFSET := Vector2((108 - SIZE * TILE_WIDTH) / 2 - 2, 85)
onready var OFFSET := Vector2(2, get_viewport().size.y - 16 * TILE_WIDTH - 2)


var tiles: Array # All SIZExSIZE tiles
var goal: Array # Goal tiles on the screen

var touch_enabled := false # If false, touch does nothing
var empty_tile_location: Vector2

# Time variables
var second_timer: Timer
var time_left := 60
var count_down := 3

var score := 0
var multiplier := 1

var _goal_helper: Array


func _ready() -> void:
	randomize()
	
	# init timer
	second_timer = Timer.new()
	second_timer.connect("timeout", self, "_on_second_timer_timeout")
	add_child(second_timer)
	second_timer.start()
	
	# initialize tiles
	_goal_helper = []
	for i in range(SIZE):
		var row = []
		for j in range(SIZE):
			var tile := Tile.new((SIZE * i + j) % Colour.size())
			row.append(tile)
			_goal_helper.append(tile.color)
		tiles.append(row)
	tiles[0][0] = null # free up one space
	empty_tile_location = Vector2(0, 0)
	
	# Add child
	for i in range(SIZE):
		for j in range(SIZE):
			if tiles[i][j] == null:
				continue
			tiles[i][j].position = OFFSET + Vector2((TILE_WIDTH + MARGIN) * j, (TILE_WIDTH + MARGIN) * i)
			add_child(tiles[i][j])
	
	generate_new_goal(Vector2(randi() % 3 + 2, randi() % 3 + 2))


func _input(event: InputEvent) -> void:
	if touch_enabled and (event is InputEventScreenTouch and event.is_pressed() or event is InputEventScreenDrag):
		move_tile(world_to_grid(event.position))


func world_to_grid(pos: Vector2) -> Vector2:
	if pos.x < OFFSET.x or pos.y < OFFSET.y:
		return Vector2(-1, -1)
	return Vector2(int(pos.x - OFFSET.x) / (TILE_WIDTH + MARGIN), int(pos.y - OFFSET.y) / (TILE_WIDTH + MARGIN))


func move_tile(cell: Vector2) -> void:
	if cell == empty_tile_location or cell.x < 0 or cell.y < 0 or cell.x >= tiles.size() or cell.y >= tiles.size():
		return
	var direction := empty_tile_location - cell
	if direction.length_squared() != 1:
		return
	
	var tile = tiles[cell.y][cell.x]
	if tile.tween.is_active():
		return
	tile.scale = Vector2(1.2 if direction.x != 0 else 1, 1.2 if direction.y != 0 else 1)
	tile.offset += Vector2(-2 if direction.x != 0 else 0, -2 if direction.y != 0 else 0)
	tile.tween.interpolate_property(tile, "position", tile.position, tile.position + direction * (TILE_WIDTH + MARGIN), 0.1, Tween.TRANS_CUBIC)
	tile.tween.start()
	tile.tween.connect("tween_completed", self, "on_tile_move_completed", [tile])
	tiles[cell.y + direction.y][cell.x + direction.x] = tile
	tiles[cell.y][cell.x] = null
	empty_tile_location = cell


func on_tile_move_completed(_object: Object, _key: NodePath, tile: Tile) -> void:
	var goal_position := check_goal_completed()
	if goal_position != Vector2(-1, -1):
		generate_new_goal(Vector2(randi() % 3 + 2, randi() % 3 + 2))
	tile.tween.disconnect("tween_completed", self, "on_tile_move_completed")
	tile.scale = Vector2(1, 1)
	tile.offset = Vector2(10, 10)


func generate_new_goal(size: Vector2) -> void:
	for row in goal:
		for tile in row:
			tile.hide()
			tile.queue_free()
	
	_goal_helper.shuffle()
	
	goal = []
	for r in range(size.x):
		var row := []
		for c in range(size.y):
			row.append(Tile.new(_goal_helper[r * size.y + c]))
			row[c].position = 0.75 * (TILE_WIDTH + MARGIN) * Vector2(c, r) + Vector2((108 - (TILE_WIDTH + MARGIN) * size.y) / 2, 0)
			
			add_child(row[c])
		goal.append(row)


func check_goal_completed() -> Vector2:
	for i in range(0, SIZE - goal.size() + 1):
		for j in range(0, SIZE - goal[0].size() + 1):
			var cont := false
			for r in range(i, i + goal.size()):
				for c in range(j, j + goal[0].size()):
					if goal[r - i][c - j].color != -1 and tiles[r][c] == null:
						cont = true
						break
					if goal[r - i][c - j].color != -1 and tiles[r][c] != null and goal[r - i][c - j].color != tiles[r][c].color:
						cont = true
						break
				if cont:
					break
			if cont:
				continue
			return Vector2(i, j)
	return Vector2(-1, -1)


func game_over() -> void:
	pass


func _on_second_timer_timeout() -> void:
	if count_down > 0:
		count_down -= 1
		$TimerLabel.text = String(count_down)
		if count_down == 0:
			touch_enabled = true
	else:
		time_left -= 1
		$TimerLabel.text = String(time_left)
		if time_left == 0:
			game_over()
			second_timer.stop()
