extends State

@onready var hoodie_girl: Sprite2D = $"../../Sprite2D"

@onready var leash_point: Node2D = $"../../Leash_Point"
@onready var leash_raycast: RayCast2D = $"../../Leash_Point/Leash_Raycast"
@onready var leash_line: Line2D = $"../../Leash_Point/Leash_Line"


# Leash Variables
@export var weak: float = 1000.0
@export var normal: float = 1250.0
@export var strong: float = 1600.0
@export var leash_range: float = 100.0
@export var pull_strength: float = normal
@export var drag_strength: float = 100.0
@export var is_leashed = false
@export var leashed_object = null
@export var leashed_object_position = Vector2.ZERO

# Leash animation variables
var animating_leash = false
var retracting_leash = false
var current_leash_length = 0.0
var target_position = Vector2.ZERO
var leash_speed = 600.0  # Speed at which the leash extends (adjust to your preference)

# Animation Player Animation Names and State
@export var throw_leash_animation : String = "leash_throw"
@export var pull_leash_animation : String = "leash_pull"
@export var jump_animation : String = "jump_start"
@export var idle_animation : String = "leash_hold"
@export var walk_animation : String = "leash_walk"
@export var air_state : State
@export var ground_state : State


# State Functions
func Enter():
	# When entering state automatically throw leash
	if is_leashed:
		pull_leash()
	else:
		leash_throw()

func Update(_delta):
	# Check for input
	if Input.is_action_just_pressed("left_click"):
		if is_leashed:
			pull_leash()
		else:
			leash_throw()

func Physics_Update(_delta):
	# Dynamically update leash line if attached
	update_leash(_delta)
	
	if character.is_on_ground and not animating_leash and not retracting_leash:
		# If not leashed, return to ground state
		if not is_leashed:
			next_state = ground_state
		
		# Check for movement and call animations
		if character.velocity.x == 0:
			animation_player.play(idle_animation)
		else:
			animation_player.play(walk_animation)
	
	# If not on ground or animating go to air state
	elif not character.is_on_ground and not animating_leash and not retracting_leash:
		if not is_leashed:
			next_state = air_state



# Leash Functions
func leash_throw():
	if is_leashed or animating_leash or retracting_leash:
		return # Return if already grabbed onto something
	
	var mouse_position = character.get_global_mouse_position()
	var direction = (mouse_position - leash_point.global_position).normalized()
	
	leash_raycast.target_position = direction * leash_range
	leash_raycast.force_raycast_update()
	
	# Initialize leash animation variables
	animating_leash = true
	retracting_leash = false
	current_leash_length = 0.0
	target_position = leash_raycast.target_position
	
	# Make the leash line visible and start animating
	leash_line.visible = true
	leash_line.points = [leash_point.global_position, leash_point.global_position] #Initially both points are at origin
	
	# Call animation ## Not working??
	animation_player.play(throw_leash_animation)

func attach_to_object(target):
	#print(target, " attaching!")
	leashed_object = target
	is_leashed = true
	leashed_object_position = leash_raycast.get_collision_point()
	leash_line.visible = true
	
	# Convert global positions to local positions relative to the leash_line node
	var player_local_position = Vector2(5,-31)
	var target_local_position = leash_line.to_local(leashed_object.global_position)
	##print("Line: ", player_local_position, " to ", target_local_position)
	
	# Set the points for the line
	leash_line.points = [player_local_position, target_local_position]

func pull_leash():
	animation_player.play(pull_leash_animation)
	if is_leashed and leashed_object:
		var direction_to_player = (leash_line.global_position - leashed_object.global_position).normalized()
		
		var pull_force = direction_to_player * pull_strength
		leashed_object.apply_impulse(pull_force)
		
		stop_grappling()

func stop_grappling():
	is_leashed = false
	leashed_object = null
	leash_line.visible = false
	# Reset speed incase grapple stopped with leassh at full length
	character.speed = (character.normal_speed)
	# Set state back to ground or air
	if character.is_on_floor():
		next_state = ground_state
	else:
		next_state = air_state

func attack(enemy):
	print("Enemy whipped!")

func update_leash(delta):
	# Extend Leash
	if animating_leash:
		# Increment leash length towards target
		current_leash_length = min(current_leash_length + leash_speed * delta, leash_range)
		
		var player_local_position = leash_line.to_local(leash_line.global_position)
		var extended_position = player_local_position + (target_position.normalized() * current_leash_length)
		
		# Update the leash lines second point
		leash_line.points = [player_local_position, extended_position]
		
		# If leash is fully extended, stop animation and check for collision
		if current_leash_length >= leash_range:
			animating_leash = false
			# Check for collision
			if leash_raycast.is_colliding():
				var hit_object = leash_raycast.get_collider()
				#print("Leash collided with ", hit_object)
				
				if hit_object.is_in_group("attachable"):
					attach_to_object(hit_object)
				elif hit_object.is_in_group("enemy"):
					attack(hit_object)
					retracting_leash = true
				else:
					retracting_leash = true
			else:
				#print("No collider found at ", leash_raycast.target_position)
				retracting_leash = true
	
	
	elif retracting_leash:
		# Decrease the leash length towards the player
		current_leash_length = max(current_leash_length - leash_speed * delta, 0.0)
		
		# Calculate the point where the leash is retracting
		var player_local_position = leash_line.to_local(leash_line.global_position)
		var retract_position = player_local_position + (target_position.normalized() * current_leash_length)
		
		# Update the leash line's second point to retract back toward the player
		leash_line.points = [player_local_position, retract_position]
		
		# If the leash has fully retracted (length is 0), stop the animation
		if current_leash_length <= 0.0:
			retracting_leash = false
			leash_line.visible = false
	
	
	# If not extending or retracting, check if connected and update leash line to connection as needed
	elif leashed_object and leash_line.visible == true:
		 # Dynamically update the leash line points
		var player_local_position = leash_line.to_local(leash_line.global_position)
		var target_local_position = leash_line.to_local(leashed_object.global_position)
		leash_line.points = [player_local_position, target_local_position]
		
		# Check length of leash, if it's longer than the max length, pull the object
		current_leash_length = (target_local_position - player_local_position).length()
		##print ("Leash length: ", current_leash_length)
		if current_leash_length > (leash_range * 1.5):
			character.speed = (character.slow_speed)
			pull_strength = strong
		elif current_leash_length > leash_range:
			leash_drag()
		elif current_leash_length < leash_range:
			# Reset player speed if drag is not called
			character.speed = (character.normal_speed)
			pull_strength = weak

func leash_drag():
	# Slow down player
	character.speed = (character.drag_speed)
	pull_strength = normal
	
	var direction_to_player = (leash_line.global_position - leashed_object.global_position).normalized()
	
	var pull_force = direction_to_player * drag_strength
	leashed_object.apply_impulse(pull_force)
