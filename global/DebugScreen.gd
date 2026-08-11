extends Node

var debug_layer: DebugScreenLayer

var strings: Array[Callable]

var debug_visuals: Array[DebugVisual]

var VISUAL_DEBUG: bool = false

func _enter_tree() -> void:
	if Global.DEBUG:
		debug_layer = load("res://global/DebugScreenLayer.tscn").instantiate()
		get_tree().root.add_child.call_deferred(debug_layer)
	
	# debug_layer.ready.connect(func() -> void:
	# 	process_mode = Node.PROCESS_MODE_INHERIT
	# )

	# process_mode = Node.PROCESS_MODE_DISABLED

func _ready() -> void:
	debug_layer.visible = Global.DEBUG
	DebugDraw3D.scoped_config().set_thickness(2)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_screen"):
		debug_layer.visible = !debug_layer.visible
	if Input.is_action_just_pressed("debug_visuals"):
		VISUAL_DEBUG = !VISUAL_DEBUG



	if !Global.DEBUG || !debug_layer.visible:
		return
	

	var final: String = ""
	for string in strings:
		final += string.call() + "\n"
	
	debug_layer.set_text(final)


	
func add_debug_line(debug: Callable) -> void:
	strings.push_back(debug)

func draw_debug_visuals() -> void:
	for visual in debug_visuals:
		visual.draw_debug()