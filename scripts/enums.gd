extends Node

enum MovementType { translation, rotation }

enum State { 
	manual_control,
	following_line,
	turning_left,
	turning_right,
	reverse,
	blocked,
	avoiding,
	recovering,
	stopping,
	finished,
	find_line,
	waiting,
	reverse_stopping,
	test_acceleration
}

