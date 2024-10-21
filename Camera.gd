extends Camera3D

var sensitivity = 0.3  # Sensibilité de la souris
var rotation_x = 0.0   # Rotation en X (haut/bas)
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


var speed = 5.0  # Vitesse de déplacement

func _process(delta):
	# Clamp the rotation in X (up/down) to avoid flipping
	rotation.x = clamp(rotation.x, -1, 1)
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate(Vector3.UP, -event.relative.x*0.001)
		rotate_object_local(Vector3.RIGHT, -event.relative.y*0.001)
