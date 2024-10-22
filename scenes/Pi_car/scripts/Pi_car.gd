extends Node3D

var nfsm = 0
var speed = 0
var capteurs_SL = []

func check_capteurs_SL():
	for i in range(capteurs_SL.size()):
		if capteurs_SL[i] == true:
			print("Capteurs %d detecte la ligne" % (i+1))
		else:
			print("Capteurs %d ne detecte pas la ligne" % (i+1))

# Called when the node enters the scene tree for the first time.
func _ready():
	nfsm = $"../NetworkFSM"
	capteurs_SL = [false, false, false, false, false]


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
	
	# Loop pour debug les capteurs
	check_capteurs_SL()

func _physics_process(delta):
	pass


func _on_capteur_1_area_entered(area):
	if area.name == "Line":
		capteurs_SL[0] = true


func _on_capteur_1_area_exited(area):
	if area.name == "Line":
		capteurs_SL[0] = false


func _on_capteur_2_area_entered(area):
	if area.name == "Line":
		capteurs_SL[1] = true


func _on_capteur_2_area_exited(area):
	if area.name == "Line":
		capteurs_SL[1] = false


func _on_capteur_3_area_entered(area):
	if area.name == "Line":
		capteurs_SL[2] = true


func _on_capteur_3_area_exited(area):
	if area.name == "Line":
		capteurs_SL[2] = false


func _on_capteur_4_area_entered(area):
	if area.name == "Line":
		capteurs_SL[3] = true


func _on_capteur_4_area_exited(area):
	if area.name == "Line":
		capteurs_SL[3] = false


func _on_capteur_5_area_entered(area):
	if area.name == "Line":
		capteurs_SL[4] = true


func _on_capteur_5_area_exited(area):
	if area.name == "Line":
		capteurs_SL[4] = false

