extends Node
#class_name StateMachine
#
#@export var initial_state : State
#var current_state : State
#var states : Dictionary = {}
#
#func _ready():
	#for child in get_children():
		#if child is State:
			#states[child.name.to_lower()] = child
			#child.state_transition.connect(change_state)
			#
	#if initial_state:
		#initial_state.Enter()
		#current_state = initial_state
#
## Call the current state and update function continously
#func _process(delta: float) -> void:
	#if current_state:
		#current_state.Update(delta)
#
#
#func _physics_process(delta: float) -> void:
	#if current_state:
		#current_state.Physics_Update(delta)
#
#
#func change_state(state, new_state_name):
	#if state != current_state:
		#return
	#
	#var new_state = states.get(new_state_name.to_lower())
	#if !new_state:
		#return
	#
	#if current_state:
		#current_state.Exit()
	#
	#new_state.Enter()
	#
	#current_state = new_state
