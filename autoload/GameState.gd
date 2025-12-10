extends Node

signal overflow_changed(value: int, max_value: int)
signal overflow_full
signal dog_death
signal score_changed(score: int)

enum Gender { MALE, FEMALE }
var selected_gender: Gender = Gender.MALE

const PLAYER_SCENES := {
	Gender.MALE: preload("res://scenes/player/player_male.tscn"),
	Gender.FEMALE: preload("res://scenes/player/player_female.tscn"),
}

var overflow: int = 0
var max_overflow: int = 20   # maximale Anzahl an Objekten bis Game Over

var score: int = 0
var _time_accum: float = 0.0
var is_game_over: bool = false


func get_selected_player_scene() -> PackedScene:
	return PLAYER_SCENES[selected_gender]


func add_object() -> void:
	overflow = clamp(overflow + 1, 0, max_overflow)
	overflow_changed.emit(overflow, max_overflow)
	if overflow >= max_overflow and not is_game_over:
		is_game_over = true
		overflow_full.emit()


func remove_object() -> void:
	overflow = clamp(overflow - 1, 0, max_overflow)
	overflow_changed.emit(overflow, max_overflow)


func reset_overflow() -> void:
	overflow = 0
	overflow_changed.emit(overflow, max_overflow)

	# Score & Zeit zurücksetzen
	score = 0
	score_changed.emit(score)
	_time_accum = 0.0
	is_game_over = false


# Wird einmal pro Frame aufgerufen, um +1 pro Sekunde zu geben
func update_time_score(delta: float) -> void:
	if is_game_over:
		return

	_time_accum += delta
	while _time_accum >= 1.0:
		_time_accum -= 1.0
		score += 1
		score_changed.emit(score)


# +5 Punkte pro aufgehobenem Objekt
func add_pickup_score() -> void:
	if is_game_over:
		return
	score += 5
	score_changed.emit(score)


func trigger_dog_death_game_over() -> void:
	"""Called when dog dies to trigger game over"""
	if not is_game_over:
		is_game_over = true
		dog_death.emit()
		print("🎮 Game Over: Dog died!")
