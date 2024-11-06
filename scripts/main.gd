extends Node3D


func _on_parcours_sl_button_pressed():
	Globals.change_scene_path("res://scenes/parcours/Parcours_SL/parcours_SL.tscn")
	get_tree().change_scene_to_file("res://scenes/Choix_Valeurs/ChooseParcoursValues.tscn")
	

func _on_parcours_reel_button_pressed():
	Globals.change_scene_path("res://scenes/parcours/Parcours_Reel/parcours_reel.tscn")
	get_tree().change_scene_to_file("res://scenes/Choix_Valeurs/ChooseParcoursValues.tscn")


func _on_parcours_us_button_pressed():
	Globals.change_scene_path("res://scenes/parcours/Parcours_US/Ultrason.tscn")
	get_tree().change_scene_to_file("res://scenes/Choix_Valeurs/ChooseParcoursValues.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
