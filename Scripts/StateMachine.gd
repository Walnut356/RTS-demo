"""
State machine base class
"""

extends Node
class_name StateMachine

#variables
var state = null
var oldState = null
var states = {}

onready var parent = get_parent()

#stuff for other state machines to inherit
func _physics_process(delta):
	if state!= null:
		_state_logic(delta)
		var transition = _get_transition(delta)
		if transition != null:
			set_state(transition)
			
func _state_logic(delta):
	pass
	
func _get_transition(delta):
	pass
	
func set_state(newState):
	oldState = state
	state = newState
	
	if oldState != null:
		_exit_state(oldState, newState)
	if newState != null:
		_enter_state(newState, oldState)
		
func _exit_state(oldState, newState):
	pass
	
func _enter_state(newState, oldState):
	pass
	
func add_state(state_name):
	states[state_name] = states.size()
	


