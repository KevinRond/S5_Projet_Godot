extends Node3D

var nfsm = 0
var speed = 0
var turn_speed = 0.75
var capteurs_SL = []
var ACCELERATION = ((9.8*0.0015)/0.002)/1000 # 0.00735 m/s^2
var V_MAX = 0.15 # m/s
var state = State.manual_control
var tick_counter = 0

enum State { manual_control, following_line, turning_left, turning_right }

@onready var indicateur_capt1 = $Indicateur_Capteur1
@onready var indicateur_capt2 = $Indicateur_Capteur2
@onready var indicateur_capt3 = $Indicateur_Capteur3
@onready var indicateur_capt4 = $Indicateur_Capteur4
@onready var indicateur_capt5 = $Indicateur_Capteur5
@onready var state_label = $Label_State

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

	match state:
		State.following_line:
			var result = suivre_ligne(delta, speed)
			speed = result[0]
			state = result[1]
			update_state_label()
		State.turning_left:
			tick_counter += 1
			if speed > 0.025:
				speed -= ACCELERATION/500
			rotate_y(-turn_speed * delta)
			if tick_counter >= 3000:
				state = State.following_line
				tick_counter = 0
			update_state_label()	
		State.turning_right:
			tick_counter += 1
			if speed > 0.025:
				speed -= ACCELERATION/500
			rotate_y(turn_speed * delta)
			if tick_counter >= 3000:
				state = State.following_line
				tick_counter = 0
			update_state_label()
		State.manual_control:
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
				rotate_y(turn_speed * delta)
			if Input.is_key_pressed(KEY_D):
				rotate_y(-turn_speed * delta) 
				
			update_state_label()
			if line_detected():
				state = State.following_line
			
	translate(Vector3(-delta * speed, 0, 0))

	# print("Vitesse courante: %f" % speed)
	

func _physics_process(delta):
	pass
	
func update_state_label():
	var state_text
	match state:
		State.manual_control:
			state_text = "Manual Control"
		State.following_line:
			state_text = "Following Line"
		State.turning_left:
			state_text = "Turning Left"
		State.turning_right:
			state_text = "Turning Right"
		_:
			state_text = "Unknown State"
	
	state_label.text = "Current PiCar State: %s" % state_text  # Converts the state enum to string
	
func calculate_actual_speed(translation, delta):
	return translation/delta
	
func line_detected():
	if capteurs_SL != [false, false, false, false, false]:
		return true
	else:
		return false

func suivre_ligne(delta, speed):
	var new_speed = speed
	var new_state = State.following_line
	print("plz")
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
	elif capteurs_SL == [true, false, false, false, false]:
		rotate_y(-0.4 * delta)
		if speed < V_MAX:
			new_speed += ACCELERATION
	elif capteurs_SL == [false, false, false, false, true]:
		rotate_y(0.4 * delta)
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
		if speed < V_MAX:
			new_speed += ACCELERATION

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

