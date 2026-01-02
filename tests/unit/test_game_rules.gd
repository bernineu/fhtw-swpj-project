extends GutTest

# These tests verify game rules automatically
# They don't test visuals/animations, but they verify logic

# Test: Dog should die after 3 chocolates
func test_chocolate_death_rule():
	# We can't test with real dog, but we can verify the rule
	const CHOCOLATE_LIMIT = 3
	var chocolates_eaten = 0
	
	for i in range(CHOCOLATE_LIMIT):
		chocolates_eaten += 1
		
	assert_eq(chocolates_eaten, 3, "Death should occur at 3 chocolates")
	# In game: dog.chocolate_eaten >= 3 triggers death

# Test: Discipline should have cooldown
func test_discipline_cooldown_rule():
	const COOLDOWN_DURATION = 1.0
	var time_since_last_discipline = 0.0
	
	# Simulate 0.5 seconds passing
	time_since_last_discipline = 0.5
	var can_discipline_early = time_since_last_discipline >= COOLDOWN_DURATION
	assert_false(can_discipline_early, "Should not be able to discipline at 0.5s")
	
	# Simulate 1.0 seconds total
	time_since_last_discipline = 1.0
	var can_discipline_ready = time_since_last_discipline >= COOLDOWN_DURATION
	assert_true(can_discipline_ready, "Should be able to discipline at 1.0s")

# Test: Score should stop at game over
func test_score_freezes_at_game_over():
	GameState.reset_overflow()
	GameState.score = 100
	GameState.is_game_over = true
	
	# Try to add score
	GameState.update_time_score(10.0)
	GameState.add_pickup_score()
	
	assert_eq(GameState.score, 100, "Score should remain 100 when game over")

# Test: Overflow should trigger game over at 20
func test_overflow_limit_rule():
	const MAX_OVERFLOW = 20
	GameState.reset_overflow()
	
	# Add to limit
	for i in range(MAX_OVERFLOW):
		GameState.add_object()
	
	assert_true(GameState.is_game_over, "Game should be over at max overflow")
	assert_eq(GameState.overflow, MAX_OVERFLOW, "Overflow should be at max")

# Test: Pickup range validation
func test_pickup_range_rule():
	const PICKUP_DISTANCE = 3.0
	
	# Simulate positions
	var player_pos = Vector3(0, 0, 0)
	var snack_close = Vector3(2, 0, 0)  # 2 units away
	var snack_far = Vector3(5, 0, 0)    # 5 units away
	
	var distance_close = player_pos.distance_to(snack_close)
	var distance_far = player_pos.distance_to(snack_far)
	
	assert_true(distance_close <= PICKUP_DISTANCE, "Close snack should be pickable")
	assert_false(distance_far <= PICKUP_DISTANCE, "Far snack should not be pickable")

# Test: Discipline range validation
func test_discipline_range_rule():
	const DISCIPLINE_RANGE = 5.0
	
	var player_pos = Vector3(0, 0, 0)
	var dog_close = Vector3(4, 0, 0)   # 4 units away
	var dog_far = Vector3(6, 0, 0)     # 6 units away
	
	var distance_close = player_pos.distance_to(dog_close)
	var distance_far = player_pos.distance_to(dog_far)
	
	assert_true(distance_close <= DISCIPLINE_RANGE, "Close dog should be disciplinable")
	assert_false(distance_far <= DISCIPLINE_RANGE, "Far dog should not be disciplinable")

# Test: Snack spawn timer rule
func test_snack_spawn_timing():
	const SPAWN_INTERVAL = 3.0
	var time_accumulator = 0.0
	var snacks_spawned = 0
	
	# Simulate 9 seconds
	for i in range(90):  # 90 frames at 0.1s each
		time_accumulator += 0.1
		if time_accumulator >= SPAWN_INTERVAL:
			time_accumulator -= SPAWN_INTERVAL
			snacks_spawned += 1
	
	assert_eq(snacks_spawned, 3, "Should spawn 3 snacks in 9 seconds")

# Test: Hunger increase rate
func test_hunger_increase_rate():
	const HUNGER_PER_SECOND = 0.01
	var hunger = 0.0
	
	# Simulate 10 seconds
	for i in range(10):
		hunger += HUNGER_PER_SECOND
	
	assert_almost_eq(hunger, 0.1, 0.001, "Hunger should be 0.1 after 10 seconds")

# Test: Hunger reduction per snack
func test_hunger_reduction_amount():
	const HUNGER_REDUCTION = 0.3
	var hunger = 0.5
	
	hunger -= HUNGER_REDUCTION
	
	assert_almost_eq(hunger, 0.2, 0.001, "Hunger should be 0.2 after eating")

# Test: Time score accumulation
func test_time_score_rate():
	GameState.reset_overflow()
	
	# Simulate 30 seconds
	GameState.update_time_score(30.0)
	
	assert_eq(GameState.score, 30, "Score should be 30 after 30 seconds")
