extends Node

signal overflow_changed(value: int, max_value: int)
signal overflow_full

enum Gender { MALE, FEMALE }
var selected_gender: Gender = Gender.MALE

const PLAYER_SCENES := {
	Gender.MALE: preload("res://scenes/player/player_male.tscn"),
	Gender.FEMALE: preload("res://scenes/player/player_female.tscn"),
}

var overflow: int = 0
var max_overflow: int = 20   # z.B. max. 10 Items gleichzeitig im Raum


func get_selected_player_scene() -> PackedScene:
	return PLAYER_SCENES[selected_gender]


func add_object() -> void:
	overflow = clamp(overflow + 1, 0, max_overflow)
	overflow_changed.emit(overflow, max_overflow)
	if overflow >= max_overflow:
		overflow_full.emit()


func remove_object() -> void:
	overflow = clamp(overflow - 1, 0, max_overflow)
	overflow_changed.emit(overflow, max_overflow)

func reset_overflow() -> void:
	overflow = 0
	overflow_changed.emit(overflow, max_overflow)
