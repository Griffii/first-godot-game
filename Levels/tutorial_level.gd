class_name Level extends Node

@export var player : Player
@export var player_spawn_node: Node2D


var area = "Tutorial"
var paused = false

func _ready() -> void:
	player.disable()
	player.visible = false
	
	enter_level()

func _process(delta: float) -> void:
		pass

func enter_level():
	init_player_location()
	player.enable()

func init_player_location():
	player.reset_player_to(player_spawn_node.position)
	player.visible = true

func _on_kill_plane_body_entered(body: Node2D) -> void:
	if body == player:
		player.fall_into_void(player_spawn_node)
	if body.is_in_group("student"):
		body.queue_free()  # Despawn npcs if they fall into the void
