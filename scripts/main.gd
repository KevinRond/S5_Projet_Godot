extends Node3D

# Variables
var NetworkIPAddrRegex = RegEx.new()

# Engine functions
# Called when the node enters the scene tree for the first time.
func _ready():
	NetworkIPAddrRegex.compile(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$')
	
# Move this part of code anywhere you like. You might need to add a button or something before starting websocket connexion?!?
	var RegexResult = NetworkIPAddrRegex.search_all("127.0.0.1")
	if RegexResult.size() > 0:
		get_node("NetworkFSM").current_state = $NetworkFSM/NetworkInitState
	else:
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
