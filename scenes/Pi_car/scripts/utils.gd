const State = Enums.State
# Taille du buffer temporel (1 seconde de données, à raison de 10 mises à jour par seconde)
const SENSOR_HISTORY_SIZE = 10

# Historique des capteurs
var sensor_history = []


func set_state_text(state):
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
		State.reverse:
			state_text = "Reverse"
		State.blocked:
			state_text = "Blocked"
		State.avoiding:
			state_text = "Avoiding"
		State.recovering:
			state_text = "Recovering"
		State.finished:
			state_text = "Finished"
		State.find_line:
			state_text = "Finding Line"
		State.stopping:
			state_text = "Stopping"
		State.waiting:
			state_text = "Waiting"
		_:
			state_text = "Unknown State"
	
	return "Current PiCar State: %s" % state_text  # Converts the state enum to string
	
func line_detected(sensor_array):
	return sensor_array != [false, false, false, false, false]
		
# Fonction pour mettre à jour l'historique des capteurs
func update_sensor_history(sensor_array):
	if len(sensor_history) >= SENSOR_HISTORY_SIZE:
		# Supprimer les données les plus anciennes si le buffer est plein
		sensor_history.pop_front()
	sensor_history.append(sensor_array)
# Vérifie si au moins 5 "1" différents ont été détectés dans l'historique
func finish_line_detected():
	var count = 0
	for i in range(SENSOR_HISTORY_SIZE):
		if i == 0 or not sensor_history[i] == sensor_history[i - 1]:
			# Compare avec la valeur précédente pour détecter les changements
			count += sensor_history[i].count(true)
		if count >= 5:
			return true
	return false
	
func FIN_FINAL(sensor_array):
	var sum = 0
	for sensor in sensor_array:
		if sensor:
			sum += 1
	return sum >= 2
	
func make_fake_sensor_data():
	var SL = []
	for i in range(5):
		SL.append(randi() % 2 == 0)
	var distance = randf() * 150
	
	var data = {
		"lt_status": SL,
		"us_output": distance,
	}
	return JSON.stringify(data)
	
func make_json_instructions(new_speed, new_rotation):
	var json = {
		"speed": new_speed,
		"rotation": new_rotation,
	}

	return JSON.stringify(json)

func check_center_sensors(sensor_array):
	var center_sensors = [sensor_array[1], sensor_array[2], sensor_array[3]]
	for sensor in center_sensors:
		if sensor == true:
			return true
	return false
