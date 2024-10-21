extends Node3D

var nfsm = 0
var speed = 0
var range = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	nfsm = $"../NetworkFSM"
	$RayCast3D.scale = Vector3(range, range, range)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Process data received here from simulation and RPiCar
	# If websocket connection
	if nfsm.current_state == $"../NetworkFSM/NetworkProcessState" :
		# Do something here
		print("Hey do something here :)")
		
	# Car movement toggle
	if Input.is_key_pressed(KEY_W):
		speed = 1
	if Input.is_key_pressed(KEY_S):
		speed = 0
		
	translate(Vector3(-delta * speed,0,0))
	DrawLine3d.DrawRay(self.position, Vector3(-range,0,0),Color(0,0,1), delta)
	pass

func _physics_process(delta):
	# Raycast collision system
	if $RayCast3D.is_colliding():
		print("Hey yo dont touch me")
	pass
