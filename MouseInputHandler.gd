extends Node
class_name MouseInputHandler

# TODO: might wanna handle this in an other way to not get race conditions and have more consistent phisycs
signal mouse_moved(dist: Vector2)
signal release_ball_pressed()

var mouse_pos: Vector2

func _process(delta: float) -> void:
	# TODO: handle mouse hiding properly
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	

var last_mouse_pos: Vector2
func _unhandled_input(event: InputEvent) -> void:
	# if !inputEnabled:
	# 	return
	# Receives mouse motion
	mouse_pos = Vector2.ZERO
	if event is InputEventMouseMotion:
		mouse_pos = event.screen_relative
		# print(mouse_pos)
		mouse_moved.emit(mouse_pos)
	
	if Input.is_action_just_pressed("release_ball"):
		release_ball_pressed.emit()
