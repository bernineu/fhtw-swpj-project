extends GutTest

var hud: Control
var test_scene: Node

func before_each():
	test_scene = Node.new()
	add_child_autofree(test_scene)
	
	# Create minimal HUD structure
	hud = Control.new()
	hud.name = "HUD"
	
	var overflow_bar = ProgressBar.new()
	overflow_bar.name = "OverflowBar"
	hud.add_child(overflow_bar)
	
	var game_over_panel = Control.new()
	game_over_panel.name = "GameOverPanel"
	game_over_panel.visible = false
	
	var highscore_label = Label.new()
	highscore_label.name = "Highscore"
	game_over_panel.add_child(highscore_label)
	
	var again_button = Button.new()
	again_button.name = "Button"
	game_over_panel.add_child(again_button)
	
	hud.add_child(game_over_panel)
	test_scene.add_child(hud)
	
	# Attach HUD script
	var hud_script = load("res://scripts/hud.gd")
	hud.set_script(hud_script)
	
	GameState.reset_overflow()

func after_each():
	if is_instance_valid(test_scene):
		test_scene.queue_free()

# TC-UI-001: Overflow bar displays current value
func test_overflow_bar_displays_value():
	var overflow_bar = hud.get_node("OverflowBar") as ProgressBar
	
	GameState.overflow = 10
	GameState.max_overflow = 20
	
	hud._on_overflow_changed(10, 20)
	
	assert_eq(overflow_bar.value, 10, "Bar value should be 10")
	assert_eq(overflow_bar.max_value, 20, "Bar max should be 20")

# TC-UI-002: Overflow bar updates on spawn
func test_overflow_bar_updates_on_spawn():
	var overflow_bar = hud.get_node("OverflowBar") as ProgressBar
	
	GameState.overflow = 5
	hud._on_overflow_changed(5, 20)
	assert_eq(overflow_bar.value, 5)
	
	GameState.add_object()
	hud._on_overflow_changed(6, 20)
	assert_eq(overflow_bar.value, 6, "Bar should update to 6")

# TC-UI-003: Overflow bar updates on pickup
func test_overflow_bar_updates_on_pickup():
	var overflow_bar = hud.get_node("OverflowBar") as ProgressBar
	
	GameState.overflow = 10
	hud._on_overflow_changed(10, 20)
	assert_eq(overflow_bar.value, 10)
	
	GameState.remove_object()
	hud._on_overflow_changed(9, 20)
	assert_eq(overflow_bar.value, 9, "Bar should update to 9")

# TC-UI-004: Score displays and updates
func test_score_display_updates():
	var highscore_label = hud.get_node("GameOverPanel/Highscore") as Label
	
	GameState.score = 0
	hud._on_score_changed(0)
	assert_eq(highscore_label.text, "Highscore: 0")
	
	GameState.score = 5
	hud._on_score_changed(5)
	assert_eq(highscore_label.text, "Highscore: 5")
	
	GameState.score = 100
	hud._on_score_changed(100)
	assert_eq(highscore_label.text, "Highscore: 100")

# TC-UI-005: Score updates on pickup
func test_score_updates_on_pickup():
	var highscore_label = hud.get_node("GameOverPanel/Highscore") as Label
	
	GameState.score = 10
	hud._on_score_changed(10)
	
	GameState.add_pickup_score()
	hud._on_score_changed(15)
	
	assert_eq(highscore_label.text, "Highscore: 15")

# TC-UI-006: Game over panel shows on overflow full
func test_game_over_panel_on_overflow():
	var game_over_panel = hud.get_node("GameOverPanel") as Control
	assert_false(game_over_panel.visible, "Panel should be hidden initially")
	
	# Trigger overflow full
	hud._on_overflow_full()
	
	await wait_frames(2)
	
	assert_true(game_over_panel.visible, "Panel should be visible")
	assert_true(get_tree().paused, "Game should be paused")

# TC-UI-007: Game over panel shows on dog death
func test_game_over_panel_on_dog_death():
	var game_over_panel = hud.get_node("GameOverPanel") as Control
	assert_false(game_over_panel.visible, "Panel should be hidden initially")
	
	# Trigger dog death
	hud._on_dog_death()
	
	await wait_frames(2)
	
	assert_true(game_over_panel.visible, "Panel should be visible")
	assert_true(get_tree().paused, "Game should be paused")

# TC-UI-008: Again button restarts game
func test_again_button_restarts():
	GameState.score = 100
	GameState.overflow = 15
	GameState.is_game_over = true
	
	var game_over_panel = hud.get_node("GameOverPanel") as Control
	game_over_panel.visible = true
	get_tree().paused = true
	
	# Click again button
	hud._on_again_button_pressed()
	
	await wait_frames(2)
	
	assert_false(get_tree().paused, "Game should be unpaused")
	assert_eq(GameState.score, 0, "Score should reset")
	assert_eq(GameState.overflow, 0, "Overflow should reset")
	assert_false(GameState.is_game_over, "Game over flag should be false")
