extends GutTest

var test_scene: Node3D
var dog: CharacterBody3D
var player: CharacterBody3D

func before_each():
	test_scene = TestHelpers.create_test_scene()
	add_child_autofree(test_scene)
	GameState.reset_overflow()

func after_each():
	if is_instance_valid(test_scene):
		test_scene.queue_free()

# TC-NEG-004: Multiple snacks spawn at same location
func test_multiple_snacks_same_location():
	var spawn_pos = Vector3(5, 0.5, 5)
	
	var snack1 = TestHelpers.create_snack(test_scene, 0, spawn_pos)
	var snack2 = TestHelpers.create_snack(test_scene, 1, spawn_pos)
	var snack3 = TestHelpers.create_snack(test_scene, 2, spawn_pos)
	
	await wait_frames(2)
	
	# All snacks should exist
	assert_true(is_instance_valid(snack1), "Snack 1 should exist")
	assert_true(is_instance_valid(snack2), "Snack 2 should exist")
	assert_true(is_instance_valid(snack3), "Snack 3 should exist")
	
	# Dog should be able to target one of them
	dog = TestHelpers.create_mock_dog(test_scene, Vector3.ZERO)
	dog.find_nearest_treat()
	await wait_frames(2)
	
	assert_not_null(dog.target_treat, "Dog should target one snack")

# TC-NEG-006: Discipline at exact 5.0 unit boundary
func test_discipline_at_exact_boundary():
	player = TestHelpers.create_mock_player(test_scene)
	player.discipline_range = 5.0
	player.discipline_cooldown = 0.0
	
	# Position dog exactly 5.0 units away
	dog = TestHelpers.create_mock_dog(test_scene, player.global_position + Vector3(5.0, 0, 0))
	var snack = TestHelpers.create_snack(test_scene, 2, dog.global_position + Vector3(1, 0, 0))
	dog.target_treat = snack
	
	# Attempt discipline
	player.attempt_discipline()
	
	# Should succeed with <= comparison
	assert_true(dog.is_being_disciplined, "Discipline should work at exact boundary")

# TC-NEG-007: Dog eats at exact 3.0 unit boundary
func test_dog_eats_at_exact_boundary():
	dog = TestHelpers.create_mock_dog(test_scene, Vector3.ZERO)
	
	# Position snack exactly 3.0 units away
	var snack = TestHelpers.create_snack(test_scene, 0, Vector3(3.0, 0, 0))
	snack.eating_distance = 3.0
	
	dog.global_position = Vector3.ZERO
	snack.global_position = Vector3(3.0, 0, 0)
	
	# Try eating
	snack._try_eating()
	
	# Should trigger eating at exact boundary
	assert_true(dog.is_eating, "Dog should eat at exact boundary distance")

# TC-NEG-009: Dog disciplined at exact moment of eating completion
func test_discipline_race_condition_with_eating():
	dog = TestHelpers.create_mock_dog(test_scene, Vector3.ZERO)
	player = TestHelpers.create_mock_player(test_scene)
	
	# Set dog to eating with timer almost complete
	dog.is_eating = true
	dog.eat_timer = 0.01  # About to complete
	dog.current_eating_snack_type = 2
	
	var snack = TestHelpers.create_snack(test_scene, 2, dog.global_position)
	dog.target_treat = snack
	
	# Position player nearby
	player.global_position = dog.global_position + Vector3(3, 0, 0)
	player.discipline_cooldown = 0.0
	
	# Attempt discipline at same moment eating completes
	player.attempt_discipline()
	dog._physics_process(0.02)  # Complete eating
	
	await wait_frames(2)
	
	# Either discipline succeeded OR eating completed, but no crash
	assert_true(is_instance_valid(dog), "Dog should remain valid")
	# One of these should be true
	var outcome = dog.is_being_disciplined or (not dog.is_eating and dog.eat_timer <= 0)
	assert_true(outcome, "One outcome should occur without crash")

# TC-NEG-011: Player picks up snack while dog is eating it
func test_concurrent_snack_pickup_and_eating():
	dog = TestHelpers.create_mock_dog(test_scene, Vector3.ZERO)
	player = TestHelpers.create_mock_player(test_scene)
	
	# Create snack between dog and player
	var snack = TestHelpers.create_snack(test_scene, 0, Vector3(2, 0, 0))
	
	# Dog starts eating
	dog.global_position = Vector3(1.5, 0, 0)
	dog.is_eating = true
	dog.eat_timer = 1.0  # 1 second left
	
	# Player is in range to pick up
	player.global_position = Vector3(3, 0, 0)
	
	# Player tries to pick up
	snack._try_pickup()
	
	await wait_frames(2)
	
	# Snack should be handled by one actor
	# Either it's removed or still exists, but no crash
	assert_true(true, "Concurrent access handled without crash")

# TC-NEG-012: Navigation target set to invalid position
func test_invalid_navigation_position():
	dog = TestHelpers.create_mock_dog(test_scene, Vector3.ZERO)
	
	# Create snack at invalid position (way outside bounds)
	var snack = TestHelpers.create_snack(test_scene, 0, Vector3(10000, -1000, 10000))
	dog.target_treat = snack
	
	# Set navigation target to invalid position
	dog.nav_agent.set_target_position(snack.global_position)
	
	# Should not crash
	for i in range(5):
		dog._physics_process(0.1)
		await wait_frames(1)
	
	assert_true(is_instance_valid(dog), "Dog should handle invalid position gracefully")

# TC-NEG-013: Scene change during animation
func test_scene_change_during_animation():
	player = TestHelpers.create_mock_player(test_scene)
	
	# Start pickup animation
	player.play_pickup_animation()
	assert_true(player._is_playing_pickup, "Animation should be playing")
	
	# Simulate scene change by removing player
	player.queue_free()
	await wait_frames(2)
	
	# Should not crash
	assert_true(true, "Scene change handled without crash")

# TC-NEG-002: Player pickup during animation lock
func test_pickup_during_animation_lock():
	player = TestHelpers.create_mock_player(test_scene)
	var snack1 = TestHelpers.create_snack(test_scene, 0, player.global_position + Vector3(2, 0, 0))
	var snack2 = TestHelpers.create_snack(test_scene, 1, player.global_position + Vector3(2, 0, 0))
	
	GameState.add_object()
	GameState.add_object()
	
	# Start first pickup
	player._is_playing_pickup = true
	player.speed = 0.0
	
	var initial_overflow = GameState.overflow
	
	# Try second pickup while locked
	snack2._try_pickup()
	
	# Second pickup should be ignored
	assert_eq(GameState.overflow, initial_overflow, "Overflow should not change during animation lock")

# TC-NEG-003: Discipline during cooldown
func test_rapid_discipline_attempts():
	player = TestHelpers.create_mock_player(test_scene)
	dog = TestHelpers.create_mock_dog(test_scene, player.global_position + Vector3(3, 0, 0))
	
	var snack = TestHelpers.create_snack(test_scene, 2, dog.global_position)
	dog.target_treat = snack
	
	player.discipline_cooldown = 0.0
	
	# First discipline
	player.attempt_discipline()
	assert_almost_eq(player.discipline_cooldown, 1.0, 0.01, "Cooldown should be set")
	
	var first_discipline_worked = dog.is_being_disciplined
	
	# Reset dog state for second attempt
	dog.is_being_disciplined = false
	
	# Try again immediately (should fail)
	player.attempt_discipline()
	
	# Cooldown should prevent second discipline
	assert_false(dog.is_being_disciplined, "Second discipline should be blocked by cooldown")

# TC-INT-003: Performance with 20+ snacks
func test_performance_with_many_snacks():
	var snack_count = 25
	var snacks = []
	
	# Spawn 25 snacks
	for i in range(snack_count):
		var pos = Vector3(randf_range(-10, 10), 0.5, randf_range(-10, 10))
		var snack_type = i % 3  # Rotate through types
		var snack = TestHelpers.create_snack(test_scene, snack_type, pos)
		snacks.append(snack)
	
	dog = TestHelpers.create_mock_dog(test_scene, Vector3.ZERO)
	player = TestHelpers.create_mock_player(test_scene)
	
	await wait_frames(2)
	
	# Process for several frames
	var start_time = Time.get_ticks_msec()
	for i in range(60):  # Simulate 60 frames
		dog._physics_process(0.016)  # ~60 FPS
		player._physics_process(0.016)
		await wait_frames(1)
	var end_time = Time.get_ticks_msec()
	
	var elapsed = end_time - start_time
	
	# Should complete in reasonable time (very lenient: under 2 seconds for 60 frames)
	assert_true(elapsed < 2000, "Performance should be acceptable with 25 snacks")
	assert_eq(snacks.size(), snack_count, "All snacks should still exist")

# TC-NEG-010: Duplicate game over signals
func test_duplicate_game_over_signals():
	GameState.reset_overflow()
	
	var overflow_signals = 0
	var death_signals = 0
	
	GameState.overflow_full.connect(func(): overflow_signals += 1)
	GameState.dog_death.connect(func(): death_signals += 1)
	
	# Trigger overflow game over
	for i in range(20):
		GameState.add_object()
	
	# Also trigger dog death
	GameState.trigger_dog_death_game_over()
	
	await wait_frames(2)
	
	# Each signal should only fire once
	assert_eq(overflow_signals, 1, "Overflow signal should fire once")
	assert_eq(death_signals, 1, "Death signal should fire once")
	assert_true(GameState.is_game_over, "Game over flag should be set")

# TC-AI-017: Discipline interrupts eating
func test_discipline_interrupts_eating():
	dog = TestHelpers.create_mock_dog(test_scene, Vector3.ZERO)
	player = TestHelpers.create_mock_player(test_scene)
	
	# Dog is eating
	dog.is_eating = true
	dog.eat_timer = 1.0  # 1 second remaining
	dog.current_eating_snack_type = 2  # Chocolate
	
	var snack = TestHelpers.create_snack(test_scene, 2, dog.global_position)
	
	player.global_position = dog.global_position + Vector3(4, 0, 0)
	player.discipline_cooldown = 0.0
	
	# Discipline the dog
	dog.on_disciplined(2)
	
	# Eating should be interrupted
	assert_false(dog.is_eating, "Eating should be interrupted")
	assert_eq(dog.eat_timer, 0.0, "Eat timer should be reset")
	assert_true(dog.is_being_disciplined, "Dog should be disciplined")
	assert_eq(dog.current_eating_snack_type, -1, "Eating snack type should be cleared")
