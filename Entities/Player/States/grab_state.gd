extends State

class_name GrabState

# State and Animation Names
@export var air_state : State
@export var crouch_state : State
@export var ground_state : State
@export var idle_animation : String = "idle"
@export var walk_animation : String = "walk"

# Object Storage
var grabbed_object = null
var grabbed_object_array = null

func Enter():
	grab_object()

func Exit():
	# Call release function for object
	if grabbed_object:
		grabbed_object.release()
	# Reset character speed
	character.speed = character.normal_speed
	# Reset variables
	character.is_grabbing = false
	grabbed_object = null
	grabbed_object_array = null

func Update(_delta):
	# Always lsiten for these inputs
	if Input.is_action_pressed("crouch"):
		next_state = crouch_state

func Physics_Update(delta):
	if character.is_grabbing:
		if character.is_on_ground:
			# Check for movement and call animations
			if character.velocity.x == 0:
				animation_player.play(idle_animation)
			else:
				animation_player.play(walk_animation)
		# If falling, change states
		else:
			next_state = air_state
	# If not grabbing change state
	else:
		if character.is_on_ground:
			next_state = ground_state
		else:
			next_state = air_state

# Handle input
func state_input(event : InputEvent):
	if event.is_action_pressed("interact"):
		if character.is_grabbing:
			character.is_grabbing = false
			if grabbed_object:
				grabbed_object.release()
				grabbed_object = null
		else:
			grab_object()

func grab_object():
	# If area2D is colliding with interactable object call the objects grab() function
	if character.grab_box.get_overlapping_bodies() != null:
		grabbed_object_array = character.grab_box.get_overlapping_bodies() # This returns an array of overlapping bodies
		if grabbed_object_array.size() > 0:
			grabbed_object = grabbed_object_array[0] # Select only the first obect in the array
			#print("Tried to grab ", grabbed_object)
			if grabbed_object.is_in_group("attachable"):
				#print(grabbed_object, " is grabbable!")
				character.is_grabbing = true
				# Call grab fucntion for object
				grabbed_object.grab(character)
				# Slow down the character
				character.speed = character.drag_speed
