"""
Handles the input and movement of the player viewport
"""

extends Camera2D

var camSpeed = 20

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

