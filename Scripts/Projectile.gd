extends RigidBody2D

var pSpeed = 600
var pAccel = 50
var target
var currSpeed = 0
var moveVector = Vector2.ZERO
func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	currSpeed = min(currSpeed + pAccel, pSpeed) # factor in accel value, lock to max speed
	moveVector = position.direction_to(target.position) * currSpeed
	position += moveVector
	
