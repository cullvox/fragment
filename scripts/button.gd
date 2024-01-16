extends Interact

@onready var player = $AnimationPlayer

func _ready():
	pass

func _process(delta):
	pass

func _on_interact():
	player.play("press")

