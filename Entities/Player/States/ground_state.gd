class_name GroundState extends State


# State and Animation Names
@export var air_state : State
@export var crouch_state : State
@export var leash_state : State
@export var grab_state : State
@export var chatting_state : State
@export var dash_state : State
@export var jump_animation : String = "jump_start"
@export var idle_animation : String = "idle"
@export var walk_animation : String = "walk"


func Enter():
	Dialogic.signal_event.connect(_on_dialogic_signal)

func Exit():
	pass


func state_input(event : InputEvent):
	# Only check when an input event occcurs
	if event.is_action_pressed("jump"):
		next_state = air_state
		animation_player.play(jump_animation)
	
	if event.is_action_pressed("left_click"):
		next_state = leash_state
	
	if event.is_action_pressed("dash"):
		if character.dash_cooldown_timer <= 0.0:
			next_state = dash_state
	
	if event.is_action_pressed("interact"):
		next_state = grab_state


func Update(_delta):
	# Always lsiten for these inputs
	if Input.is_action_pressed("crouch"):
		next_state = crouch_state

func Physics_Update(delta):
	if character.is_on_ground:
		# Check for movement and call animations
		if character.velocity.x == 0:
			animation_player.play(idle_animation)
		else:
			animation_player.play(walk_animation)
	# If falling, change states
	else:
		next_state = air_state

func _on_dialogic_signal(arguement: String):
	print("Dialogic signal recieved: ", arguement)
	if arguement == "chatting_start":
		next_state = chatting_state
