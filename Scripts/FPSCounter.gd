extends Node2D

func _ready():
	Engine.set_target_fps(120)
func _process(delta):
	$FPSCounter.text = str(Engine.get_frames_per_second())
