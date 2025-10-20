extends Control

func _ready():
	# Verbinde den Button mit einer Funktion
	$StartButton.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
	# Szene wechseln zu deinem eigentlichen Spiel
	get_tree().change_scene_to_file("res://scenes/main.tscn")
