class_name NetworkFSMProcessState
extends StateMachineState

var test = 0

func _input(event):
	pass

# Called when the state machine enters this state.
func on_enter() -> void:
	print("Network Process State entered")


# Called every frame when this state is active.
func on_process(delta: float) -> void:
	get_parent().socket.poll()
	var state = get_parent().socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		# Received packets and process them
		while get_parent().socket.get_available_packet_count():
			get_parent().data_received = JSON.parse_string(get_parent().socket.get_packet().get_string_from_utf8())
			if get_parent().data_received == null:
				print("Error while parsing received string")
			else:
				# Do stuff here
				pass

		# Send current data to send JSON packet every 50ms ish
	elif state == WebSocketPeer.STATE_CLOSING || WebSocketPeer.STATE_CLOSING:
		# Do stuff here
		pass 


# Called every physics frame when this state is active.
func on_physics_process(delta: float) -> void:
	pass


# Called when there is an input event while this state is active.
func on_input(event: InputEvent) -> void:
	pass


# Called when the state machine exits this state.
func on_exit() -> void:
	print("Network Process State left")
