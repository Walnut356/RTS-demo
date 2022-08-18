extends KinematicBody2D
class_name Unit

#unit owner
export var unitOwner := ""
export var isAllied := true

#unit stats
var uSpeed = 300
var uAccel = 300
var uDecel = 4
var uAttackRange = 10
var uDamage = 10
var uHealth = 60
var uShields = 60
var uAttackSpeed = .5

#required code variables

#movement
var selected = false
var moveVector = Vector2.ZERO
var moveTarget = Vector2.ZERO
var targetMax = uSpeed/100
var speed = 0
var moveThreshold = 1
var lastPosition = Vector2.ZERO

#attack
var possibleTargets = []
var attackTarget
#add threat level - sort by threat level, then by range
#possible targets attacking unit are higher threat level
#units that can't attack are lower threat level (except spellcasters)
#possibly: units  being attacked by other friendly units are higher threat levels?
#if there are multiple options, select at random
var tempRange = Vector2(uAttackRange, uAttackRange)

#misc
onready var state_machine = $smUnit

func _ready():
	moveTarget = position


func _process(delta):
	$Targetting.set_scale(tempRange)
	
	#i have no idea why i have to do this. I'm required to load the shader in editor, then do the
	#opposite of the intuitive bool operation. Any other variation of loading the shader or if statement
	#doesn't work. I don't know why applying this shader twice reverts it somehow.
	if(isAllied):
		$Selected.material = load("res://Materials/enemy_select.tres")

func move_to_target(_delta, tar):
	speed = min(speed + uAccel, uSpeed) # factor in accel value
	moveVector = position.direction_to(tar) * speed
	moveVector = move_and_slide(moveVector)
	
func Faction():
	return unitOwner

func MoveTo(tar):
	moveTarget = tar
	
func Select():
	selected = true
	$Selected.visible = true

func Deselect():
	selected = false
	$Selected.visible = false

func _on_MoveTimer_timeout():
	if(get_slide_count()):
		if lastPosition.distance_to(moveTarget) < position.distance_to(moveTarget) + moveThreshold:
			moveTarget = position

func _on_Targetting_body_entered(body):
	if body.is_in_group("unit"):
		if(not body.isAllied):
			possibleTargets.append(body)

func _on_Targetting_body_exited(body):
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
	if closest_enemy().position.distance_to(position) <= uAttackRange * 10:
		return closest_enemy()
	else:
		return null
		
func take_damage(amount) -> bool:
	if uShields > 0 && uShields >= amount:
		uShields -= amount
		return true
	elif uShields < amount:
		amount -= uShields
		uHealth -= amount
	
	if uHealth <= 0:
		state_machine.died()
		$CollisionShape.disabled = true
		return false
	else:
		return true
		
func get_state():
	return state_machine.state


func is_dying() -> bool:
	return state_machine.state == state_machine.states.die
