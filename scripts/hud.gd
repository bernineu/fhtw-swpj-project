extends Control

@onready var hearts_container: HBoxContainer = get_node_or_null("Hearts")
@onready var overflow_bar: ProgressBar = get_node_or_null("OverflowBar")
@onready var game_over_panel: Control = get_node_or_null("GameOverPanel")

@export var snack_icons: Array[Texture2D] = [] # Index 0..3 = DOG_FOOD, CHEESE, CHOCOLATE, POISON
@onready var discipline_list: VBoxContainer = get_node_or_null("DisciplinePanel/DisciplineList")

var discipline_rows: Array = []  # speichert {icon:TextureRect, label:Label}

@onready var win_panel: Control = get_node_or_null("WinPanel")
var win_button: Button = null
var win_triggered := false


@export var heart_full: Texture2D
@export var heart_empty: Texture2D

var heart_icons: Array[TextureRect] = []
var dog: Node = null

var again_button: Button = null
var highscore_label: Label = null
var collectedItems_label: Label = null


func _ready() -> void:

	if overflow_bar == null:
		push_warning("OverflowBar nicht gefunden – HUD erwartet einen Knoten 'OverflowBar'.")
	else:
		overflow_bar.min_value = 0
		overflow_bar.max_value = GameState.max_overflow
		overflow_bar.value = GameState.overflow

# --- WinPanel setup ---
	if win_panel != null:
		win_panel.visible = false
		win_button = win_panel.get_node_or_null("Button") as Button
		if win_button != null:
			win_button.pressed.connect(_on_win_button_pressed)
	else:
		push_warning("WinPanel nicht gefunden – HUD erwartet einen Knoten 'WinPanel'.")


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

	# --- Dog suchen ---
	dog = get_tree().get_first_node_in_group("dog")
	if dog == null:
		push_warning("Dog nicht gefunden (Group 'dog'). HUD wird nicht aktualisiert.")
		return

	# --- Herzen ---
	var max_lives := 3
	if "MAX_LIVES" in dog:
		max_lives = dog.MAX_LIVES
	elif "max_lives" in dog:
		max_lives = dog.max_lives

	_build_hearts(max_lives)

	var current_lives := 3
	if "lives" in dog:
		current_lives = dog.lives
	_update_hearts(current_lives)

	if dog.has_signal("lives_changed"):
		dog.lives_changed.connect(_on_lives_changed)
	else:
		push_warning("Dog hat kein Signal 'lives_changed'.")

	# --- Discipline UI bauen ---
	_build_discipline_ui()

	# initial füllen
	if dog.has_method("get_discipline_count"):
		for i in range(4):
			_update_discipline_row(i, dog.get_discipline_count(i))
	else:
		# fallback: direkt Array lesen
		if "discipline_counts" in dog:
			for i in range(4):
				_update_discipline_row(i, dog.discipline_counts[i])

	# live updates
	if dog.has_signal("discipline_changed"):
		dog.discipline_changed.connect(_on_discipline_changed)
	else:
		push_warning("Dog hat kein Signal 'discipline_changed'.")


func _on_discipline_changed(snack_type: int, count: int) -> void:
	_update_discipline_row(snack_type, count)
	_check_win_condition()


func _build_discipline_ui() -> void:
	if discipline_list == null:
		push_warning("DisciplineList nicht gefunden – erwartet 'DisciplinePanel/DisciplineList'.")
		return
	# clean
	for c in discipline_list.get_children():
		c.queue_free()
	discipline_rows.clear()

	var names = ["DOG_FOOD", "CHEESE", "CHOCOLATE", "POISON"]
	for i in range(4):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(40, 40)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if i < snack_icons.size() and snack_icons[i] != null:
			icon.texture = snack_icons[i]

		var label := Label.new()
		label.text = "%s: 0/3" % names[i]

		row.add_child(icon)
		row.add_child(label)
		discipline_list.add_child(row)

		discipline_rows.append({"icon": icon, "label": label})


func _on_overflow_changed(value: int, max_value: int) -> void:
	if overflow_bar == null:
		return
	overflow_bar.max_value = max_value
	overflow_bar.value = value


func _update_discipline_row(snack_type: int, count: int) -> void:
	if snack_type < 0 or snack_type >= discipline_rows.size():
		return
	var names = ["DOG_FOOD", "CHEESE", "CHOCOLATE", "POISON"]
	var lbl: Label = discipline_rows[snack_type]["label"]
	lbl.text = "%s: %d/3" % [names[snack_type], count]


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

func _on_win_button_pressed() -> void:
	print("Win button clicked")
	get_tree().paused = false
	GameState.reset_overflow()
	get_tree().change_scene_to_file("res://scenes/game/menu/startmenu3d.tscn")


func _check_win_condition() -> void:
	if win_triggered:
		return
	if dog == null or !is_instance_valid(dog):
		return
	if not ("discipline_counts" in dog):
		return

	var threshold := 3
	if "discipline_threshold_block" in dog:
		threshold = dog.discipline_threshold_block

	# "3 food types" -> meistens meint man: DOG_FOOD, CHEESE, CHOCOLATE (ohne POISON)
	var food_types := [0, 1, 2]

	var fully_disciplined := 0
	for st in food_types:
		if dog.discipline_counts[st] >= threshold:
			fully_disciplined += 1

	if fully_disciplined >= 1:
		_show_win_screen()


func _show_win_screen() -> void:
	win_triggered = true

	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if win_panel != null:
		win_panel.visible = true


func _on_again_button_pressed() -> void:
	print("Again clicked")
	# Pause beenden
	get_tree().paused = false

	# Overflow & Score zurücksetzen
	GameState.reset_overflow()

	# Zurück ins Startmenü
	get_tree().change_scene_to_file("res://scenes/game/menu/startmenu3d.tscn")
