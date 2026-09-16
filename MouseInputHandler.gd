extends Node
class_name MouseInputHandler

# TODO: might wanna handle this in an other way to not get race conditions and have more consistent phisycs
# signal mouse_moved(dist: Vector2)
# signal release_ball_pressed()

var accumulated_mouse_movement: Vector2
var last_touch_position: Vector2
var release_ball_pressed: bool
var release_ball_was_pressed: bool
var ball_powerup_pressed: bool
var ball_powerup_was_pressed: bool
var unlock_pressed: bool
var unlock_was_pressed: bool

var action_last_pressed: float = 0.0
var BUFFER_LENGTH: float = 0.1

func _process(delta: float) -> void:
	# TODO: handle mouse hiding properly
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	


var last_mouse_pos: Vector2
# var last_touch_second: 
var touch_screen_controls: bool
func _unhandled_input(event: InputEvent) -> void:
	touch_screen_controls = OS.has_feature("web_android") || OS.has_feature("android")
	# touch_screen_controls = true
	
	if touch_screen_controls:
		if event is InputEventScreenDrag:
			if event.index == 0:
				accumulated_mouse_movement += (event.position - last_touch_position) * Global.PLAYER_SENSITIVITY
				last_touch_position = event.position
		
		if event is InputEventScreenTouch:
			if event.index == 0:
				last_touch_position = event.position
			if event.index == 0 || event.index == 1:
				release_ball_pressed = release_ball_pressed || event.pressed
				

		ball_powerup_pressed = Input.is_action_just_pressed("activate_ball")
		unlock_pressed = Input.is_action_just_pressed("activate_key")
	
	else:
		if event is InputEventMouseMotion:
			accumulated_mouse_movement += event.screen_relative * Global.PLAYER_SENSITIVITY

		release_ball_pressed = Input.is_action_just_pressed("release_ball")
		ball_powerup_pressed = Input.is_action_just_pressed("activate_ball")
		unlock_pressed = Input.is_action_just_pressed("activate_key")

	# release_ball_pressed = Input.is_action_pressed("release_ball")
	# ball_powerup_activated = !ball_powerup_was_activated && Input.is_action_pressed("activate_ball")
	# if Input.is_action_just_pressed("activate_ball"):
	# ball_powerup_was_activated = Input.is_action_pressed("activate_ball")

func release_ball_just_pressed() -> bool:
	return !release_ball_was_pressed && release_ball_pressed

func ball_powerup_just_pressed() -> bool:
	return !ball_powerup_was_pressed && ball_powerup_pressed

func unlock_just_pressed() -> bool:
	return !unlock_was_pressed && unlock_pressed

func action_press_buffered() -> bool:
	return action_last_pressed <= BUFFER_LENGTH

func frame_end_propagation(delta: float) -> void:
	if release_ball_just_pressed():
		action_last_pressed = 0.0
	else:
		action_last_pressed += delta

	ball_powerup_was_pressed = ball_powerup_pressed
	release_ball_was_pressed = release_ball_pressed
	unlock_was_pressed = unlock_pressed
	ball_powerup_pressed = false
	release_ball_pressed = false
	unlock_pressed = false
	
	