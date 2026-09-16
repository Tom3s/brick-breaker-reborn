@tool
extends EditorScript
# extends Node

var texture_path: String = "res://raw_assets/textures/powerups"
var final_path: String = "res://visuals/textures/powerups/"

func _ready() -> void:
	_run()

func _run() -> void:
	var dir: DirAccess = DirAccess.open(texture_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			# print("Found file: " + file_name)
			if !file_name.ends_with(".png"): 
				file_name = dir.get_next()
				continue
			
			# Comment out to redo all files
			# will skip those textures, that are already processed
			if FileAccess.file_exists(final_path + file_name):
				file_name = dir.get_next()
				continue

			convert_texture_to_sdf(file_name)

			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

const NR_PASSES: int = 4

func convert_texture_to_sdf(file_name: String) -> void:
	LoggerMogyi.log(null, "Converting %s to SDF" % file_name)
	var texture_name: String = texture_path + "/" + file_name
	
	var bw_image: Image = Image.load_from_file(texture_name)
	# bw_image.save_png(final_path + file_name)
	var outside_pass: Image = bw_image.duplicate()
	var inside_pass: Image = bw_image.duplicate()
	for x in outside_pass.get_size().x:
		for y in outside_pass.get_size().y:
			if outside_pass.get_pixel(x, y).r < 0.5:
				outside_pass.set_pixel(x, y, Color.BLACK)
				inside_pass.set_pixel(x, y, Color8(x, y, 0))
			else:
				outside_pass.set_pixel(x, y, Color8(x, y, 0))
				inside_pass.set_pixel(x, y, Color.BLACK)
	

	
	outside_pass = jump_flood(outside_pass)
	inside_pass = jump_flood(inside_pass)
	
	for x in outside_pass.get_size().x:
		for y in outside_pass.get_size().y:
			var curr_outside: Color = outside_pass.get_pixel(x, y)
			var curr_inside: Color = inside_pass.get_pixel(x, y)
			var dist_outside: float = get_distance(x, y, curr_outside)
			var dist_inside: float = get_distance(x, y, curr_inside)


			# print(dist)

			if bw_image.get_pixel(x, y).r < 0.5: # black
				if dist_outside == 99999:
					bw_image.set_pixel(x, y, Color.BLACK)
					continue
				var remapped: int = int(remap(dist_outside, 1, MAX_DIST, 128, 0))
				bw_image.set_pixel(x, y, Color8(remapped, remapped, remapped))
			else:
				if dist_inside == 99999:
					bw_image.set_pixel(x, y, Color.WHITE)
					continue
				var remapped: int = int(remap(dist_inside, 0, MAX_DIST, 128, 255))
				bw_image.set_pixel(x, y, Color8(remapped, remapped, remapped))
				

			# if remapped != 0:
			# 	print(remapped)


	LoggerMogyi.log(null, "Done converting %s to SDF" % file_name)
	
	bw_image.save_png(final_path + file_name)

var MAX_DIST: float = -1

func get_distance(x: int, y: int, c: Color) -> float:
	if c.r8 == 0 && c.g8 == 0: return 99999 # large

	var to_x: int = c.r8
	var to_y: int = c.g8

	var dist: float = Vector2i(x, y).distance_to(Vector2i(to_x, to_y))

	# keep track of max distance smh
	MAX_DIST = max(MAX_DIST, dist)

	return dist

func jump_flood(last_pass: Image) -> Image:
	var passes: Array[int]
	for i in NR_PASSES:
		passes.append(int(pow(2, i)))
	passes.reverse()

	var new_pass: Image = last_pass.duplicate()

	for offset in passes:
		for y in last_pass.get_size().y:
			for x in last_pass.get_size().x:
				if x == 0 && y == 0: continue

				var left: Color = Color8(0, 0, 255)
				var right: Color = Color8(0, 0, 255)
				var current: Color = last_pass.get_pixel(x, y)
				if x >= offset:
					left = last_pass.get_pixel(x - offset, y)
				if x + offset < last_pass.get_size().x:
					right = last_pass.get_pixel(x + offset, y)
				
				new_pass.set_pixel(x, y, current)
				if get_distance(x, y, left) < get_distance(x, y, current):
					new_pass.set_pixel(x, y, left)
				elif get_distance(x, y, right) < get_distance(x, y, current):
					new_pass.set_pixel(x, y, right)
		
		last_pass = new_pass.duplicate()
		
		for x in last_pass.get_size().x:
			for y in last_pass.get_size().y:
				if x == 0 && y == 0: continue

				var up: Color = Color8(0, 0, 255)
				var down: Color = Color8(0, 0, 255)
				var current: Color = last_pass.get_pixel(x, y)
				if y >= offset:
					up = last_pass.get_pixel(x, y - offset)
				if y + offset < last_pass.get_size().y:
					down = last_pass.get_pixel(x, y + offset)
				
				new_pass.set_pixel(x, y, current)
				if get_distance(x, y, up) < get_distance(x, y, current):
					new_pass.set_pixel(x, y, up)
				elif get_distance(x, y, down) < get_distance(x, y, current):
					new_pass.set_pixel(x, y, down)
		
		last_pass = new_pass.duplicate()
	
	return last_pass