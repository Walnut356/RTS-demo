"""
Handles the input and movement of the player viewport
"""

extends Camera2D

var camSpeed = 20
export var panSpeed = 75.0
export var marginX = 125.0
export var marginY = 125.0
var mousepos = Vector2()
var mouseposGlobal = Vector2()
var start = Vector2()
var startv = Vector2()
var end = Vector2()
var endv = Vector2()

var move_to_point = Vector2()

func _process(delta):
	#key-based movement
	var input =  Vector2(
	int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")),
	int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
)
	input = input.normalized()
	position = lerp(position, position + input * camSpeed, camSpeed * delta)

	#TODO drag based movement


	#TODO edgepan
	#check mousepos
	mousepos = get_local_mouse_position()
	mouseposGlobal = get_global_mouse_position()
	
	if mousepos.x < marginX:
			position.x = lerp(position.x, position.x - panSpeed, panSpeed * delta)
	elif mousepos.x > OS.window_size.x - marginX:
			position.x = lerp(position.x, position.x + panSpeed, panSpeed * delta)
	if mousepos.y < marginY:
			position.y = lerp(position.y, position.y - panSpeed, panSpeed * delta)
	elif mousepos.y > OS.window_size.y - marginY:
			position.y = lerp(position.y, position.y + panSpeed, panSpeed * delta)
