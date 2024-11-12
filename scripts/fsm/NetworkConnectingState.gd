class_name NetworkFSMConnectingState
extends StateMachineState


# Called when the state machine enters this state.
func on_enter() -> void:
	print("Network Connecting State entered")
	var err = get_parent().socket.connect_to_url("wss://localhost:8765")
	if err != OK:
		print("Failed to connect to web sock 0_0")
	# You should connect to the websocket server here. With the socket variable of NetworkFSM
	get_parent().socket.connect("connection_closed", self, "_on_connection_closed")
	get_parent().socket.connect("connection_error", self, "_on_connection_error")
	get_parent().socket.connect("data_received", self, "_on_data_received")

# Called every frame when this state is active.
func on_process(delta: float) -> void:
	get_parent().socket.poll()
	
	while get_parent().socket.get_available_packet_count() > 0:
		var msg = get_parent().socket.get_packet().get_string_from_utf8()
		print("Polling received data: ", msg)  # Print the received message
		
		# Optionally, parse and print it as JSON
		var parsed_data = JSON.parse_string(msg)
		if parsed_data is Dictionary:
			print("Parsed data: ", parsed_data)
		else:
			print("Failed to parse data.")
	var state = get_parent().socket.get_ready_state()
	if state == WebSocketPeer.STATE_CONNECTING:
		# Could be nice to have a blinker showing thats it's trying to connect?
		pass
	elif state == WebSocketPeer.STATE_OPEN:
		# Do stuff here
		pass
	
	elif state == WebSocketPeer.STATE_CLOSED || state == WebSocketPeer.STATE_CLOSING:
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
	print("Network Connecting State left")
