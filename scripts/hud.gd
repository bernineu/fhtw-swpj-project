extends Control

@onready var hearts_container: HBoxContainer = get_node_or_null("Hearts")
@onready var overflow_bar: ProgressBar = get_node_or_null("OverflowBar")
@onready var game_over_panel: Control = get_node_or_null("GameOverPanel")

@export var heart_full: Texture2D
@export var heart_empty: Texture2D

var heart_icons: Array[TextureRect] = []
var dog: Node = null

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
	
		# --- Dog suchen und an Lives-UI koppeln ---
	dog = get_tree().get_first_node_in_group("dog")
	if dog == null:
		push_warning("Dog nicht gefunden (Group 'dog'). Lives-HUD wird nicht aktualisiert.")
	else:
		# Herzen initial aufbauen
		var max_lives := 3
		if "MAX_LIVES" in dog:
			max_lives = dog.MAX_LIVES
		elif "max_lives" in dog:
			max_lives = dog.max_lives

		_build_hearts(max_lives)

		# Initialer Stand
		var current_lives := 3
		if "lives" in dog:
			current_lives = dog.lives
		_update_hearts(current_lives)

		# Signal verbinden
		if dog.has_signal("lives_changed"):
			dog.lives_changed.connect(_on_lives_changed)
		else:
			push_warning("Dog hat kein Signal 'lives_changed'.")



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


func _build_hearts(max_lives: int) -> void:
	if hearts_container == null:
		push_warning("Hearts-Container nicht gefunden – erwartet 'Hearts' (HBoxContainer).")
		return

	# Alte Icons entfernen (falls Szene neu geladen wird)
	for c in hearts_container.get_children():
		c.queue_free()
	heart_icons.clear()

	for i in range(max_lives):
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(32, 32) # Größe anpassen
		tr.texture = heart_full if heart_full != null else null
		hearts_container.add_child(tr)
		heart_icons.append(tr)


func _update_hearts(current_lives: int) -> void:
	for i in range(heart_icons.size()):
		var tr := heart_icons[i]
		if tr == null:
			continue
		if i < current_lives:
			tr.texture = heart_full
		else:
			tr.texture = heart_empty


func _on_lives_changed(new_lives: int) -> void:
	_update_hearts(new_lives)


func _on_again_button_pressed() -> void:
	print("Again clicked")
	# Pause beenden
	get_tree().paused = false

	# Overflow & Score zurücksetzen
	GameState.reset_overflow()

	# Zurück ins Startmenü
	get_tree().change_scene_to_file("res://scenes/game/menu/startmenu3d.tscn")
