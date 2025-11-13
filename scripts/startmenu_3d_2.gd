extends Node3D

@onready var btn_man: CharacterBody3D   = $Man
@onready var btn_woman: CharacterBody3D = $Woman
@onready var btn_start: StaticBody3D  = $Television

var has_selection := false

func _ready() -> void:
	start_idle_animations()

	btn_woman.connect("input_event", Callable(self, "woman_chosen"))
	btn_man.connect("input_event", Callable(self, "man_chosen"))
	btn_start.connect("input_event", Callable(self, "start_chosen"))

func woman_chosen(camera, event, click_position, click_normal, shape_idx):
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		print("Woman clicked in main script!")
		start_idle_animations()
		play_character_animation(btn_woman, "HumanArmature|Female_Jump")
		_select_gender(GameState.Gender.FEMALE)

func man_chosen(camera, event, click_position, click_normal, shape_idx):
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		print("Man clicked in main script!")
		start_idle_animations()
		play_character_animation(btn_man, "HumanArmature|Man_Jump")
		_select_gender(GameState.Gender.MALE)

func start_chosen(camera, event, click_position, click_normal, shape_idx):
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		print("Start button clicked in main script!")
		_start_game()

func start_idle_animations() -> void:
	play_character_animation(btn_woman, "HumanArmature|Female_Idle")
	play_character_animation(btn_man, "HumanArmature|Man_Idle")

func play_character_animation(btn, animation_name) -> void:
	var anim = btn.find_child("AnimationPlayer", true, false)
	
	anim.play(animation_name)
	
	# Loopen erzwingen, wenn möglich
	if anim.has_animation(animation_name):
		var a : Animation = anim.get_animation(animation_name)
		if a: a.loop_mode = Animation.LOOP_LINEAR

func _select_gender(gender):
	GameState.selected_gender = gender
	has_selection = true


func _start_game():
	if not has_selection:
		return
	get_tree().change_scene_to_file("res://scenes/game/main-with-furniture.tscn")
