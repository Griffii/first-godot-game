class_name Player extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape_player: CollisionShape2D = $CollisionShape_Player
@onready var leash_point: Node2D = $Leash_Point
@onready var leash_raycast: RayCast2D = $Leash_Point/Leash_Raycast
@onready var leash_line: Line2D = $Leash_Point/Leash_Line
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $CharacterStateMachine
@onready var grab_box: Area2D = $Grab_Box


# Dash Control Variables  ## NOT USED ##
@export var dash_speed: float = 800.0             # Speed of the dash
@export var dash_duration: float = 0.15           # How long the dash lasts (in seconds)
@export var dash_cooldown: float = 2.0            # Cooldown between dashes
@export var dash_count: int = 1                   # Number of dashes allowed before needing to touch the ground
@export var dash_recharge_on_ground: bool = true  # Recharges dash when touching ground

# Wall Slide/Jump Variables  ## NOT USED ##
@export var wall_jump_force: Vector2 = Vector2(-300, -400)  # Velocity applied when wall jumping
@export var wall_slide_speed: float = 50.0        # Speed when sliding down a wall
@export var climb_speed: float = 100.0            # Speed of climbing up/down walls
@export var max_climb_time: float = 1.5           # Time the player can stay on the wall before tiring
@export var wall_jump_gravity: float = 600.0      # Gravity applied while wall jumping

# Movement and physics variables
@export var acceleration: float = 800.0
@export var deceleration: float = 600.0
@export var air_control: float = 0.5              # Reduce movement control in the air

# Variable Player Speeds
@export var normal_speed: float = 120.0
@export var drag_speed: float = 50.0
@export var slow_speed: float = 7.0

@export var push_force: float = 150.0             # Pushing force when walking into objects
@export var jump_force: float = -350.0            # Jump height
@export var gravity: float = 980.0                # Gravity force
@export var max_fall_speed: float = 600.0         # Max fall speed

@export var jump_buffer_duration: float = 0.15    # Time window for jump buffer
@export var jump_cutoff_multiplier: float = 0.5   # Multiplier to reduce jump height if key is released early
@export var coyote_time_duration: float = 0.1     # Time window for coyote jump

###################################################################################################

# Internal variables
var is_dead = false                      # Is alive?

var speed : float = normal_speed         # Current player speed
var direction: float = 0.0               # Current input_direction as a float
var facing_direction: float = 1.0        # Last direction faced (Left or Right | Only updates when directoin is )
var plat_vel = Vector2.ZERO              # Store x velocity of moving platforms

var is_on_ground: bool = false
var is_dashing: bool = false
var is_grabbing: bool = false

var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

var coyote_time: float = 0.0
var jump_buffer: float = 0.0

var is_chatting: bool = false           # Check if player in in dialogue with an npc
###################################################################################################

func _ready():
	pass

func _process(_delta):
	pass


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Call functions for movement, jumping, timers, pushing
	move_player(delta)      # Moves the player depending on input
	gravity_and_jump(delta) # Apply gravity, manage jump input
	update_timers(delta)    # Timers for coyote time / jump buffer
	#push_colliders()        # Apply force to collision objects (Push things)
	
	
	# Update the ground status
	move_and_slide()
	is_on_ground = is_on_floor()

func move_player(delta):
	# Get left or right input
	var input_direction: float = 0.0
	if Input.is_action_pressed("move_right"):
		input_direction += 1
	if Input.is_action_pressed("move_left"):
		input_direction -= 1
	
	# Set character facing direction after every input incase it's needed
	if input_direction != 0 && facing_direction != input_direction:
		facing_direction = input_direction
	
	# Set Velocity and toggle acc/dec based on dashing state
	if is_dashing:
		#print("Dashing! ", facing_direction , " " , speed)
		direction = facing_direction
		velocity.x = facing_direction * speed
	else:
		# Apply player input control
		if input_direction != 0 && state_machine.check_if_can_move():
			# Move character in input direction with acceleration
			direction = input_direction
			velocity.x = move_toward(velocity.x, input_direction * speed, acceleration * delta)
			
			# Apply air control if character is in the air
			if not is_on_ground:
				velocity.x = lerp(velocity.x, input_direction * speed, air_control * delta)
		else:
			# Apply deceleration when no input is pressed
			velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	
	# Flip horizontally when moving left or right
	# Don't flip if grabbing
	if !is_grabbing:
		if facing_direction == -1:
			sprite.flip_h = false
		elif facing_direction == 1:
			sprite.flip_h = true
	
	# Flip child nodes that need to be at the front of the character
	adjust_child_positions()

func gravity_and_jump(delta):
	# Apply gravity and limit fall speed
	if not is_on_ground:
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
	
	# Coyote time: Allows jumping shortly after leaving the ground
	if is_on_ground:
		coyote_time = coyote_time_duration
	
	# Jump buffer: Allows jump input to be buffered
	if Input.is_action_just_pressed("jump"):
		jump_buffer = jump_buffer_duration
	
	# Jumping logic
	if coyote_time > 0 and jump_buffer > 0:
		if is_on_ground and plat_vel.x != 0:   # Only works if the x velocity is greate than 1 pixel in either direction
			# Add platform velocity to jump and lower deceleration to keep momentum
			velocity.x += plat_vel.x
			deceleration *= 0.175
			acceleration *= 0.75
		velocity.y = jump_force
		coyote_time = 0.0
		jump_buffer = 0.0
	
	# Jump cutoff logic (reduce jump height if jump button is released early)
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cutoff_multiplier
	
	# Get platform velocity incase standing on moving platform
	var current_plat_vel = get_platform_velocity()
	if current_plat_vel != Vector2.ZERO:
		plat_vel = current_plat_vel

func update_timers(delta: float) -> void:
	# Update temporary timers every delta
	if coyote_time > 0:
		coyote_time -= delta
	if jump_buffer > 0:
		jump_buffer -= delta
	# Track dash
	if  dash_timer > 0:
		dash_timer -= delta
	if  dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

func adjust_child_positions():
	if facing_direction == 1:
		# Move RayCast and Area2D to the right side
		#leash_raycast.target_position = abs(leash_raycast.target_position)
		#leash_point.position.x = abs(leash_point.position.x)
		grab_box.position.x = abs(grab_box.position.x)
	elif facing_direction == -1:
		# Move RayCast and Area2D to the left side (flip position)
		#leash_raycast.target_position = -abs(leash_raycast.target_position)
		#leash_point.position.x = -abs(leash_point.position.x)
		grab_box.position.x = -abs(grab_box.position.x)

func push_colliders():
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * push_force)

func halt_movement():
	# Instantly halt movement by resetting velocity to zero
	velocity = Vector2.ZERO
	move_and_slide()  # Optional, to make sure it processes the stop immediately

func fall_into_void(spawn_location_node : Node2D):
	print("You Died.")
	var spawn_location = spawn_location_node.position
	visible = false   # Leave visible if palying an animation
	is_dead = true
	
	await get_tree().create_timer(1).timeout
	reset_player_to(spawn_location)

func reset_player_to(pos: Vector2):
	global_position = pos
	visible = true
	is_dead = false

func disable():
	is_dead = true
	visible = false

func enable():
	is_dead = false
	visible = true

## Not Used Limbo State Machine ##
###### State Machine and Inputs #####
#func initiate_state_machine():
	#main_sm = LimboHSM.new()
	#add_child(main_sm)
	#
	#var idle_state = LimboState.new().named("idle").call_on_enter(idle_start).call_on_update(idle_update)
	#var walk_state = LimboState.new().named("walk").call_on_enter(walk_start).call_on_update(walk_update)
	#var jump_state = LimboState.new().named("jump").call_on_enter(jump_start).call_on_update(jump_update)
	#var attack_state = LimboState.new().named("attack").call_on_enter(attack_start).call_on_update(attack_update)
	#
	#main_sm.add_child(idle_state)
	#main_sm.add_child(walk_state)
	#main_sm.add_child(jump_state)
	#main_sm.add_child(attack_state)
	#
	#main_sm.initial_state = idle_state
	#
	## Transitions between states - Must be specific in what state can transition to what other state
	#main_sm.add_transition(idle_state, walk_state, &"to_walk")
	#main_sm.add_transition(main_sm.ANYSTATE, idle_state, &"state_ended")
	#main_sm.add_transition(idle_state, jump_state, &"to_jump")
	#main_sm.add_transition(walk_state, jump_state, &"to_jump")
	#main_sm.add_transition(main_sm.ANYSTATE, attack_state, &"to_attack")
	#
	#main_sm.initialize(self)
	#main_sm.set_active(true)
#
#func _unhandled_input(event):
	#if event.is_action_pressed("interact"):
		#main_sm.dispatch(&"to_attack")
#
### State machine functions - Start + Update
#func idle_start():
	#animation_player.play("idle")
#func idle_update(_delta):
	#if velocity.x != 0:
		#main_sm.dispatch(&"to_walk")
	#if velocity.y != 0:
		#main_sm.dispatch(&"to_jump")
#
#func walk_start():
	#animation_player.play("walk")
#func walk_update(_delta):
	#if velocity.y != 0:
		#main_sm.dispatch(&"to_jump")
	#if velocity.x == 0:
		#main_sm.dispatch(&"state_ended")
#
#func jump_start():
	#animation_player.play("jump")
#func jump_update(_delta):
	#if velocity.y < 0:
		#animation_player.play("jump_going_up")
	#elif velocity.y > 0:
		#animation_player.play("falling")
	#elif velocity.y == 0 && is_on_floor():
		#animation_player.play("landing")
		### I call the end of state dispatch using the on_animation_finished signal function
#
#func attack_start():
	#animation_player.play("interact")
	#leash.leash_throw()
#func attack_update(_delta):
	## Check if we are on the last frame of the animation called in attack_start, if so revert to idle
	#if hoodie_girl.frame == hoodie_girl.sprite_frames.get_frame_count("interact") - 1:
		#main_sm.dispatch(&"state_ended")
