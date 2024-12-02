const State = Enums.State

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
		State.tight_right_turn:
			state_text = "Tight Right Turn"
		State.tight_left_turn:
			state_text = "Tight Left Turn"
		_:
			state_text = "Unknown State"
	
	return "Current PiCar State: %s" % state_text  # Converts the state enum to string
	
func line_detected(sensor_array):
	return sensor_array != [false, false, false, false, false]
		
func finish_line_detected(sensor_array):
	var sum = 0
	for sensor in sensor_array:
		if sensor:
			sum += 1
	return sum >= 3
	
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
