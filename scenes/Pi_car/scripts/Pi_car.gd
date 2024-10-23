extends Node3D

var nfsm = 0
var speed = 0
var turn_speed = 0.5
var capteurs_SL = []
var ACCELERATION = 0.0001
var V_MAX = 0.15

@onready var indicateur_capt1 = $Indicateur_Capteur1
@onready var indicateur_capt2 = $Indicateur_Capteur2
@onready var indicateur_capt3 = $Indicateur_Capteur3
@onready var indicateur_capt4 = $Indicateur_Capteur4
@onready var indicateur_capt5 = $Indicateur_Capteur5

# Called when the node enters the scene tree for the first time.
func _ready():
	nfsm = $"../NetworkFSM"
	capteurs_SL = [false, false, false, false, false]
	print(indicateur_capt1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Process data received here from simulation and RPiCar
	# If websocket connection
	#if nfsm.current_state == $"../NetworkFSM/NetworkProcessState" :
		## Do something here
		#pass
		
	
	
	if Input.is_key_pressed(KEY_W):
		if speed < V_MAX:
			speed += ACCELERATION
	if !Input.is_key_pressed(KEY_W):
		if speed > 0:
			speed -= ACCELERATION
	if Input.is_key_pressed(KEY_S):
		speed = 0
		
	# Rotate left/right
	if Input.is_key_pressed(KEY_A):
		rotate_y(turn_speed * delta)  # Rotate left
	if Input.is_key_pressed(KEY_D):
		rotate_y(-turn_speed * delta)  # Rotate right
		
	if line_detected():
		speed = suivre_ligne(delta, speed)
	translate(Vector3(-delta * speed, 0, 0))
	
	# print("Vitesse courante: %d" % speed)
	

func _physics_process(delta):
	pass
	
func line_detected():
	if capteurs_SL != [false, false, false, false, false]:
		return true
	else:
		return false

func suivre_ligne(delta, speed):
	var new_speed = speed
	if capteurs_SL == [false, false, false, false, false]:
		if speed > 0:
			new_speed = speed - ACCELERATION
		print("Aucun capteur ne détecte la ligne")
	elif capteurs_SL == [false, false, true, false, false]:
		if speed < V_MAX:
			new_speed = speed + ACCELERATION
	elif capteurs_SL == [false, true, true, false, false]:
		rotate_y(0.2 * delta)
	elif capteurs_SL == [false, false, true, true, false]:
		rotate_y(-0.2 * delta)

		
	return new_speed
	

# Fonction utilitaire pour vérifier ce que les capteurs du suiveur de ligne voient
func check_capteurs_SL():
	for i in range(capteurs_SL.size()):
		if capteurs_SL[i] == true:
			print("Capteurs %d detecte la ligne" % (i+1))
		else:
			print("Capteurs %d ne detecte pas la ligne" % (i+1))


func change_color(index, detected):
	var green = Color(0, 1, 0)
	var red = Color(1, 0, 0)
	match index:
		0:
			if detected:
				indicateur_capt1.color = green
			else:
				indicateur_capt1.color = red
		1:
			if detected:
				indicateur_capt2.color = green
			else:
				indicateur_capt2.color = red
		2:
			if detected:
				indicateur_capt3.color = green
			else:
				indicateur_capt3.color = red
		3:
			if detected:
				indicateur_capt4.color = green
			else:
				indicateur_capt4.color = red
		4:
			if detected:
				indicateur_capt5.color = green
			else:
				indicateur_capt5.color = red
	


func _on_capteur_1_area_entered(area):
	if area.name == "Line":
		capteurs_SL[0] = true
		change_color(0, true)


func _on_capteur_1_area_exited(area):
	if area.name == "Line":
		capteurs_SL[0] = false
		change_color(0, false)


func _on_capteur_2_area_entered(area):
	if area.name == "Line":
		capteurs_SL[1] = true
		change_color(1, true)


func _on_capteur_2_area_exited(area):
	if area.name == "Line":
		capteurs_SL[1] = false
		change_color(1, false)


func _on_capteur_3_area_entered(area):
	if area.name == "Line":
		capteurs_SL[2] = true
		change_color(2, true)


func _on_capteur_3_area_exited(area):
	if area.name == "Line":
		capteurs_SL[2] = false
		change_color(2, false)


func _on_capteur_4_area_entered(area):
	if area.name == "Line":
		capteurs_SL[3] = true
		change_color(3, true)


func _on_capteur_4_area_exited(area):
	if area.name == "Line":
		capteurs_SL[3] = false
		change_color(3, false)


func _on_capteur_5_area_entered(area):
	if area.name == "Line":
		capteurs_SL[4] = true
		change_color(4, true)


func _on_capteur_5_area_exited(area):
	if area.name == "Line":
		capteurs_SL[4] = false
		change_color(4, false)

