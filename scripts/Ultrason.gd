extends Node3D

var nfsm = 0
var speed = 0
var rot = 0
var range = 1
var state = "stop"

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
		state = "move"
		print(state)
	if Input.is_key_pressed(KEY_S):
		speed = 0
		state = "stop"
		print(state)
	
	# Movement and rotation of the car
	translate(Vector3(-delta * speed,0,0))
	rotate(Vector3(0,1,0), delta * rot)
	
	# Raycast line for debug
	DrawLine3d.DrawRay(self.position, Vector3(-range*cos(self.rotation.y),0,range*sin(self.rotation.y)),Color(0,0,1), delta)
	pass

func _physics_process(delta):
	# Raycast collision system
	if $RayCast3D.is_colliding() and state == "move":
		speed = 0.5
		rot = 1
		state = "block"
		print(state)
	elif !$RayCast3D.is_colliding() and state == "block" and self.rotation.y > PI/2:
		rot = -1
		state = "avoid"
		print(state)
	elif state == "avoid" and self.rotation.y < -PI/2:
		rot = 1
		state = "recover"
		print(state)
	elif state == "recover" and self.rotation.y > 0:
		speed = 1
		rot = 0
		self.rotation.y = 0
		state = "move"
		print(state)
	pass
