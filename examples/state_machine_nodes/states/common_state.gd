extends StateNode


const SPEED = 300.0


var player: CharacterBody2D
var sprite: AnimatedSprite2D


func init() -> void:
	player = owner
	sprite = player.get_node(^"Sprite")
