extends Control

@onready var btn_male: Button   = $HBoxContainer/Button_male
@onready var btn_female: Button = $HBoxContainer/Button_female
@onready var btn_start: Button  = $StartButton

var has_selection := false

func _ready():
	# Start erst aktivieren, wenn etwas gewählt wurde (optional)
	btn_start.disabled = true

	btn_male.pressed.connect(func():
		_select_gender(GameState.Gender.MALE)
	)
	btn_female.pressed.connect(func():
		_select_gender(GameState.Gender.FEMALE)
	)
	btn_start.pressed.connect(_start_game)

func _select_gender(gender):
	GameState.selected_gender = gender
	has_selection = true
	btn_start.disabled = false

	# (Optional) visuelles Feedback
	btn_male.button_pressed   = (gender == GameState.Gender.MALE)
	btn_female.button_pressed = (gender == GameState.Gender.FEMALE)

func _start_game():
	if not has_selection:
		return
	get_tree().change_scene_to_file("res://scenes/game/main-with-furniture.tscn")
