extends Node

enum Gender { MALE, FEMALE }
var selected_gender: Gender = Gender.MALE

const PLAYER_SCENES := {
	Gender.MALE: preload("res://scenes/player/player_male.tscn"),
	Gender.FEMALE: preload("res://scenes/player/player_female.tscn"),
}

func get_selected_player_scene() -> PackedScene:
	return PLAYER_SCENES[selected_gender]
