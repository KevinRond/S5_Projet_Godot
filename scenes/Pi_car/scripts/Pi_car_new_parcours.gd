extends Node3D

var nfsm = 0
var speed = 0
var turn_speed = 1
var capteurs_SL = []
var ACCELERATION = 0.08 #((9.8*0.0018)/0.002)/1500 # 0.0049 m/s^2
var V_MAX = 0.15
var state = State.manual_control
var tick_counter = 0

enum State { manual_control, following_line, turning_left, turning_right, tight_left_turn, tight_right_turn, no_line, line_end }

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

	match state:
		State.following_line:
			var result = suivre_ligne(delta, speed)
			speed = result[0]
			state = result[1]
		State.turning_left:
			tick_counter += 1
			if speed > 0:
				speed -= ACCELERATION * delta
			rotate_y(-turn_speed * delta)
			if capteurs_SL[2] == true:
				state = State.following_line
				tick_counter = 0
			if tick_counter >= 2000:
				state = State.following_line
				tick_counter = 0
		State.turning_right:
			tick_counter += 1
			if speed > 0:
				speed -= ACCELERATION * delta
			rotate_y(turn_speed * delta)
			if capteurs_SL[2] == true:
				state = State.following_line
				tick_counter = 0
			if tick_counter >= 500:
				state = State.following_line
				tick_counter = 0
				
		State.tight_right_turn:
			if capteurs_SL == [true, true, true, true, true]:
				if speed > 0:
					speed -= ACCELERATION * delta
					state = State.line_end
			rotate_y(-turn_speed*delta)
			if capteurs_SL[1] == true or capteurs_SL[2] == true or capteurs_SL[3] == true or capteurs_SL[4] == true:
				state = State.following_line
			if speed > 0:
				speed -= ACCELERATION * delta
			if capteurs_SL == [false, false, false, false, false]:
				speed-= ACCELERATION * delta
				rotate_y(-1.5*turn_speed*delta)
			
				
		State.tight_left_turn:
			if capteurs_SL == [true, true, true, true, true]:
				if speed > 0:
					speed -= ACCELERATION * delta
					state = State.line_end
			rotate_y(turn_speed*delta)
			if capteurs_SL[0] == true or capteurs_SL[1] == true or capteurs_SL[2] == true or capteurs_SL[3] == true:
				state = State.following_line
			if speed > 0:
				speed -= ACCELERATION * delta
			if capteurs_SL == [false, false, false, false, false]:
				speed-= ACCELERATION * delta
				rotate_y(1.5*turn_speed*delta)
			
		
		State.no_line:
			if capteurs_SL == [true, true, true, true, true]:
				if speed > 0:
					speed -= ACCELERATION * delta
					state = State.line_end
			if capteurs_SL == [false, false, false, false, false]:
				speed-= ACCELERATION * delta
			elif capteurs_SL[0] == true or capteurs_SL[1]:
				state = State.tight_right_turn
			elif capteurs_SL[3] == true or capteurs_SL[4]:
				state = State.tight_left_turn
			else:
				state = State.following_line
				
		State.line_end:
			if speed > 0:
				speed -= ACCELERATION * delta
			state = State.line_end
		
		State.manual_control:
			if Input.is_key_pressed(KEY_W):
				if speed < V_MAX:
					speed += ACCELERATION *2
			if !Input.is_key_pressed(KEY_W):
				if speed > 0:
					speed -= ACCELERATION*2
			if Input.is_key_pressed(KEY_S):
				speed = 0
				
			# Rotate left/right
			if Input.is_key_pressed(KEY_A):
				rotate_y(turn_speed * delta)
			if Input.is_key_pressed(KEY_D):
				rotate_y(-turn_speed * delta) 
				
			if line_detected():
				state = State.following_line
			
	translate(Vector3(-delta * speed, 0, 0))

	# print("Vitesse courante: %f" % speed)
	

func _physics_process(delta):
	pass
	
func line_detected():
	if capteurs_SL != [false, false, false, false, false]:
		return true
	else:
		return false

func oldddddd_suivre_ligne(delta, speed):
	var new_speed = speed
	var new_state = State.following_line
	if capteurs_SL == [false, false, false, false, false]:
		if speed > 0:
			new_speed -= ACCELERATION
		new_state = State.manual_control
	elif capteurs_SL == [false, false, true, false, false]:
		if speed < V_MAX:
			new_speed += ACCELERATION
	elif capteurs_SL == [false, true, true, false, false]:
		rotate_y(-0.1 * delta)
		if speed < V_MAX:
			new_speed += ACCELERATION
	elif capteurs_SL == [false, false, true, true, false]:
		rotate_y(0.1 * delta)
		if speed < V_MAX:
			new_speed += ACCELERATION
	elif capteurs_SL == [false, true, false, false, false]:
		rotate_y(-0.2 * delta)
		if speed < V_MAX:
			new_speed += ACCELERATION
	elif capteurs_SL == [false, false, false, true, false]:
		rotate_y(0.2 * delta)
		if speed < V_MAX:
			new_speed += ACCELERATION
	elif capteurs_SL == [true, true, false, false, false]:
		rotate_y(-0.3 * delta)
		if speed < V_MAX:
			new_speed += ACCELERATION
	elif capteurs_SL == [false, false, false, true, true]:
		rotate_y(0.3 * delta)
		if speed < V_MAX:
			new_speed += ACCELERATION
	elif capteurs_SL == [true, false, false, false, false]: #tight right turn
		if speed > 0.05:
			new_speed -= ACCELERATION
		rotate_y(-turn_speed * delta)
	elif capteurs_SL == [false, false, false, false, true]: #tight left turn
		rotate_y(turn_speed * delta)
		if speed < V_MAX:
			new_speed += ACCELERATION
	elif capteurs_SL == [true, true, true, false, false] or capteurs_SL == [true, true, true, true, false] or capteurs_SL == [true, true, false, true, false]:
		rotate_y(-5 * delta)  # Left turn
		if speed > 0:
			new_speed -= ACCELERATION
		new_state = State.turning_left
	elif capteurs_SL == [false, false, true, true, true] or capteurs_SL == [false, true, true, true, true] or capteurs_SL == [false, true, false, true, true]:
		rotate_y(5 * delta)  # Right turn
		print("yoooooooooooooooooooooooooooooooooooo")
		if speed > 0:
			new_speed -= ACCELERATION
		new_state = State.turning_right
	else:
		new_speed -= ACCELERATION

	return [new_speed, new_state] 
	
func suivre_ligne(delta, speed):
	var new_speed = speed
	var new_state = State.following_line
	if capteurs_SL[2] == true: #Juste milieu (accelere)
		if speed < V_MAX:
			new_speed += ACCELERATION * delta
	elif capteurs_SL[1] == true: #Milieu droit voit ligne, tite rotation vers la droite
		rotate_y(-0.1 * delta)
		if speed < V_MAX:
			new_speed += ACCELERATION * delta
	elif capteurs_SL[3] == true: #Milieu gauche voit ligne, tite rotation a gauche
		rotate_y(0.1 * delta)
		if speed < V_MAX:
			new_speed += ACCELERATION * delta
	elif capteurs_SL == [true, false, false, false, false]: #Extremite droite seule voit ligne, rentre dans tight left turn
		rotate_y(-0.2 * delta)
		if speed > 0:
			new_speed -= ACCELERATION * delta
		new_state=State.tight_right_turn
	elif capteurs_SL == [false, false, false, false, true]: #extremite gauche seule voit ligne, tight left turn
		rotate_y(0.2 * delta)
		if speed > 0:
			new_speed -= ACCELERATION * delta
		new_state=State.tight_left_turn
	elif capteurs_SL == [false, false, false, false, false]:
		new_state = State.no_line
	
	elif capteurs_SL == [true, true, true, true, true]:
		if speed > 0:
			new_speed -= ACCELERATION * delta
			new_state = State.line_end
		
	else:
		new_state = State.manual_control

	return [new_speed, new_state] 

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
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[0] = true
		change_color(0, true)


func _on_capteur_1_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[0] = false
		change_color(0, false)

func _on_capteur_2_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[1] = true
		change_color(1, true)


func _on_capteur_2_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[1] = false
		change_color(1, false)


func _on_capteur_3_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[2] = true
		change_color(2, true)


func _on_capteur_3_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[2] = false
		change_color(2, false)


func _on_capteur_4_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[3] = true
		change_color(3, true)


func _on_capteur_4_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[3] = false
		change_color(3, false)


func _on_capteur_5_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[4] = true
		change_color(4, true)
		print(capteurs_SL)


func _on_capteur_5_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[4] = false
		change_color(4, false)
		
func _on_capteur_fin_area_entered(area):
	if area.name.begins_with("Finish"):
		get_tree().quit()

