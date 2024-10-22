class_name Teacher extends CharacterBody2D

var player_in_area = false
var is_chatting = false


func _ready() -> void:
	pass
	#Dialogic.signal_event.connect(arg or func) # If you need to recieve signals from the dialogue timeine

func _process(delta: float) -> void:
	if player_in_area == true and !is_chatting:
		if Input.is_action_pressed("dialogic_default_action"):
			run_dialogue("teacher_1-1_quest01")



func _on_chat_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true

func _on_chat_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false


func run_dialogue(dialogue:String):
	is_chatting = true
	var layout = Dialogic.start(dialogue)
	layout.register_character(load("res://Entities/Teachers/Teacher_1-1/teacher_1-1.dch"), $chat_bubble_marker)
