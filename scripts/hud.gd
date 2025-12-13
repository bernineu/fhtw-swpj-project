extends Control

@onready var overflow_bar: ProgressBar = get_node_or_null("OverflowBar")
@onready var game_over_panel: Control = get_node_or_null("GameOverPanel")
var again_button: Button = null
var highscore_label: Label = null


func _ready() -> void:

	if overflow_bar == null:
		push_warning("OverflowBar nicht gefunden – HUD erwartet einen Knoten 'OverflowBar'.")
	else:
		overflow_bar.min_value = 0
		overflow_bar.max_value = GameState.max_overflow
		overflow_bar.value = GameState.overflow

	if game_over_panel != null:
		game_over_panel.visible = false

		# Again-Button suchen
		# Pfad an deine Szene angepasst lassen:
		again_button = game_over_panel.get_node_or_null("Button") as Button
		if again_button != null:
			again_button.pressed.connect(_on_again_button_pressed)
		else:
			push_warning("AgainButton nicht gefunden – erwartet 'GameOverPanel/Button'.")

		# Highscore-Label suchen
		highscore_label = game_over_panel.get_node_or_null("Highscore") as Label
		if highscore_label == null:
			push_warning("Highscore-Label nicht gefunden – erwartet 'GameOverPanel/Highscore'.")
	else:
		push_warning("GameOverPanel nicht gefunden – HUD erwartet einen Knoten 'GameOverPanel'.")

	# Signale vom GameState verbinden
	GameState.overflow_changed.connect(_on_overflow_changed)
	GameState.overflow_full.connect(_on_overflow_full)
	GameState.dog_death.connect(_on_dog_death)
	GameState.score_changed.connect(_on_score_changed)


func _on_overflow_changed(value: int, max_value: int) -> void:
	if overflow_bar == null:
		return
	overflow_bar.max_value = max_value
	overflow_bar.value = value


func _on_overflow_full() -> void:
	# Spiel pausieren
	get_tree().paused = true

	# Maus sichtbar machen, damit man klicken kann
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if game_over_panel != null:
		game_over_panel.visible = true


func _on_dog_death() -> void:
	"""Handle dog death game over (same as overflow)"""
	# Spiel pausieren
	get_tree().paused = true

	# Maus sichtbar machen, damit man klicken kann
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if game_over_panel != null:
		game_over_panel.visible = true


func _on_score_changed(score: int) -> void:
	if highscore_label != null:
		highscore_label.text = "Highscore: %d" % score


func _on_again_button_pressed() -> void:
	print("Again clicked")
	# Pause beenden
	get_tree().paused = false

	# Overflow & Score zurücksetzen
	GameState.reset_overflow()

	# Zurück ins Startmenü
	get_tree().change_scene_to_file("res://scenes/game/menu/startmenu3d.tscn")
