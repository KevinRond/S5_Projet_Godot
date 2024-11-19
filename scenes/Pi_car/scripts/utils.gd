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
		_:
			state_text = "Unknown State"
	
	return "Current PiCar State: %s" % state_text  # Converts the state enum to string
	
