extends Node



# Called when the node enters the scene tree for the first time.
func _ready():
	var camera = $Camera
	var screen = $upper/Screen
	var texture = camera.get_viewport().get_texture()
	var mat = StandardMaterial3D.new()
	mat.set("albedo_texture", texture)
	 
	screen.material_override = mat
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
