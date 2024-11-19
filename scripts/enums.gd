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
	finished,
	find_line
}

