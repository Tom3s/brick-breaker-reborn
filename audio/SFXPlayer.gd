extends Node
class_name SFXPlayer

@onready var ball_hit: AudioStreamPlayer = %BallHit

@onready var normal_block_hit: AudioStreamPlayer = %NormalBlock
@onready var ice_block_hit: AudioStreamPlayer = %IceBlock

@onready var laser_shot: AudioStreamPlayer = %LaserShot

@onready var flame_ignite: AudioStreamPlayer = %FlameIgnite
@onready var flame_extinguish: AudioStreamPlayer = %FlameExtinguish

func play_ball_hit() -> void:
	ball_hit.play()

func play_block_hit(type: BreakableBlock.BlockType) -> void:
	if type == BreakableBlock.BlockType.NORMAL:
		normal_block_hit.play()
	elif type == BreakableBlock.BlockType.ICE:
		ice_block_hit.play(.464)
	
func play_laser_shot() -> void:
	laser_shot.play()

func play_flame_ignite() -> void:
	flame_ignite.play()

func play_flame_extinguish() -> void:
	flame_extinguish.play()


	