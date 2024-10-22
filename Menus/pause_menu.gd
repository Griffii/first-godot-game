class_name PauseMenu extends Control

@export var root_node : Node

var is_paused: bool = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		is_paused = !is_paused
		visible = is_paused
		if Engine.time_scale == 1:
			Engine.time_scale = 0
		else:
			Engine.time_scale = 1


func _on_play_pressed() -> void:
	is_paused = false
	visible = is_paused
	Engine.time_scale = 1

func _on_quit_pressed() -> void:
	Engine.time_scale = 1
	is_paused = false
	SceneManager.swap_scenes("res://Menus/main_menu.tscn", null, root_node, "fade_to_black")
