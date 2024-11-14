extends Node3D

const MovementType = Enums.MovementType
const State = Enums.State
var Movement = load("res://scripts/classes/Movement.gd")
var MovementArray = load("res://scripts/classes/Movement_Array.gd")
var utils = load("res://scenes/Pi_car/scripts/utils.gd").new()

var stuff = 1
signal test_completed
""" EXPLICATION ACCÉLÉRATION
En théorie, l'accélération est sensée être g*h/x où h est la profondeur de la
plaquette et x est le rayon. Cela nous donnerait une accel max de 7.35 m/s^2, 
ce qui est évidemment beaucoup trop. En testant, un facteur de 1/1200 semblait
donné la meilleure valeur d'acceleration.

Il est possible que la boule tombe lors du premier essai d'un parcours, vérifier
que si on relance le test avec "r", la boule tombe toujours.

SI L'ACCÉLÉRATION EST MODIFIÉE, LA VITESSE MAX ET LES VITESSES DE TOURNAGE 
DOIVENT ÊTRE RETESTÉES
""" 
var ACCELERATION = ((9.8*0.0015)/0.02)/2 # 0.0049 m/s^2
""" EXPLICATION V_MAX
La vitesse maximale fut trouvée en vérifiant si le robot pouvait arrêter avec 
l'incertitude de 30mm selon l'accélération trouvée

SI ON MODIFIE CETTE VALEUR, ON DOIT S'ASSURER DE REFAIRE LE TEST D'ARRÊT
""" 
var V_MAX = 0.18 # m/s
""" EXPLICATION V_TURN ET V_TIGHT_TURN
Ces vitesses ont été trouvées en vérifiant si le robot pouvait faire les 
virages du parcours réel

SI ON MODIFIE CES VALEURS, ON DOIT S'ASSURER DE VÉRIFIER LES RÉSULTATS DANS LE 
PARCOURS RÉEL
""" 
var V_TURN = 0.12
var V_TIGHT_TURN = 0.1
const MAX_DISPLACEMENT = 0.2
const ULTRASON_RANGE = 0.1
const BRAKE_RANGE = 0.06
# 1 -> Évitement à gauche ; -1 -> Évitement à droite
const AVOID_SIDE = 1

var nfsm = 0
var speed = 0
var capteurs_SL = []
var state = State.manual_control
var tick_counter = 0
var movement_array: MovementArray = MovementArray.new()
var rotation_value = 0
var initial_rotation = 0
var distance_multiplier = 2

var start_time = 0
var previous_error = 0
var P = 0
var I = 0
var D = 0
var Pvalue = 0
var Ivalue = 0
var Dvalue = 0

var KP = 1
var KI = 0.001
var KD = 0.015
var elapsed_time = 0.0  # Variable pour stocker le temps écoulé

@onready var indicateur_capt1 = $Indicateur_Capteur1
@onready var indicateur_capt2 = $Indicateur_Capteur2
@onready var indicateur_capt3 = $Indicateur_Capteur3
@onready var indicateur_capt4 = $Indicateur_Capteur4
@onready var indicateur_capt5 = $Indicateur_Capteur5
@onready var state_label = $Label_State
@onready var speed_label = $Label_Speed
@onready var time_label = $Label_Time




# Called when the node enters the scene tree for the first time.
func _ready():
	start_time = Time.get_ticks_msec()
	nfsm = $"../NetworkFSM"
	capteurs_SL = [false, false, false, false, false]
	ACCELERATION = Settings.acceleration
	V_MAX = Settings.v_max
	V_TURN = Settings.v_turn * V_MAX
	V_TIGHT_TURN = Settings.v_tight_turn * V_MAX
	KP = Settings.kp
	KI = Settings.ki
	KD = Settings.kd
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _physics_process(delta):
	# Process data received here from simulation and RPiCar
	# If websocket connection
	#if nfsm.current_state == $"../NetworkFSM/NetworkProcessState" :
		## Do something here
		#pass

	var rotation = 0
	var US_distance = 0

	match state:
		State.following_line:
			var result = suivre_ligne(delta, speed)
			speed = result[0]
			state = result[1]
			rotation = result[2]
			
			if Input.is_key_pressed(KEY_SPACE):
				state = State.reverse
			if $RayCast3D.is_colliding():
				US_distance = Vector3(self.position.x, self.position.y, self.position.z).distance_to($RayCast3D.get_collision_point()) + $RayCast3D.position.x
				if US_distance < ULTRASON_RANGE + BRAKE_RANGE:
					rotation_value = 0
					initial_rotation = rotation_value
					$Camera3D.position.x = -0.1
					$Camera3D.position.y = 1
					$Camera3D.rotation.x = -PI/2
					state = State.blocked
			update_state_label()
			
		State.turning_left:
			tick_counter += 1
			if speed > 0.025:
				speed -= ACCELERATION/500 * delta
			rotate_y(-0.30 * delta)
			if tick_counter >= 3000:
				state = State.following_line
				tick_counter = 0
			update_state_label()	
			if !line_detected():
				write_to_log("Valeurs du parcours:\n" + "Acceleration : " + str(ACCELERATION) + "    Vmax : " + str(V_MAX) 
				+ "    Vitesse turn : " + str(Settings.v_turn) + "    Vitesse tight turn : " + str(Settings.v_tight_turn)
				+ "\nLe suiveur de ligne suit pus les lignes   FAIL", "fail")
				#get_tree().quit()
				emit_signal("test_completed")
			
		State.turning_right:
			tick_counter += 1
			if speed > 0.025:
				speed -= ACCELERATION/500 * delta
			rotate_y(0.30 * delta)
			if tick_counter >= 3000:
				state = State.following_line
				tick_counter = 0
			update_state_label()
			if !line_detected():
				write_to_log("Valeurs du parcours:\n" + "Acceleration : " + str(ACCELERATION) + "    Vmax : " + str(V_MAX) 
				+ "    Vitesse turn : " + str(Settings.v_turn) + "    Vitesse tight turn : " + str(Settings.v_tight_turn)
				+ "\nLe suiveur de ligne suit pus les lignes   FAIL", "fail")
				#get_tree().quit()
				emit_signal("test_completed")
			
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
				rotate_y(0.30 * delta)
			if Input.is_key_pressed(KEY_D):
				rotate_y(-0.30 * delta) 
			if Input.is_key_pressed(KEY_SPACE):
				state = State.reverse
				
			update_state_label()
			if line_detected():
				state = State.following_line
			
		State.reverse:
			if speed > 0:
				speed -= ACCELERATION * delta
			else:
				var old_move = movement_array.get_last_move()
				if old_move != null:
					speed = -old_move[0]
					rotation = -old_move[1]
				else:
					if speed < 0:
						speed += ACCELERATION * delta

			update_state_label()
		State.blocked:
			if $RayCast3D.is_colliding():
				US_distance = Vector3(self.position.x, self.position.y, self.position.z).distance_to($RayCast3D.get_collision_point()) + $RayCast3D.position.x
			else:
				US_distance = distance_multiplier*ULTRASON_RANGE
			if US_distance < distance_multiplier*ULTRASON_RANGE:
				if speed > -V_MAX:
					speed -= 0.5*ACCELERATION * delta
			else:
				if speed < V_MAX:
					speed += ACCELERATION * delta
				if abs(rotation_value) < abs(initial_rotation) + 3*PI/8:
					rotation = AVOID_SIDE*0.75
				else:
					distance_multiplier = 3
					state = State.avoiding
			update_state_label()
			
		State.avoiding:
			rotation = -AVOID_SIDE*0.5
			if $RayCast3D.is_colliding():
				US_distance = Vector3(self.position.x, self.position.y, self.position.z).distance_to($RayCast3D.get_collision_point()) + $RayCast3D.position.x
				if US_distance < distance_multiplier*ULTRASON_RANGE:
					rotation = 0
					initial_rotation = rotation_value
					state = State.blocked
			elif capteurs_SL[0] or capteurs_SL[1] or capteurs_SL[2] or capteurs_SL[3] or capteurs_SL[4]:
				distance_multiplier = 2
				$Camera3D.position.x = 0.472
				$Camera3D.position.y = 0.225
				$Camera3D.rotation.x = -PI/6
				state = State.recovering
			elif AVOID_SIDE*rotation_value <= 0 && AVOID_SIDE*rotation_value > -PI/4:
				rotation = -AVOID_SIDE*0.75
			elif AVOID_SIDE*rotation_value <= -PI/4:
				rotation = 0
			update_state_label()
		State.recovering:
			rotation = AVOID_SIDE*0.3
			if (AVOID_SIDE*rotation_value <= 0 && AVOID_SIDE*rotation_value > -PI/8 and 
			(capteurs_SL == [false, true, true, false, false] or capteurs_SL == [false, false, true, true, false])):
				rotation = 0
				state = State.following_line
			update_state_label()
			
		State.finished:
			if speed > 0:
				speed -= ACCELERATION * delta
			update_state_label()

	rotation_value += rotation * delta
	rotate_y(rotation * delta)
	translate(Vector3(-delta * speed, 0, 0))
	update_speed_label()
	
	if state != State.reverse && speed > 0:
		if rotation == 0:
			var movement = Movement.new(speed, (delta * speed), MovementType.translation, rotation)
			movement_array.add_move(movement)
		else:
			var movement = Movement.new(speed, (delta * speed), MovementType.rotation, rotation)
			movement_array.add_move(movement)
		
	# print("Vitesse courante: %f" % speed)
	print("Rotation courante: %f" % rotation)
	
	if state == State.finished:
		time_label.text = "Final time: %.2f secondes" % elapsed_time
	else:
		elapsed_time += delta
		time_label.text = "Time: %.2f secondes" % elapsed_time
	
func read_line(sensors):
	var on_line: bool = false
	var avg: float = 0
	var sum: int = 0
	
	for i in range(len(sensors)):
		if sensors[i] == true:
			on_line = true
			avg += i * 25
			sum += 1
			
	var last_position = avg / sum
	
	if not on_line:
		if last_position < (len(sensors) - 1) * 25 / 2:
			return 0
		else:
			return (len(sensors) - 1) * 25
	
	return avg / sum if sum > 0 else 0

func robot_control(sensors):
	var position = read_line(sensors)
	var error = 2000 - position
	var rotation = 0
	
	while !line_detected():
		if previous_error > 0:
			rotation = -deg_to_rad(10)
		else:
			rotation = deg_to_rad(10)
		position = read_line(sensors)
		
	PID_Linefollow(error)

func PID_Linefollow(error):
	P = error
	I = I + error
	D = error - previous_error
	
	Pvalue = KP*P
	Ivalue = KI*I
	Dvalue = KD*D
	
	var PID_value = Pvalue + Ivalue + Dvalue
	previous_error = error
	PID_value = deg_to_rad(PID_value)
	PID_value = clamp(PID_value, -deg_to_rad(45), deg_to_rad(45))
	
	return PID_value


func update_speed_label():
	speed_label.text = "Vitesse: %.3f m/s" % speed

	
func update_state_label():
	state_label.text = utils.set_state_text(state)
	
	
func calculate_actual_speed(translation, delta):
	return translation/delta
	
	
func line_detected():
	if capteurs_SL != [false, false, false, false, false]:
		return true
	else:
		return false
		
func suivre_ligne(delta, speed):
	var position = read_line(capteurs_SL)
	var error = 50 - position
	var PID_output = PID_Linefollow(error)
	print("error: %d" % error)
	print("PID output: %f" % PID_output)

	var new_speed = speed
	var new_state = State.following_line
	var new_rotation = PID_output
	
	if capteurs_SL == [true, true, true, true, true]:
		if speed > 0:
			new_speed -= ACCELERATION * delta
		new_state = State.finished
	

	if capteurs_SL == [false, false, false, false, false]:
		if speed > 0:
			new_speed -= ACCELERATION * delta
			write_to_log("Error: Line lost")
			emit_signal("test_completed")
	else:
		if speed < V_MAX:
			new_speed += ACCELERATION * delta
		if PID_output > 0:
			new_rotation = min(PID_output, deg_to_rad(45))
			if PID_output > deg_to_rad(10):
				if speed > V_TURN:
					new_speed -= ACCELERATION/1.5 * delta
			if PID_output > deg_to_rad(30):
				if speed > V_TIGHT_TURN:
					new_speed -= ACCELERATION/1.5 * delta
		else:
			new_rotation = max(PID_output, -deg_to_rad(45))
			if PID_output < -deg_to_rad(10):
				if speed > V_TURN:
					new_speed -= ACCELERATION/1.5 * delta
			if PID_output < -deg_to_rad(30):
				if speed > V_TIGHT_TURN:
					new_speed -= ACCELERATION/1.5 * delta

	print("New speed: %f, new rotation: %f" % [new_speed, rad_to_deg(new_rotation)])
	return [new_speed, new_state, new_rotation]


func change_color(index, detected, too_far=false):
	var green = Color(0, 1, 0)
	var red = Color(1, 0, 0)
	var pink = Color(1, 0.5, 0.8)
	match index:
		0:
			if detected:
				indicateur_capt1.color = green
			else:
				indicateur_capt1.color = red
			if too_far:
				indicateur_capt1.color = pink
		1:
			if detected:
				indicateur_capt2.color = green
			else:
				indicateur_capt2.color = red
			if too_far:
				indicateur_capt2.color = pink
		2:
			if detected:
				indicateur_capt3.color = green
			else:
				indicateur_capt3.color = red
			if too_far:
				indicateur_capt3.color = pink
		3:
			if detected:
				indicateur_capt4.color = green
			else:
				indicateur_capt4.color = red
			if too_far:
				indicateur_capt4.color = pink
		4:
			if detected:
				indicateur_capt5.color = green
			else:
				indicateur_capt5.color = red
			if too_far:
				indicateur_capt5.color = pink
	

func _on_capteur_1_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[4] = true
		change_color(0, true)
	if area.name == "TOO_FAR":
		change_color(0, true, true)


func _on_capteur_1_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[4] = false
		change_color(0, false)
	

func _on_capteur_2_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[3] = true
		change_color(1, true)
	if area.name == "TOO_FAR":
		change_color(1, true, true)


func _on_capteur_2_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[3] = false
		change_color(1, false)


func _on_capteur_3_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[2] = true
		change_color(2, true)
	if area.name == "TOO_FAR":
		change_color(2, true, true)


func _on_capteur_3_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[2] = false
		change_color(2, false)


func _on_capteur_4_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[1] = true
		change_color(3, true)
	if area.name == "TOO_FAR":
		change_color(3, true, true)


func _on_capteur_4_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[1] = false
		change_color(3, false)


func _on_capteur_5_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[0] = true
		change_color(4, true)
	if area.name == "TOO_FAR":
		change_color(4, true, true)


func _on_capteur_5_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[0] = false
		change_color(4, false)
		
func _on_capteur_fin_area_entered(area):
	if area.name.begins_with("Finish"):
		print("entered the right tings")
		
		var end_time = Time.get_ticks_msec()
		var elapsed_time = (end_time - start_time) / 1000.0
		write_to_log("Valeurs du parcours:\n" + "Acceleration : " + str(ACCELERATION) + "    Vmax : " + str(V_MAX) 
		+ "    Vitesse turn : " + str(Settings.v_turn) + "    Vitesse tight turn : " + str(Settings.v_tight_turn) 
		+ "\nTime taken: " + str(elapsed_time) + " seconds")
		emit_signal("test_completed")
		
func write_to_log(message: String, filename="success"):
	var today_date = Time.get_date_string_from_system()  # Format: "YYYY-MM-DD"
	var path = "res://log/" + filename + "_" + today_date + ".txt"

	# Check if the file exists, and create it if it doesn't
	if !FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.close()

	var file = FileAccess.open(path, FileAccess.READ_WRITE)
	file.seek_end()  # Move to the end for appending

	var dt = Time.get_time_string_from_system()
	file.store_string(dt + "\n" + message + "\n\n")

	file = null
		
	
	

func _on_boule_fell_capteur_body_entered(body):
	if body.name == "Boule":
		write_to_log("Valeurs du parcours:\n" + "Acceleration : " + str(ACCELERATION) + "    Vmax : " + str(V_MAX) 
		+ "    Vitesse turn : " + str(Settings.v_turn) + "    Vitesse tight turn : " + str(V_TIGHT_TURN)
		+ "\nLa boule a dip  FAIL", "fail")
		#get_tree().quit()
		emit_signal("test_completed")
		# Handle the fall, such as resetting the ball position or ending the simulation
