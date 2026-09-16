extends Node3D
# class_name # not requiered for test

@onready var ball_mesh_scene: PackedScene = preload("res://visuals/BallMesh.tscn")
@onready var block_mesh_scene: PackedScene = preload("res://visuals/BlockMesh.tscn")
@onready var powerup_asset_scene: PackedScene = preload("res://visuals/PowerupAsset.tscn")
@onready var gun_bullet_asset_scene: PackedScene = preload("res://visuals/GunBullet.tscn")

@onready var sfx_player: SFXPlayer = %SFXPlayer
# @onready var ball_mesh: MeshInstance3D = %BallMesh
@onready var ball_parent: Node3D = %Balls
@onready var powerup_parent: Node3D = %Powerups
@onready var paddle_mesh: MeshInstance3D = %PaddleMesh
@onready var laser_asset: LaserAsset = %LaserAsset
@onready var block_parent: Node3D = %Blocks
@onready var projectile_parent: Node3D = %Projectiles
@onready var mouse_input_handler: MouseInputHandler = %MouseInputHandler

@onready var play_layer_viewport: SubViewport = %PlayLayerViewport
@onready var play_layer_camera: Camera3D = %PlayLayerCamera

@onready var debug_parent: Node3D = %Debug

@onready var roof: MeshInstance3D = %Roof

@onready var ingame_ui: IngameUI = %IngameUI

var wall_material: ShaderMaterial

# var ball: Ball = Ball.new()
# var balls: Array[Ball]
# var paddle: Paddle = Paddle.new()

# var screen_collision: Array[LineCollider]
# var death_barrier: LineCollider
# var blocks: Array[BreakableBlock]

# var broken_block_count: int = 0
# var nr_metal_blocks: int = 0

# var powerups: Array[Powerup]
var context: Global.GameContext

func _ready() -> void:
	context = Global.GameContext.new()
	# ball.randomize_velocity()
	var _new_ball: Ball = Ball.new()
	_new_ball.asset_ref = ball_mesh_scene.instantiate()
	context.balls.push_back(_new_ball)

	# screen_bounds = DisplayServer.window_get_size()
	set_up_screen_collision()

	var base_seed: int = randi()

	for i in Global.LEVEL_COUNT:
		context.add_block_array(generate_sparse_map(base_seed + i), i)
		generate_block_assets(context.levels[i].blocks)

	display_blocks(context.levels[context.current_level].blocks)
	

	handle_mouse_movement(Vector2.ZERO)
	context.paddle.position.x = 0.0

	# paddle.collider_line.debug_set_up = false
	context.paddle.set_line()

	# TODO: add back ball power sounds
	# context.fireball_activated.connect(sfx_player.play_flame_ignite)
	# context.fireball_deactivated.connect(sfx_player.play_flame_extinguish)

	# if DEBUG:
	DebugScreen.add_debug_line(func() -> String: return "FPS(d): %.2f" % _debug_fps)
	DebugScreen.add_debug_line(func() -> String: return "Frametime: %.3fms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000))
	DebugScreen.add_debug_line(context.balls[0]._get_ball_pos_debug)
	DebugScreen.add_debug_line(context._get_debug_string)


	%Playfield.mesh.size = 1024 / 32.0 * BreakableGrid.GRID_SIZE
	%LeftWall.mesh.size.x = 1024 / 32.0 * BreakableGrid.GRID_SIZE.y
	%RightWall.mesh.size.x = 1024 / 32.0 * BreakableGrid.GRID_SIZE.y
	roof.mesh.size.x = 1024 / 32.0 * BreakableGrid.GRID_SIZE.x
	%LeftWall.position.x = -(BreakableGrid.GRID_SIZE.x * BreakableGrid.CELL_SIZE / 2)
	%RightWall.position.x = (BreakableGrid.GRID_SIZE.x * BreakableGrid.CELL_SIZE / 2)
	roof.position.z = -(BreakableGrid.GRID_SIZE.y * BreakableGrid.CELL_SIZE / 2)

	wall_material = %LeftWall.get_surface_override_material(0)

	
var _debug_fps: float = 0.0
func _process(delta: float) -> void:
	play_layer_camera.position = get_viewport().get_camera_3d().position
	play_layer_camera.rotation = get_viewport().get_camera_3d().rotation
	play_layer_camera.fov = get_viewport().get_camera_3d().fov
	_debug_fps = 1.0 / delta
	# var safe_delta: float = min(delta, 1. / 60)
	var safe_delta: float = delta

	context.set_flags()
	# delta *= .1
	# safe_delta *= .6

	play_layer_viewport.size = get_viewport().get_visible_rect().size

	# ooooooooo  ooooooooooo oooooooooo ooooo  oooo  ooooooo8  
	#  888    88o 888    88   888    888 888    88 o888    88  
	#  888    888 888ooo8     888oooo88  888    88 888    oooo 
	#  888    888 888    oo   888    888 888    88 888o    88  
	# o888ooo88  o888ooo8888 o888ooo888   888oo88   888ooo888  
														 
	if Global.DEBUG:
		context._set_debug_strings()
		
		if Input.is_action_just_pressed("debug_powerup"):
			var powerup: Powerup = Powerup.new()
			powerup.randomize_velocity()

			var mesh: MeshInstance3D = MeshInstance3D.new()
			mesh.mesh = SphereMesh.new()
			mesh.mesh.radius = 16
			mesh.mesh.height = 32
			debug_parent.add_child(mesh)

			powerup.asset = mesh

			context.powerups.push_back(powerup)
		
		if Input.is_action_just_pressed("debug_ball"):
			var ball: Ball = Ball.new()
			ball.asset_ref = ball_mesh_scene.instantiate()
			ball.released = true
			context.balls.push_back(ball)

			ball.randomize_velocity()
		
		# SET DEBUG VISUALS
		DebugScreen.debug_visuals.clear()
		if DebugScreen.VISUAL_DEBUG:
			DebugScreen.debug_visuals.push_back(context.paddle.line.debug_visual)


	# ooooo oooo   oooo oooooooooo ooooo  oooo ooooooooooo 
	#  888   8888o  88   888    888 888    88  88  888  88 
	#  888   88 888o88   888oooo88  888    88      888     
	#  888   88   8888   888        888    88      888     
	# o888o o88o    88  o888o        888oo88      o888o                                            

	handle_mouse_movement(mouse_input_handler.accumulated_mouse_movement)
	mouse_input_handler.accumulated_mouse_movement = Vector2.ZERO

	context.paddle.lerp_move(safe_delta)

	
	if !context.balls[0].released && mouse_input_handler.release_ball_just_pressed():
		release_ball()
	
	if mouse_input_handler.ball_powerup_just_pressed():
		context.activate_ball_power()
		print("pressing ball powerup")

	
	if mouse_input_handler.unlock_just_pressed():
		context.activate_key()
		roof.visible = false

	# WARNING: no input event should be handled after this, as it may be incorrect state

	# oooooooooo      o      ooooo       ooooo        oooooooo8  
	#  888    888    888      888         888        888         
	#  888oooo88    8  88     888         888         888oooooo  
	#  888    888  8oooo88    888      o  888      o         888 
	# o888ooo888 o88o  o888o o888ooooo88 o888ooooo88 o88oooo888  

	if context.balls.size() == 1 && !context.balls[0].released:
		context.balls[0].set_position(context.paddle.position + Vector2.UP * context.balls[0].radius * 2)
	else:
		# ball.move(delta)
		for ball: Ball in context.balls:
			ball.move(safe_delta)

	# handling blocks before balls
	# this is bc multiball powerup might rotate the ball's 
	# velocity of out the play area
	# TODO: this might've been bc of delta becoming too high
	# investigate with safe_delta and move back if neccessary
	# blocked by: bitmap optimization

	# ooooo ooooo ooooo ooooooooooo      oooooooooo ooooo         ooooooo     oooooooo8 oooo   oooo 
	#  888   888   888  88  888  88       888    888 888        o888   888o o888     88  888  o88   
	#  888ooo888   888      888           888oooo88  888        888     888 888          888888     
	#  888   888   888      888           888    888 888      o 888o   o888 888o     oo  888  88o   
	# o888o o888o o888o    o888o         o888ooo888 o888ooooo88   88ooo88    888oooo88  o888o o888o 
																							  
	for ball: Ball in context.balls:
		if !ball.released:
			# break # TODO: might be hacky
			continue # should fix stuck ball bug


		for block: BreakableBlock in context.get_blocks_for_circle(ball.position, ball.radius):
			# if block == null:
			# 	LoggerMogyi.log(self, "PANIC smth aint right")
			# TODO: remove later
			if DebugScreen.VISUAL_DEBUG:
				DebugVisual.draw_rectangle(
					block.a, block.b, Color.BLUE
				)
			for line: LineCollider in block.collision:

				var collision_result := line.collide_with_ball(ball, safe_delta)

				# if ball.collide_with(line, block.reflects_ball(context)):
				if collision_result.collided:
					if block.reflects_ball(context):
						ball.position = collision_result.position
						ball.velocity = collision_result.velocity
						# TODO: boost ball on collision
						ball.boost()

					block.hit_block(context, ball)

					if context.get_active_ball_powerup() == Ball.Type.ICE:
						convert_blocks_to_ice(ball.position)
					elif context.get_active_ball_powerup() == Ball.Type.MINE:
						explode_blocks(ball.position)


			if block.is_broken():
				if block.has_powerup:
					block.has_powerup = false
					spawn_powerup(block)
				
				context.broken_block_count += 1

				# testing?
				block.asset_ref.queue_free()
				# LoggerMogyi.log(self, "Removed asset ref for block")
				context.remove_block(block)
				break


	

	#   oooooooo8   ooooooo  ooooo       ooooo       ooooo  oooooooo8 ooooo  ooooooo  oooo   oooo 
	# o888     88 o888   888o 888         888         888  888         888 o888   888o 8888o  88  
	# 888         888     888 888         888         888   888oooooo  888 888     888 88 888o88  
	# 888o     oo 888o   o888 888      o  888      o  888          888 888 888o   o888 88   8888  
	#  888oooo88    88ooo88  o888ooooo88 o888ooooo88 o888o o88oooo888 o888o  88ooo88  o88o    88  
																							
	# check for death barrier first
	var index: int = 0
	while index < context.balls.size():
		var ball: Ball = context.balls[index]

		var colliion_result := context.death_barrier.collide_with_ball(ball)

		if colliion_result.collided || outside_screen_bounds(ball):	
			if context.balls.size() > 1:
				# ball_parent.remove_child(ball.asset_ref)
				ball.asset_ref.queue_free()
				context.balls.erase(ball)
				index -= 1
			else:
				if context.is_death_barrier_active():
					on_death()
				else:
					context.prev_level()
					display_blocks(context.levels[context.current_level].blocks)
					roof.visible = false
					break
		
		index += 1
	
	var level_unlocked: bool = context.levels[context.current_level].unlocked
	for ball: Ball in context.balls:

		var collision_result := context.top_barrier.collide_with_ball(ball)

		# if ball.collide_with(context.top_barrier, !level_unlocked, !level_unlocked):
		if collision_result.collided:
			if !level_unlocked:
				ball.position = collision_result.position
				ball.velocity = collision_result.velocity
				# TODO
				ball.boost()

			if level_unlocked:
				context.next_level()
				display_blocks(context.levels[context.current_level].blocks)
				roof.visible = !context.levels[context.current_level].unlocked
				break


	for line in context.screen_collision:
		# ball.collide_with(line, true)
		for ball: Ball in context.balls:
			var collision_result := line.collide_with_ball(ball)
			if collision_result.collided:
				ball.position = collision_result.position
				ball.velocity = collision_result.velocity
				# TODO
				ball.boost()
			# ball.collide_with(line, true)

	
	if context.is_current_level_complete():
		# TODO: change blocks to breakable if only non-breakable remain
		# on_board_clear()
		# return
		context.next_level()
		display_blocks(context.levels[context.current_level].blocks)
		roof.visible = !context.levels[context.current_level].unlocked

		if context.balls.size() == 0:
			var _new_ball: Ball = Ball.new()
			_new_ball.asset_ref = ball_mesh_scene.instantiate()
			context.balls.push_back(_new_ball)
			on_death()

	for ball: Ball in context.balls:
		var collision_result := context.paddle.line.collide_with_ball(ball)

		# if ball.collide_with_paddle(context.paddle):
		if collision_result.collided:
			ball.position = collision_result.contact_point + (context.paddle.line.normal * ball.radius)
			var reflection_angle: float = lerpf(
				-context.paddle.reflection_angle, 
				context.paddle.reflection_angle, 
				collision_result.t
			)
			ball.velocity = Vector2.UP.rotated(reflection_angle)
			ball.boost()

			sfx_player.play_paddle_hit()

	# ooooooooooo ooooooooooo ooooooooooo ooooooooooo  oooooooo8 ooooooooooo  oooooooo8  
	#  888    88   888    88   888    88   888    88 o888     88 88  888  88 888         
	#  888ooo8     888ooo8     888ooo8     888ooo8   888             888      888oooooo  
	#  888    oo   888         888         888    oo 888o     oo     888             888 
	# o888ooo8888 o888o       o888o       o888ooo8888 888oooo88     o888o    o88oooo888  

	if context.TUNNEL_ACTIVE:
		context.paddle.set_tunnel_lines()
		for ball: Ball in context.balls:
			var collision_result := context.paddle.tunnel_left.collide_with_ball(ball)
			if collision_result.collided:
				ball.position = collision_result.position
				ball.velocity = collision_result.velocity
				ball.boost()
				continue
			
			collision_result = context.paddle.tunnel_right.collide_with_ball(ball)
			if collision_result.collided:
				ball.position = collision_result.position
				ball.velocity = collision_result.velocity
				ball.boost()


	# update active effects
	var disable_effect_queue: Array[Powerup]
	for powerup: Powerup in context.active_powerups:
		powerup.update(safe_delta)
		if powerup.time_left <= 0.0:
			disable_effect_queue.push_back(powerup)
		
		if powerup.laser_shot:
			for block: BreakableBlock in context.get_blocks_for_aabb(
				context.paddle.position + Vector2.UP * grid_unit_size.y,
				context.paddle.position,
			):
				if DebugScreen.VISUAL_DEBUG:
					DebugVisual.draw_rectangle_timed(
						block.a, block.b, Color.ORANGE, 0.75
					)
				if block.a.x <= context.paddle.position.x && block.b.x >= context.paddle.position.x:
					damage_block_and_clear(block, context.get_laser_damage())
			
			sfx_player.play_laser_shot()
	

	if context.ball_power_active:
		context.update_ball_powerup(safe_delta)

	for powerup: Powerup in disable_effect_queue:
		context.active_powerups.erase(powerup)
	
	context.gun_cooldown -= safe_delta
	if context.GUN_ACTIVE && mouse_input_handler.action_press_buffered() && context.gun_cooldown <= 0.0:
		LoggerMogyi.log(self, "Shooting with active GUN powerup")
		spawn_gun_projectiles()
		sfx_player.play_gun_shot()
		context.gun_cooldown = Powerup.GUN_MAX_COOLDOWN
		mouse_input_handler.action_last_pressed = mouse_input_handler.BUFFER_LENGTH

	# update projectiles
	#
	# oooooooooo oooooooooo    ooooooo  ooooo ooooooooooo  oooooooo8 ooooooooooo ooooo ooooo       ooooooooooo  oooooooo8  
	#  888    888 888    888 o888   888o 888   888    88 o888     88 88  888  88  888   888         888    88  888         
	#  888oooo88  888oooo88  888     888 888   888ooo8   888             888      888   888         888ooo8     888oooooo  
	#  888        888  88o   888o   o888 888   888    oo 888o     oo     888      888   888      o  888    oo          888 
	# o888o      o888o  88o8   88ooo88   888  o888ooo8888 888oooo88     o888o    o888o o888ooooo88 o888ooo8888 o88oooo888  
	#                                 8o888                                                                                

	var proj_marked_for_remove: Array[Projectile] = []																					
	for projectile: Projectile in context.projectiles:
		projectile.move(safe_delta)
		# TODO: -grid_unit_size.y / 2 might work just as well
		if projectile.position.y < -grid_unit_size.y: 
			proj_marked_for_remove.push_back(projectile)
			continue

		if projectile.type == Projectile.Type.GUN_BULLET:
			var blocks: Array[BreakableBlock] = context.get_blocks_for_aabb(projectile.position, projectile.position - (projectile.velocity * safe_delta))
			if blocks.size() == 0: continue

			var bottom_most_block: BreakableBlock = blocks[0]
			
			for i in blocks.size():
				if i == 0: continue

				if blocks[i].b.y > bottom_most_block.b.y:
					bottom_most_block = blocks[i]
			
			if DebugScreen.VISUAL_DEBUG:
				DebugVisual.draw_rectangle_timed(
					bottom_most_block.a, bottom_most_block.b, Color.CYAN, 0.1
				)

			damage_block_and_clear(bottom_most_block, context.get_gun_damage())
			proj_marked_for_remove.push_back(projectile)

	
	for projectile: Projectile in proj_marked_for_remove:
		projectile.asset_ref.queue_free()
		context.projectiles.erase(projectile)



	# https://patorjk.com/software/taag/#p=display&f=O8
	#
	# ooooo  oooo ooooo  oooooooo8 ooooo  oooo    o      ooooo        oooooooo8  
	#  888    88   888  888         888    88    888      888        888         
	#   888  88    888   888oooooo  888    88   8  88     888         888oooooo  
	#    88888     888          888 888    88  8oooo88    888      o         888 
	#     888     o888o o88oooo888   888oo88 o88o  o888o o888ooooo88 o88oooo888  

	# ==========================================================================================

	# oooooooooo    ooooooo  oooo     oooo ooooooooooo oooooooooo ooooo  oooo oooooooooo   oooooooo8  
	#  888    888 o888   888o 88   88  88   888    88   888    888 888    88   888    888 888         
	#  888oooo88  888     888  88 888 88    888ooo8     888oooo88  888    88   888oooo88   888oooooo  
	#  888        888o   o888   888 888     888    oo   888  88o   888    88   888                888 
	# o888o         88ooo88      8   8     o888ooo8888 o888o  88o8  888oo88   o888o       o88oooo888  
																										 

	# update powerup pickups
	for powerup: Powerup in context.powerups:
		powerup.move(safe_delta)
		powerup.asset.position.x = powerup.position.x
		powerup.asset.position.z = powerup.position.y
		powerup.asset.position.y = BreakableGrid.CELL_SIZE

		collide_with_screen(powerup)

		# powerup picked up logic
		# TODO: move to its own function
		if powerup.collide_with_paddle(context.paddle):
			powerup.activate_powerup(context)
			context.powerups.erase(powerup)
			powerup.asset.queue_free()
		
		if powerup.position.y > BreakableGrid.GRID_SIZE.y * BreakableGrid.CELL_SIZE * 1.5:
			context.powerups.erase(powerup)
			powerup.asset.queue_free()

	if context.TUNNEL_ACTIVE:
		context.paddle.tunnel_left.debug_visual.draw_debug()
		context.paddle.tunnel_right.debug_visual.draw_debug()

	var wall_sdf_balls: PackedVector3Array
	wall_sdf_balls.resize(32) # TODO: MAX_BALL_COUNT
	wall_sdf_balls.fill(Vector3.INF)

	for i in context.balls.size():
		var ball: Ball = context.balls[i]
		
		if ball.asset_ref.get_parent() == null:
			ball_parent.add_child(ball.asset_ref)

			# TODO: hooking up sound player here
			ball.collided.connect(sfx_player.play_ball_hit)


		ball.asset_ref.global_position.x = ball.position.x
		ball.asset_ref.global_position.z = ball.position.y
		ball.asset_ref.global_position.y = ball.radius

		if i < 32: # TODO: MAX_BALL_COUNT
			wall_sdf_balls[i] = ball.asset_ref.global_position

		ball.asset_ref.set_visual(context.get_active_ball_powerup())
		ball.asset_ref.set_effect_rotation(ball.velocity)

	wall_material.set_shader_parameter("balls", wall_sdf_balls)
	roof.get_surface_override_material(0).set_shader_parameter("balls", wall_sdf_balls)


	for projectile: Projectile in context.projectiles:
		projectile.asset_ref.global_position.x = projectile.position.x
		projectile.asset_ref.global_position.z = projectile.position.y
		projectile.asset_ref.global_position.y = BreakableGrid.CELL_SIZE / 2.0

	paddle_mesh.global_position.x = context.paddle.position.x
	paddle_mesh.global_position.z = context.paddle.position.y
	paddle_mesh.global_position.y = context.paddle.height / 2

	laser_asset.visible = context.LASER_ACTIVE
	# laser_asset.%Beam.material_override.set_shader_parameter("TimeLeft", context.LASER_COOLDOWN)
	laser_asset.set_visual(context.LASER_COOLDOWN)

	# set UI
	ingame_ui.set_ball_slots(context)
	ingame_ui.set_current_level(context.current_level + 1)
	ingame_ui.set_key_enabled(context.get_can_key_be_used())

	# DRAW DEBUG
	if Global.DEBUG && DebugScreen.VISUAL_DEBUG:
		for block: BreakableBlock in context.get_current_blocks():
			for line: LineCollider in block.collision:
				DebugScreen.debug_visuals.push_back(line.debug_visual)
		
		# TODO: uncomment this once proper visual is implemented
		# if context.TUNNEL_ACTIVE:
		# 	DebugScreen.debug_visuals.push_back(context.paddle.tunnel_left.debug_visual)
		# 	DebugScreen.debug_visuals.push_back(context.paddle.tunnel_right.debug_visual)


	if DebugScreen.VISUAL_DEBUG:
		DebugScreen.draw_debug_visuals()

	mouse_input_handler.frame_end_propagation(safe_delta)



var grid_unit_size: Vector2
func set_up_screen_collision() -> void:
	# var screen_bounds: Vector2 = DisplayServer.window_get_size()

	grid_unit_size = BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE
	var p1: Vector2 = Vector2(-grid_unit_size.x / 2, -grid_unit_size.y / 2)
	var p2: Vector2 = Vector2(grid_unit_size.x / 2, -grid_unit_size.y / 2)
	var p3: Vector2 = Vector2(grid_unit_size.x / 2, grid_unit_size.y / 2)
	var p4: Vector2 = Vector2(-grid_unit_size.x / 2, grid_unit_size.y / 2)

	var line: LineCollider = LineCollider.new()
	# line.set_points(p1, p2)
	# context.screen_collision.push_back(line)

	# This is the top barrier
	context.top_barrier = LineCollider.new()
	context.top_barrier.set_points(p2, p1)

	# This is the death barrier
	context.death_barrier = LineCollider.new()
	context.death_barrier.set_points(p4, p3)

	# p3.y += grid_unit_size.y
	# p4.y += grid_unit_size.y

	line = LineCollider.new()
	line.set_points(p3, p2)
	context.screen_collision.push_back(line)

	line = LineCollider.new()
	line.set_points(p1, p4)
	context.screen_collision.push_back(line)

	context.screen_a = p1
	context.screen_b = p3



func handle_mouse_movement(movement: Vector2) -> void:
	context.paddle.move_desired_pos(movement)

func release_ball() -> void:
	context.balls[0].randomize_velocity()
	context.balls[0].released = true

# Handle any logic for death
func on_death() -> void:
	context.balls[0].velocity = Vector2.ZERO
	context.balls[0].released = false
	LoggerMogyi.log(self, "Died")

func generate_sparse_map(seed: int = randi()) -> Array[BreakableBlock]:
	var map_generator := MapGenerator.new()
	map_generator.rng.seed = seed

	# map_generator.add_uv_to_color()
	map_generator.add_random_gradient_to_color()
	map_generator.add_perlin_noise()
	# map_generator.treshold_grayscale(0.65)
	map_generator.treshold_grayscale(0.4)

	map_generator.copy_texture_to_final_bound(0, 0, BreakableGrid.GRID_SIZE.x, int(BreakableGrid.GRID_SIZE.y * 0.66))

	return map_generator.convert_with_chance_merge(.5, .5)
	# return map_generator.convert_with_chance_merge(.0, .0)


func generate_block_assets(blocks: Array[BreakableBlock]) -> void:
	for block: BreakableBlock in blocks:
		var block_mesh: BlockMesh = block_mesh_scene.instantiate()
		block_parent.add_child(block_mesh)
		# block_mesh.set_visual_scale(block.size * BreakableGrid.CELL_SIZE)
		block_mesh.set_polygon(block.points)

		var final_pos: Vector2 = block._get_collision_vertex_position(Vector2.ZERO)
		block_mesh.global_position.x = final_pos.x
		block_mesh.global_position.z = final_pos.y
		# block_mesh.global_position.y = BreakableGrid.CELL_SIZE / 2
		block_mesh.global_position.y = 0
		block_mesh.set_material(block.type)
		if block.has_powerup && block.powerup.type == Powerup.Type.KEY:
			block_mesh.set_key_block()
		else:
			block_mesh.set_hp(block.health)
			block_mesh.set_color(block.color)


		block.asset_ref = block_mesh

		block.just_broken.connect(sfx_player.play_block_hit)

		block_parent.remove_child(block_mesh)

func display_blocks(blocks: Array[BreakableBlock]) -> void:
	for child in block_parent.get_children():
		block_parent.remove_child(child)

	for block: BreakableBlock in blocks:
		block_parent.add_child(block.asset_ref)

		
		

func on_board_clear() -> void:
	# TODO: this resets the ball. shouldn't use death entrypoint for this tho
	on_death()

	context.broken_block_count = 0
	# generate_map()

# func are_breakable_blocks_remaining() -> bool:
# 	return context.broken_block_count >= context.blocks.size() - context.nr_metal_blocks

func collide_with_screen(powerup: Powerup) -> void:
	var grid_unit_size: Vector2 = BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE
	var left: float = -grid_unit_size.x / 2
	var right: float = grid_unit_size.x / 2

	if powerup.position.x < left:
		powerup.position.x += (left - powerup.position.x) * 2
		powerup.velocity.x *= -1

	elif powerup.position.x > right:
		powerup.position.x -= (powerup.position.x - right) * 2
		powerup.velocity.x *= -1

func spawn_powerup(block: BreakableBlock) -> void:
	var powerup: Powerup = block.powerup
	powerup.position = block.get_origin()

	powerup.randomize_velocity()

	# var mesh: MeshInstance3D = MeshInstance3D.new()
	# mesh.mesh = SphereMesh.new()
	# mesh.mesh.radius = 16
	# mesh.mesh.height = 32
	# debug_parent.add_child(mesh)
	var asset: PowerupAsset = powerup_asset_scene.instantiate()
	powerup_parent.add_child(asset)
	asset.set_visuals(powerup)



	powerup.asset = asset

	context.powerups.push_back(powerup)

func spawn_gun_projectiles() -> void:
	var p: Projectile = Projectile.new()
	p.init_type(Projectile.Type.GUN_BULLET)
	p.position = context.paddle.get_left_side()
	var asset: Node3D = gun_bullet_asset_scene.instantiate()
	projectile_parent.add_child(asset)
	p.asset_ref = asset
	context.projectiles.push_back(p)

	p = Projectile.new()
	p.init_type(Projectile.Type.GUN_BULLET)
	p.position = context.paddle.get_right_side()
	p.position -= Vector2(0.001, 0) # otherwie it perfectly misses the blocks on the right sides
	asset = gun_bullet_asset_scene.instantiate()
	projectile_parent.add_child(asset)
	p.asset_ref = asset
	context.projectiles.push_back(p)

func damage_block_and_clear(block: BreakableBlock, damage: int) -> bool:
	if block == null:
		return false

	block.hit_block_dmg(damage)

	if block != null && block.is_broken():
		if block.has_powerup:
			block.has_powerup = false
			spawn_powerup(block)
		
		context.broken_block_count += 1

		block.asset_ref.queue_free()
		context.remove_block(block)

		return true
	
	return false

func convert_blocks_to_ice(pos: Vector2) -> void:
	for block: BreakableBlock in context.get_blocks_for_circle(pos, Powerup.ice_ball_radius):
		# check if block actually collides
		if block.collides_with_circle(pos, Powerup.ice_ball_radius):
			block.type = BreakableBlock.BlockType.ICE
			block.set_visuals()

func explode_blocks(pos: Vector2) -> void:
	for block: BreakableBlock in context.get_blocks_for_circle(pos, Powerup.mine_ball_radius):
		# check if block actually collides
		if block.collides_with_circle(pos, Powerup.mine_ball_radius):
			damage_block_and_clear(block, Powerup.mine_ball_damage)

func outside_screen_bounds(ball: Ball) -> bool:
	if ball.position.x + ball.radius * 2 < context.screen_a.x: return true
	if ball.position.x - ball.radius * 2 > context.screen_b.x: return true

	if ball.position.y < context.screen_a.y - (context.screen_b.y - context.screen_a.y): return true
	if ball.position.y > context.screen_b.y + (context.screen_b.y - context.screen_a.y): return true

	return false
