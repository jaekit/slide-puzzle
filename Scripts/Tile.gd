class_name Tile extends Sprite


const TILE_WIDTH = 20

var color: int
var tween: Tween


var _textures = [
	preload("res://Assets/Red1.png"),
	preload("res://Assets/Orange1.png"),
	preload("res://Assets/Blue1.png"),
	preload("res://Assets/Green1.png"),
]


func _init(color: int) -> void:
	self.color = color
	if color != -1:
		texture = _textures[color]
	offset = Vector2(1, 1) * TILE_WIDTH / 2


func _ready() -> void:
	tween = Tween.new()
	add_child(tween)
