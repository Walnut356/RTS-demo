"""
Unit state machine
Handles input for unit commands
Handles logic for states and state transitions
"""

extends StateMachine

#Commands for detection later
enum Commands {
	NONE,
	MOVE,
	ATTACK_MOVE,
	HOLD,
	PATROL
}
#modifiers for input
enum CommandMods {
	NONE,
	ATTACK_MOVE,
	PATROL
}

var command_mod = CommandMods.NONE
var command = Commands.NONE


func _ready():
	#initialize states
	add_state("idle")
	add_state("move")
	add_state("aggro")
	add_state("attack")
	add_state("die")
	
	#if it's not call deferred it doesn't work AFAIK
	call_deferred("set_state", states.idle)

#input handling
func _input(event):
	if parent.selected and state != states.die:
		if Input.is_action_just_pressed("attack_move"):
			command_mod = CommandMods.ATTACK_MOVE
		if Input.is_action_just_pressed("hold"):
			command = Commands.HOLD
			set_state(states.idle)
		if Input.is_action_just_released("mouseR"):
			parent.moveTarget = event.position
			set_state(states.move)
		if (Input.is_action_just_pressed("mouseL") and command_mod == CommandMods.ATTACK_MOVE):
				parent.moveTarget = event.position
				set_state(states.move)
				command = Commands.ATTACK_MOVE
				command_mod = CommandMods.NONE
			
func _state_logic(delta):
	match state:
		states.idle:
			pass
		states.move:
			parent.move_to_target(delta, parent.moveTarget)
		states.aggro:
			if parent.attackTarget.get_ref():
				parent.move_to_target(delta, parent.attackTarget.get_ref().position)
			else:
				set_state(states.idle)
		states.attack:
			pass
		states.die:
			pass

#to be used for animations
func _enter_state(oldState, newState):
	pass


func _exit_state(old_state, new_state):
	match old_state:
		states.attack:
			if new_state == states.idle:
				parent.attackTarget = null
		states.move:
			if new_state != states.move and command != Commands.ATTACK_MOVE:
				parent.moveTarget = parent.position

#Logic for when to set a state
func _get_transition(delta):
	match state:
		states.idle:
			match command:
				Commands.HOLD:
					if parent.closest_enemy_in_range() != null:
						parent.attackTarget = weakref(parent.closest_enemy_in_range())
						set_state(states.attack)
						
				#Commands.ATTACK_MOVE: #shouldn't ever actually need an attack move command when idle
					#set_state(states.move)
					
				Commands.NONE:
					if parent.closest_enemy() != null:
						parent.attackTarget = weakref(parent.closest_enemy())
						set_state(states.aggro)
		states.move:
			if (command == Commands.ATTACK_MOVE):
				if parent.closest_enemy() != null:
					parent.attackTarget = weakref(parent.closest_enemy())
					set_state(states.aggro)
					parent.moveTarget = parent.position
			if parent.position.distance_to(parent.moveTarget) < parent.targetMax:
				parent.moveTarget = parent.position
				command = Commands.NONE
				set_state(states.idle)
				
		states.aggro:
			if parent.closest_enemy_in_range() != null:
				parent.attackTarget = weakref(parent.closest_enemy())
				set_state(states.attack)
				
		states.attack:
			if !parent.attackTarget.get_ref():
				set_state(states.idle)
				parent.attackTarget = null
		states.dying:
			pass
			
#extends movement logic to prevent wiggling when overshooting destination
func _on_MoveTimer_timeout():
	if state != states.die:
		if parent.get_slide_count():
			if(parent.last_position.distance_to(parent.moveTarget) < 
			   parent.position.distance_to(parent.moveTarget) + parent.moveThreshold):
				parent.moveTarget = parent.position
				set_state(states.idle)
				command = Commands.NONE

func died():
	set_state(states.die)
	
#temporary until I have animated sprites. Delta is used as attack speed modifier
func _attack_target(delta):
	match state:
		states.attack:
			if parent.attackTarget.get_ref():
				if parent.attackTarget.get_ref().take_damage(parent.uDamage):
					if parent.attack_target_in_range():
						pass
				else:
					set_state(states.idle)
		states.die:
			parent.queue_free()
