extends GutTest

# Overflow counter increases on spawn
func test_overflow_counter_increases_on_spawn():
	GameState.reset_overflow()
	assert_eq(GameState.overflow, 0, "Initial overflow should be 0")
	
	# Add 5 objects
	for i in range(5):
		GameState.add_object()
	
	assert_eq(GameState.overflow, 5, "Overflow should be 5 after adding 5 objects")

# Game over triggers at max overflow
func test_game_over_triggers_at_max_overflow():
	GameState.reset_overflow()
	var signal_data = {"triggered": false}
	
	GameState.overflow_full.connect(func(): signal_data.triggered = true)
	
	# Set overflow to 19
	for i in range(19):
		GameState.add_object()
	
	# Wait for signals to process
	await wait_frames(2)
	
	assert_false(signal_data.triggered, "Game over should not trigger at 19")
	assert_false(GameState.is_game_over, "Game over flag should be false")
	
	# Add one more to reach 20
	GameState.add_object()
	
	# Wait for signal to process
	await wait_frames(2)
	
	assert_true(signal_data.triggered, "Game over should trigger at 20")
	assert_true(GameState.is_game_over, "Game over flag should be true")
	assert_eq(GameState.overflow, 20, "Overflow should be clamped at 20")

# Rapid spawn causes overflow spike
func test_overflow_clamps_at_maximum():
	GameState.reset_overflow()
	
	# Try to add 25 objects (beyond max of 20)
	for i in range(25):
		GameState.add_object()
	
	await wait_frames(2)
	
	assert_eq(GameState.overflow, 20, "Overflow should be clamped at 20")
	assert_true(GameState.is_game_over, "Game over should be triggered")

# Score system - pickup bonus
func test_pickup_score_bonus():
	GameState.reset_overflow()
	assert_eq(GameState.score, 0, "Initial score should be 0")
	
	GameState.add_pickup_score()
	assert_eq(GameState.score, 5, "Score should be 5 after one pickup")
	
	GameState.add_pickup_score()
	assert_eq(GameState.score, 10, "Score should be 10 after two pickups")

# Score updates per second
func test_time_score_increments():
	GameState.reset_overflow()
	assert_eq(GameState.score, 0, "Initial score should be 0")
	
	# Simulate 5 seconds passing
	for i in range(5):
		GameState.update_time_score(1.0)
	
	assert_eq(GameState.score, 5, "Score should be 5 after 5 seconds")

# Score doesn't increment when game over
func test_score_stops_on_game_over():
	GameState.reset_overflow()
	GameState.is_game_over = true
	
	GameState.update_time_score(5.0)
	assert_eq(GameState.score, 0, "Score should not increase when game over")
	
	GameState.add_pickup_score()
	assert_eq(GameState.score, 0, "Pickup score should not add when game over")

# Gender selection persists
func test_gender_selection_persists():
	GameState.selected_gender = GameState.Gender.FEMALE
	assert_eq(GameState.selected_gender, GameState.Gender.FEMALE, "Female gender should persist")
	
	var scene = GameState.get_selected_player_scene()
	assert_not_null(scene, "Player scene should be returned")

# Test overflow signal emission
func test_overflow_changed_signal():
	GameState.reset_overflow()
	var signal_data = {"received": false, "value": -1, "max": -1}
	
	GameState.overflow_changed.connect(func(val, max_val):
		signal_data.received = true
		signal_data.value = val
		signal_data.max = max_val
	)
	
	GameState.add_object()
	
	# Wait for signal to be processed
	await wait_frames(2)
	
	assert_true(signal_data.received, "overflow_changed signal should be emitted")
	assert_eq(signal_data.value, 1, "Signal should contain value 1")
	assert_eq(signal_data.max, 20, "Signal should contain max 20")

# Test remove object functionality
func test_remove_object_decreases_overflow():
	GameState.reset_overflow()
	
	# Add 10 objects
	for i in range(10):
		GameState.add_object()
	
	assert_eq(GameState.overflow, 10)
	
	# Remove 3 objects
	for i in range(3):
		GameState.remove_object()
	
	assert_eq(GameState.overflow, 7, "Overflow should decrease to 7")

# Test overflow doesn't go negative
func test_overflow_cannot_go_negative():
	GameState.reset_overflow()
	
	GameState.remove_object()
	GameState.remove_object()
	
	assert_eq(GameState.overflow, 0, "Overflow should not go below 0")
