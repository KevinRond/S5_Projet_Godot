class_name NetworkFSMConnectingState
extends StateMachineState

var piCar_class = preload("res://scenes/Pi_car/scripts/Pi_car_remote.gd")
var piCar = piCar_class.new()

var highestTime = 0
var commTime = 0
var startCommTime = 0
var highestCommTime = 0


# Called when the state machine enters this state.
func on_enter() -> void:
	print("Network Connecting State entered")
	var err = get_parent().socket.connect_to_url("ws://127.0.0.1:8765")
	if err != OK:
		print("Failed to connect to web sock 0_0")
	else:
		print("oh no not diddy did he")
		var start= Time.get_ticks_msec()
		var elapsedTime = 0
		#while elapsedTime < 10000:
			#elapsedTime = Time.get_ticks_msec() - start

	# You should connect to the websocket server here. With the socket variable of NetworkFSM
	#get_parent().socket.connect("connection_closed", self, "_on_connection_closed")
	#get_parent().socket.connect("connection_error", self, "_on_connection_error")
	#get_parent().socket.connect("data_received", self, "_on_data_received")

# Called every frame when this state is active.
func on_process(delta: float) -> void:
	get_parent().socket.poll()
	
	while get_parent().socket.get_available_packet_count():
		var msg = get_parent().socket.get_packet().get_string_from_utf8()
		commTime = Time.get_ticks_msec() - startCommTime
		var starttimer = Time.get_ticks_msec()
		var sensors = extract_sensors(msg, 5)
		var distance = extract_distance(msg)
		var message = piCar.treat_info(delta, sensors, distance)
		
		message = JSON.stringify(message)
		var packet = message.to_utf8_buffer()
		var endTime = Time.get_ticks_msec() - starttimer
		if endTime > highestTime:
			highestTime = endTime
		if commTime > highestCommTime:
			highestCommTime = commTime
		var miaw = get_parent().socket.put_packet(packet)
		startCommTime = Time.get_ticks_msec()
	var state = get_parent().socket.get_ready_state()

	
	#if state == WebSocketPeer.STATE_CONNECTING:
		## Could be nice to have a blinker showing thats it's trying to connect?
		#pass
	#elif state == WebSocketPeer.STATE_OPEN:
		## Do stuff here
		#pass
	#
	#elif state == WebSocketPeer.STATE_CLOSED || state == WebSocketPeer.STATE_CLOSING:
		## Do stuff here
		#pass
		


# Called every physics frame when this state is active.
func on_physics_process(delta: float) -> void:
	pass


# Called when there is an input event while this state is active.
func on_input(event: InputEvent) -> void:
	pass


# Called when the state machine exits this state.
func on_exit() -> void:
	print("Network Connecting State left")
	
	
func extract_sensors(input_string: String, array_size: int) -> Array:
	var cleaned_string = input_string.strip_edges().replace("[", "").replace("]", "")
	cleaned_string = cleaned_string.replace(" ", "")
	var string_array = cleaned_string.split(",")
	var new_array = [string_array[0], string_array[1], string_array[2], string_array[3], string_array[4]]
	var boolean_array = []
	for s in new_array:
		boolean_array.append(s.strip_edges(true, true) == "1")
	
	if boolean_array.size() == array_size:
		return boolean_array
	else:
		push_error("The array size does not match the expected size. size is", boolean_array.size())
		return []
		
func extract_distance(input_string: String) -> float:
	var cleaned_string = input_string.strip_edges().replace("[", "").replace("]", "")
	cleaned_string = cleaned_string.replace(" ", "")
	var string_array = cleaned_string.split(",")
	return float(string_array[5])
	
func string_to_boolean_array(input_string: String, array_size: int) -> Array:
	var cleaned_string = input_string.strip_edges().replace("[", "").replace("]", "")
	cleaned_string = cleaned_string.replace(" ", "")
	var string_array = cleaned_string.split(",")
	var new_array = [string_array[0], string_array[1], string_array[2], string_array[3], string_array[4]]
	var boolean_array = []
	for s in new_array:
		boolean_array.append(s.strip_edges(true, true) == "1")
	
	if boolean_array.size() == array_size:
		return boolean_array
	else:
		push_error("The array size does not match the expected size. size is", boolean_array.size())
		return []
