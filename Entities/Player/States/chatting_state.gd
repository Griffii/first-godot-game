class_name ChattingState extends State


# State and Animation Names
@export var ground_state : State
@export var air_state : State
@export var idle_animation : String = "idle"
@export var walk_animation : String = "walk"


func Enter():
	animation_player.play(idle_animation)
	Dialogic.signal_event.connect(_on_dialogic_signal)

func Exit():
	pass

func _on_dialogic_signal(arguement: String):
	print("Dialogic signal recieved: ", arguement)
	if arguement == "chatting_end":
		next_state = ground_state

func Update(_delta):
	pass

func Physics_Update(delta):
	pass
