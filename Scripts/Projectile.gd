extends Area2D

export var speed = 600
export var steer_force = 1000.0

var velocity = Vector2.ZERO
var acceleration = Vector2.ZERO
var target = null
var targetPos
var damage
var desired

func _ready():
	pass
	
func start(_transform, _target, _damage):
	global_transform = _transform
	velocity = transform.x * speed
	target = _target
	damage = _damage

func seek():
	var steer = Vector2.ZERO
	if target.get_ref():
		desired = (target.get_ref().position - position).normalized() * speed
		steer = (desired - velocity)
	return steer


func _physics_process(delta):
	acceleration += seek()
	velocity += acceleration * delta
	velocity = velocity.normalized() * speed
	rotation = velocity.angle()
	position += velocity * delta


func _on_Projectile_body_entered(body):
	if body == target.get_ref():
		set_physics_process(false)
		target.get_ref().take_damage(damage)
		print(target.get_ref().currHealth)
		print(target.get_ref().currShields)
		queue_free()

func _on_Disjoint(targ, pos):
	if target.get_ref() == targ.get_ref():
		targetPos = pos


func _on_timer_timeout():
	set_physics_process(false)
	queue_free()
	
