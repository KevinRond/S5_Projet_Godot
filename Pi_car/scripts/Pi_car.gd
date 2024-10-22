extends Node3D

var nfsm = 0
var speed = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	nfsm = $"../NetworkFSM"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Process data received here from simulation and RPiCar
	# If websocket connection
	#if nfsm.current_state == $"../NetworkFSM/NetworkProcessState" :
		## Do something here
		#pass
	
	if Input.is_key_pressed(KEY_W):
		speed = 0.1
	if Input.is_key_pressed(KEY_S):
		speed = 0
	translate(Vector3(-delta * speed, 0, 0))

func _physics_process(delta):
	pass
