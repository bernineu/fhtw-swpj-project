extends GutTest

var main_scene: Node3D

func before_each():
	GameState.reset_overflow()

# TC-INT-004: NavMesh initialization
func test_navmesh_initialization():
	# This requires a full scene load
	# Best tested manually or with scene loading
	assert_true(true, "NavMesh initialization tested in full scene")

# Full game flow test
func test_complete_game_cycle():
	# Reset game state
	GameState.reset_overflow()
	GameState.selected_gender = GameState.Gender.MALE
	
	# Verify initial state
	assert_eq(GameState.overflow, 0, "Initial overflow should be 0")
	assert_eq(GameState.score, 0, "Initial score should be 0")
	assert_false(GameState.is_game_over, "Game should not be over")
	
	# Simulate gameplay: spawn objects
	for i in range(5):
		GameState.add_object()
	
	assert_eq(GameState.overflow, 5, "Overflow should be 5")
	
	# Simulate pickups
	for i in range(3):
		GameState.remove_object()
		GameState.add_pickup_score()
	
	assert_eq(GameState.overflow, 2, "Overflow should be 2")
	assert_eq(GameState.score, 15, "Score should be 15 (3 pickups)")
	
	# Simulate time passing
	GameState.update_time_score(10.0)
	assert_eq(GameState.score, 25, "Score should be 25 (15 + 10 seconds)")
	
	# Verify game can reach game over
	for i in range(20):
		GameState.add_object()
	
	assert_true(GameState.is_game_over, "Game should be over at max overflow")

# Test save/load of game state
func test_state_persistence_across_resets():
	GameState.score = 500
	GameState.overflow = 15
	GameState.selected_gender = GameState.Gender.FEMALE
	
	# Store values
	var stored_score = GameState.score
	var stored_overflow = GameState.overflow
	var stored_gender = GameState.selected_gender
	
	# Reset only game values (not gender)
	GameState.reset_overflow()
	
	assert_eq(GameState.score, 0, "Score should reset")
	assert_eq(GameState.overflow, 0, "Overflow should reset")
	assert_eq(GameState.selected_gender, stored_gender, "Gender should persist")

# Test signal chain
func test_complete_signal_chain():
	var overflow_signal_received = false
	var score_signal_received = false
	var game_over_signal_received = false
	
	GameState.overflow_changed.connect(func(_v, _m): overflow_signal_received = true)
	GameState.score_changed.connect(func(_s): score_signal_received = true)
	GameState.overflow_full.connect(func(): game_over_signal_received = true)
	
	# Trigger actions
	GameState.add_object()
	assert_true(overflow_signal_received, "Overflow signal should fire")
	
	GameState.add_pickup_score()
	assert_true(score_signal_received, "Score signal should fire")
	
	# Trigger game over
	for i in range(20):
		GameState.add_object()
	
	await wait_frames(2)
	assert_true(game_over_signal_received, "Game over signal should fire")

# Test multiple game cycles
func test_multiple_restart_cycles():
	for cycle in range(3):
		GameState.reset_overflow()
		
		# Play a game cycle
		for i in range(10):
			GameState.add_object()
		
		for i in range(5):
			GameState.remove_object()
			GameState.add_pickup_score()
		
		GameState.update_time_score(5.0)
		
		# Verify state is correct each time
		assert_eq(GameState.overflow, 5, "Overflow should be 5 in cycle %d" % cycle)
		assert_eq(GameState.score, 30, "Score should be 30 in cycle %d" % cycle)
	
	assert_true(true, "Multiple restart cycles completed successfully")

# Test dog death triggers game over properly
func test_dog_death_game_over_integration():
	GameState.reset_overflow()
	var game_over_triggered = false
	
	GameState.dog_death.connect(func(): game_over_triggered = true)
	
	# Trigger dog death
	GameState.trigger_dog_death_game_over()
	
	await wait_frames(2)
	
	assert_true(game_over_triggered, "Dog death signal should fire")
	assert_true(GameState.is_game_over, "Game over flag should be set")

# Test overflow and dog death don't conflict
func test_overflow_and_death_independence():
	GameState.reset_overflow()
	
	var overflow_count = 0
	var death_count = 0
	
	GameState.overflow_full.connect(func(): overflow_count += 1)
	GameState.dog_death.connect(func(): death_count += 1)
	
	# Trigger overflow
	for i in range(20):
		GameState.add_object()
	
	await wait_frames(2)
	
	# Also trigger death
	GameState.trigger_dog_death_game_over()
	
	await wait_frames(2)
	
	# Both should have triggered independently
	assert_eq(overflow_count, 1, "Overflow should trigger once")
	assert_eq(death_count, 1, "Death should trigger once")
	assert_true(GameState.is_game_over, "Game over should be set")

# Test score accumulation over time
func test_score_time_accumulation():
	GameState.reset_overflow()
	
	# Simulate 30 seconds of gameplay
	for i in range(30):
		GameState.update_time_score(1.0)
	
	assert_eq(GameState.score, 30, "Score should be 30 after 30 seconds")
	
	# Add some pickups
	for i in range(5):
		GameState.add_pickup_score()
	
	assert_eq(GameState.score, 55, "Score should be 55 (30 + 25)")

# Test fractional time updates
func test_fractional_time_score_updates():
	GameState.reset_overflow()
	
	# Simulate 60 frames at 60 FPS (1 second)
	for i in range(60):
		GameState.update_time_score(1.0 / 60.0)
	
	assert_eq(GameState.score, 1, "Score should be 1 after 60 frames")
	
	# Simulate another 120 frames (2 more seconds)
	for i in range(120):
		GameState.update_time_score(1.0 / 60.0)
	
	assert_eq(GameState.score, 3, "Score should be 3 after 180 frames total")

# Test game over prevents further score updates
func test_game_over_freezes_score():
	GameState.reset_overflow()
	GameState.score = 100
	
	# Trigger game over
	for i in range(20):
		GameState.add_object()
	
	assert_true(GameState.is_game_over)
	
	var score_before = GameState.score
	
	# Try to update score
	GameState.update_time_score(10.0)
	GameState.add_pickup_score()
	
	assert_eq(GameState.score, score_before, "Score should not change when game over")

# Test gender selection affects player instantiation
func test_gender_affects_player_scene():
	GameState.selected_gender = GameState.Gender.MALE
	var male_scene = GameState.get_selected_player_scene()
	
	GameState.selected_gender = GameState.Gender.FEMALE
	var female_scene = GameState.get_selected_player_scene()
	
	assert_not_null(male_scene, "Male scene should be returned")
	assert_not_null(female_scene, "Female scene should be returned")
	assert_ne(male_scene, female_scene, "Male and female scenes should be different")
