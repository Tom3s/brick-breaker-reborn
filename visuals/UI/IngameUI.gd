extends VBoxContainer
class_name IngameUI

@onready var lives_label: Label = %CurrentLives
@onready var score_label: Label = %CurrentScore
@onready var multiplier_label: Label = %Multiplier
@onready var level_label: Label = %CurrentLevel
@onready var max_level_label: Label = %MaxLevels

@onready var main_ball_slot: TextureRect = %MainBallSlot
@onready var reserve_ball_slot: TextureRect = %ReserveBallSlot

@onready var activate_key: Button = %ActivateKey

func _ready() -> void:
	main_ball_slot.material = main_ball_slot.material.duplicate()
	reserve_ball_slot.material = reserve_ball_slot.material.duplicate()

func set_key_enabled(enabled: bool) -> void:
	activate_key.disabled = !enabled

func set_current_level(level: int) -> void:
	level_label.text = str(level)

func set_ball_slots(context: Global.GameContext) -> void:
	var new_img := load("res://visuals/textures/hp_indicators/dots/1.png")
	if context.ball_powerups.size() == 0:
		main_ball_slot.material.set_shader_parameter("sdf_texture", new_img)
		reserve_ball_slot.material.set_shader_parameter("sdf_texture", new_img)
		return

	if context.ball_powerups.size() == 1:
		reserve_ball_slot.material.set_shader_parameter("sdf_texture", new_img)


	if context.ball_powerups.size() >= 1:
		var main_power: Powerup = context.ball_powerups[0]
		var texture_loc: String = "res://visuals/textures/powerups/%s.png" % Powerup.Type.keys()[main_power.type]
		main_ball_slot.material.set_shader_parameter("sdf_texture", load(texture_loc))
		main_ball_slot.material.set_shader_parameter("icon_left", main_power.time_left / 15.0) # TODO: change properly
	
	if context.ball_powerups.size() >= 2:
		var reserve_power: Powerup = context.ball_powerups[1]
		var texture_loc: String = "res://visuals/textures/powerups/%s.png" % Powerup.Type.keys()[reserve_power.type]
		reserve_ball_slot.material.set_shader_parameter("sdf_texture", load(texture_loc))



