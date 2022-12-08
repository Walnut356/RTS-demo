"""
Unit state machine
Handles input for unit commands
Handles logic for states and state transitions
"""

extends StateMachine

onready var AttackTimer = get_node("../AttackTimer")
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
	$"%MoveLine".set_as_toplevel(true)
	$"%MoveLine".set_point_position(0, parent.position)
	$"%MoveLine".set_point_position(1, parent.position)
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
	if parent.selected and state != states.die and get_node("/root/room_temp/InputHandler").dragging == false:
		#keyboard inputs
		if Input.is_action_just_pressed("attack_move"):
			command_mod = CommandMods.ATTACK_MOVE
		if Input.is_action_just_pressed("hold"):
			command = Commands.HOLD
			set_state(states.idle)
		if Input.is_action_just_pressed("stop"):
			command = Commands.NONE
			set_state(states.idle)
		if Input.is_action_just_pressed("Cancel"):
			command_mod = CommandMods.NONE
		#mouse inputs
		if Input.is_action_just_pressed("mouseR"):
			command = Commands.MOVE
			parent.attackTarget = null
			parent.moveTarget = get_global_mouse_position()
			$"%MoveLine".set_point_position(1, get_global_mouse_position())
			set_state(states.move)
		if (Input.is_action_just_pressed("mouseL") and command_mod == CommandMods.ATTACK_MOVE):
				parent.moveTarget = get_global_mouse_position()
				command = Commands.ATTACK_MOVE
				command_mod = CommandMods.NONE
				set_state(states.move)

#----state logic---#
func _state_logic(delta):
	match state:
		states.idle:
			pass
		states.move:
			parent.lookAtTarget(delta, parent.moveTarget)
			if parent.rotation - parent.position.direction_to(parent.moveTarget).angle() <= .01:
				parent.move_to_target(delta, parent.moveTarget)
			
		states.aggro:
			if parent.closest_enemy():
				parent.moveTarget = parent.closest_enemy().position
				parent.lookAtTarget(delta, parent.moveTarget)
				if parent.rotation - parent.position.direction_to(parent.moveTarget).angle() <= .01:
					parent.move_to_target(delta, parent.closest_enemy().position)
				
		states.attack:
			if parent.attackTarget:
				if parent.attackTarget.get_ref():
					parent.lookAtTarget(delta, parent.attackTarget.get_ref().position)
					
		states.die:
			died()


#Logic for when to set a state
func _get_transition(delta):
	match state:
		states.idle:
			if command == Commands.HOLD:
					if parent.closest_enemy_in_range() != null and parent.can_attack():
						parent.attackTarget = weakref(parent.closest_enemy_in_range())
						return states.attack
			else:
				if parent.closest_enemy():
					parent.attackTarget = weakref(parent.closest_enemy())
					parent.moveTarget = parent.position
					return states.aggro
		states.move:
			if (command == Commands.ATTACK_MOVE):
				if parent.closest_enemy() != null:
					parent.attackTarget = weakref(parent.closest_enemy())
					parent.moveTarget = parent.position
					return states.aggro
			if parent.position.distance_to(parent.moveTarget) < parent.targetMax:
				parent.moveTarget = parent.position
				command = Commands.NONE
				return states.idle
				
		states.aggro:
			if parent.closest_enemy_in_range() != null:
				parent.attackTarget = weakref(parent.closest_enemy_in_range())
				return states.attack
			if parent.attackTarget.get_ref() == null:
				return states.idle
		states.attack:
			if not parent.possibleTargets.has(parent.attackTarget.get_ref()):
				parent.attackTarget = null
				return states.idle
			if not parent.can_attack():
				if command == Commands.HOLD:
					return states.idle
				else:
					return states.aggro
		states.die:
			pass
			
func _enter_state(newState, oldState):
	match newState:
		states.attack:
			if parent.attackTarget != null:
				parent.attack_current_target()
			AttackTimer.start()
			


func _exit_state(old_state, new_state):
	match old_state:
		states.attack:
			AttackTimer.stop()
			if new_state == states.idle:
				parent.attackTarget = null
		states.move:
			if new_state != states.move and command != Commands.ATTACK_MOVE:
				parent.moveTarget = parent.position


#---signals---#
#extends movement logic to prevent wiggling when overshooting destination
func _on_MoveTimer_timeout():
	if state != states.die:
		if parent.get_slide_count():
			if(parent.last_position.distance_to(parent.moveTarget) < 
			   parent.position.distance_to(parent.moveTarget) + parent.moveThreshold):
				parent.moveTarget = parent.position
				command = Commands.NONE
				set_state(states.idle)

func died():
	set_physics_process(false)
	parent.queue_free()

func _on_AttackTimer_timeout():
	if parent.attackTarget != null:
		parent.attack_current_target()


func _on_AttackRange_body_exited(body):
	if body == parent.attackTarget:
		set_state(states.aggro)
