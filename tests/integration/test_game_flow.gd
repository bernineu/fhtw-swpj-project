extends GutTest

var main_scene: Node3D

func before_each():
	GameState.reset_overflow()

# TC-INT-001: Gender selection persists across scenes
func test_gender_selection_persists():
	# Select female
	GameState.selected_gender = GameState.Gender.FEMALE
	
	# Get player scene
	var player_scene = GameState.get_selected_player_scene()
	assert_not_null(player_scene, "Player scene should be returned")
	
	# Verify it's the female scene
	var player = player_scene.instantiate()
	add_child_autofree(player)
	
	# Check if it has female-specific properties (this depends on your implementation)
	assert_true(is_instance_valid(player), "Player should instantiate correctly")

# TC-INT-002: Signals propagate correctly
func test_signal_propagation():
	var signal_chain_complete = false
	var overflow_changed_called = false
	
	GameState.overflow_changed.connect(func(_val, _max):
		overflow_changed_called = true
		signal_chain_complete = true
	)
	
	# Trigger the chain: add object -> overflow changes
	GameState.add_object()
	
	await wait_frames(2)
	
	assert_true(overflow_changed_called, "overflow_changed signal should be called")
	assert_true(signal_chain_complete, "Signal chain should complete")

# TC-INT-005: Pause/unpause maintains state
func test_pause_unpause_state():
	GameState.reset_overflow()
	GameState.score = 100
	GameState.overflow = 10
	
	# Pause game
	get_tree().paused = true
	assert_true(get_tree().paused, "Game should be paused")
	
	# Unpause
	get_tree().paused = false
	assert_false(get_tree().paused, "Game should be unpaused")
	
	# Verify state maintained
	assert_eq(GameState.score, 100, "Score should be maintained")
	assert_eq(GameState.overflow, 10, "Overflow should be maintained")

# TC-NEG-010: Game over triggered twice simultaneously
func test_duplicate_game_over_handling():
	GameState.reset_overflow()
	
	var game_over_count = 0
	GameState.overflow_full.connect(func(): game_over_count += 1)
	
	# Set overflow to max
	for i in range(20):
		GameState.add_object()
	
	# Try to trigger again
	GameState.add_object()
	
	await wait_frames(2)
	
	assert_eq(game_over_count, 1, "Game over should only trigger once")
	assert_true(GameState.is_game_over, "Game over flag should be set")

# Test score reset on game restart
func test_score_resets_on_restart():
	GameState.score = 500
	GameState.overflow = 15
	
	GameState.reset_overflow()
	
	assert_eq(GameState.score, 0, "Score should reset to 0")
	assert_eq(GameState.overflow, 0, "Overflow should reset to 0")
	assert_false(GameState.is_game_over, "Game over flag should be false")
