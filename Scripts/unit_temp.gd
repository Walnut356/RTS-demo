"""
Basic template for units. 
Contains unit stats, logic for the unit state machine
and some basic stuff like movement logic.
"""

extends KinematicBody2D
class_name Unit

#unit owner
export var unitOwner := ""
export var isAllied : bool

#unit stats
export var uSpeed = 300
export var uAccel = 300
export var uDecel = 4
export var uAttackRange = 40 #scales targetting collision bubble to determine attack range
export var uDamage = 10
#damage modifiers, assign unit types to group tags 
export var uHealth = 60
export var uShields = 60
export var uAttackSpeed = 1.34 #in seconds
export var ranged = true #ranged or melee unit?
export var projectile = true #if ranged, is attack hitscan or projectile?
#TODO ranged and melee attacks on the same unit?

#required code variables
var currHealth = uHealth
var currShields = uShields

#movement
var selected = false
var moveVector = Vector2.ZERO
var moveTarget = Vector2.ZERO
var targetMax = uSpeed/100
var speed = 0
var moveThreshold = 1
var lastPosition = Vector2.ZERO
var turnSpeed = 1 # leave at 1 for nimble units, between .8 and .5 for "clunky"

#attack
var possibleTargets = []
var attackTarget = null
#add threat level - sort by threat level, then by range
#possible targets attacking unit are higher threat level
#units that can't attack are lower threat level (except spellcasters)
#possibly: units  being attacked by other friendly units are higher threat levels?
#if there are multiple options, select at random


#misc
onready var state_machine = $smUnit
onready var _tween:Tween
const Projectile = preload("res://Scenes/Projectile.tscn")
signal disjoint

func _ready():
	_tween = Tween.new()
	#self.add_child(_tween)
	#_tween.set_active(true)
	moveTarget = position
	$AttackRange.set_scale(Vector2(uAttackRange, uAttackRange))
	var alertRange = max(uAttackRange + (uAttackRange/2), 30)
	$AlertRange.set_scale(Vector2(alertRange, alertRange))
	$VisionRange.set_scale(Vector2(50, 50))
	#i have no idea why i have to do this. I'm required to load the shader in editor, then do the
	#opposite of the intuitive bool operation. Any other variation of loading the shader or if statement
	#doesn't work. I don't know why applying this shader twice reverts it somehow.
	if(isAllied):
		$Selected.material = load("res://Materials/enemy_select.tres")
	$AttackTimer.set_wait_time(uAttackSpeed)



func _physics_process(delta):
	$MoveLine.set_point_position(0, position)
	


func Faction():
	return unitOwner

func get_state():
	return state_machine.state

#movement logic
func lookAtTarget(delta, tar):
		#var intendedAngle = position.direction_to(tar).angle()
		rotation = wrapf(lerp_angle(rotation, position.direction_to(tar).angle(), turnSpeed), -PI, PI)
		#_tween.interpolate_property(self, "rotation_degrees", rotation_degrees, wrapf(rotation_degrees + rad2deg(fmod(2*difference, TAU) - difference), 360), turnSpeed, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		#_tween.start()

func move_to_target(_delta, tar):
	speed = min(speed + uAccel, uSpeed) # factor in accel value, lock to max speed
	moveVector = position.direction_to(tar) * speed
	moveVector = move_and_slide(moveVector)

func MoveTo(tar):
	moveTarget = tar
	
func _on_MoveTimer_timeout():
	if(get_slide_count()):
		if lastPosition.distance_to(moveTarget) < position.distance_to(moveTarget) + moveThreshold:
			moveTarget = position

#selection member access
func Select():
	selected = true
	$Selected.visible = true

func Deselect():
	selected = false
	$Selected.visible = false

#Attack target logic

func _on_AlertRange_body_entered(body):
	if body.is_in_group("unit"):
		if(body.unitOwner != unitOwner):
			possibleTargets.append(body)

func _on_AlertRange_body_exited(body):
	pass
		
func _on_VisionRange_body_exited(body):
	if possibleTargets.has(body):
		possibleTargets.erase(body)


func _compare_distance(targetA, targetB):
	if position.distance_to(targetA.position) < position.distance_to(targetB.position):
		return true
	else:
		return false

func closest_enemy() -> Unit:
	if possibleTargets.size() > 0:
		possibleTargets.sort_custom(self, "_compare_distance")
		return possibleTargets[0]
	else:
		return null

func closest_enemy_in_range() -> Unit:
	if closest_enemy() in $AttackRange.get_overlapping_bodies():
		return closest_enemy()
	else:
		return null

func can_attack() -> bool:
	if closest_enemy() in $AttackRange.get_overlapping_bodies():
		return true
	else:
		return false

#health and damage calc

func take_damage(amount) -> bool:
	#determine if unit has shields, if so apply damage to shields first
	if currShields > 0 && currShields >= amount:
		currShields -= amount
		return true
	elif currShields < amount:
		amount -= currShields
		currShields = 0
		currHealth -= amount
	#death logic
	if currHealth <= 0:
		state_machine.died()
		#$CollisionShape.disabled = true
		if selected:
			print("Selected unit died")
			Deselect()
		emit_signal("disjoint", weakref(self), position)
		
		return false
	else:
		return true


func is_dying() -> bool:
	return state_machine.state == state_machine.states.die
	
func attack_current_target():
	if ranged == true && projectile == true:
		var projectile = Projectile.instance()
		get_tree().get_root().add_child(projectile)
		projectile.start(transform, attackTarget, uDamage)
		print("projectile spawned")
		
	elif ranged == true && projectile == false:
		pass
	elif ranged == false:
		pass



