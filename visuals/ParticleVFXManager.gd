extends Node3D
class_name ParticleVFXManager

@onready var playing_vfx: Node3D = %PlayingVFX
@onready var explosion: GPUParticles3D = %Explosion
@onready var small_explosion: GPUParticles3D = %SmallExplosion


func play_explosion(pos: Vector2) -> void:
	var effect: GPUParticles3D = explosion.duplicate()

	playing_vfx.add_child(effect)

	effect.position = Vector3(
		pos.x, BreakableGrid.CELL_SIZE, pos.y
	)

	effect.visible = true
	effect.emitting = true

	effect.finished.connect(func() -> void:
		# playing_vfx.remove_child(effect)
		effect.queue_free()
	)

func play_small_explosion(pos: Vector2) -> void:
	var effect: GPUParticles3D = small_explosion.duplicate()

	playing_vfx.add_child(effect)

	effect.position = Vector3(
		pos.x, BreakableGrid.CELL_SIZE, pos.y
	)

	effect.visible = true
	effect.emitting = true

	effect.finished.connect(func() -> void:
		# playing_vfx.remove_child(effect)
		effect.queue_free()
	)
