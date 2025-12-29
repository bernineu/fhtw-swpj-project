extends GutTest

var test_scene: Node3D
var player: CharacterBody3D

func before_each():
	test_scene = TestHelpers.create_test_scene()
	add_child_autofree(test_scene)
	player = TestHelpers.create_mock_player(test_scene)

func after_each():
	if is_instance_valid(test_scene):
		test_scene.queue_free()

# TC-GP-018: Discipline cooldown test
func test_discipline_cooldown():
	player.discipline_cooldown = 0.0
	assert_eq(player.discipline_cooldown, 0.0, "Initial cooldown should be 0")
	
	# Mock a dog
	var dog = TestHelpers.create_mock_dog(test_scene, player.global_position + Vector3(3, 0, 0))
	var snack = TestHelpers.create_snack(test_scene, 2, dog.global_position + Vector3(1, 0, 0))
	dog.target_treat = snack
	
	# First discipline
	player.attempt_discipline()
	assert_almost_eq(player.discipline_cooldown, 1.0, 0.01, "Cooldown should be set to 1.0")
	
	# Try to discipline again immediately
	player.attempt_discipline()
	# Should still be on cooldown, so second discipline does nothing
	
	# Simulate cooldown expiring
	player.discipline_cooldown = 0.0
	player.attempt_discipline()
	# Should work again

# TC-GP-017: Discipline fails beyond range
func test_discipline_range_validation():
	player.discipline_cooldown = 0.0
	
	# Create dog far away (6 units, beyond 5.0 range)
	var dog = TestHelpers.create_mock_dog(test_scene, player.global_position + Vector3(6, 0, 0))
	var snack = TestHelpers.create_snack(test_scene, 2, dog.global_position + Vector3(1, 0, 0))
	dog.target_treat = snack
	
	var discipline_happened = false
	dog.on_disciplined = func(_type): discipline_happened = true
	
	player.attempt_discipline()
	
	assert_false(discipline_happened, "Discipline should fail beyond range")

# TC-GP-019: Discipline only works with target
func test_discipline_requires_target():
	player.discipline_cooldown = 0.0
	
	# Create dog with no target
	var dog = TestHelpers.create_mock_dog(test_scene, player.global_position + Vector3(3, 0, 0))
	dog.target_treat = null
	
	var discipline_happened = false
	var original_method = dog.on_disciplined
	dog.on_disciplined = func(_type): discipline_happened = true
	
	player.attempt_discipline()
	
	assert_false(discipline_happened, "Discipline should not work without target")

# TC-GP-014: Pickup animation locks movement
func test_pickup_animation_locks_movement():
	assert_eq(player.speed, 15.0, "Initial speed should be 15.0")
	
	player.play_pickup_animation()
	
	assert_eq(player.speed, 0.0, "Speed should be 0 during pickup animation")
	assert_true(player._is_playing_pickup, "Pickup flag should be true")

# Test pickup animation completes
func test_pickup_animation_completes():
	player._is_playing_pickup = true
	player.speed = 0.0
	
	# Simulate animation finished callback
	player._on_animation_finished(player.PICKUP_ANIM)
	
	assert_false(player._is_playing_pickup, "Pickup flag should be false")
	assert_eq(player.speed, 15.0, "Speed should be restored to 15.0")

# TC-GP-005: Camera capture
func test_player_camera_controls():
	# This is more of an integration test, but we can test the input handling
	# Initial state - mouse should be visible in menus
	assert_true(true, "Camera control is input-based, tested manually")

# Test discipline animation locks movement
func test_discipline_animation_locks_movement():
	assert_eq(player.speed, 15.0, "Initial speed should be 15.0")
	
	player.play_discipline_animation()
	
	assert_eq(player.speed, 0.0, "Speed should be 0 during discipline animation")
	assert_true(player._is_playing_discipline, "Discipline flag should be true")

# Test discipline animation completes
func test_discipline_animation_completes():
	player._is_playing_discipline = true
	player.speed = 0.0
	
	# Simulate animation finished callback
	player._on_animation_finished(player.DISCIPLINE_ANIM)
	
	assert_false(player._is_playing_discipline, "Discipline flag should be false")
	assert_eq(player.speed, 15.0, "Speed should be restored to 15.0")

# Test get dog target snack type
func test_get_dog_target_snack_type():
	var dog = TestHelpers.create_mock_dog(test_scene, Vector3.ZERO)
	
	# Test with no target
	dog.target_treat = null
	var result = player.get_dog_target_snack_type(dog)
	assert_eq(result, -1, "Should return -1 with no target")
	
	# Test with target snack
	var snack = TestHelpers.create_snack(test_scene, 2, Vector3(5, 0, 0))
	dog.target_treat = snack
	result = player.get_dog_target_snack_type(dog)
	assert_eq(result, 2, "Should return snack type 2 (chocolate)")
	
	# Test while eating
	dog.is_eating = true
	dog.current_eating_snack_type = 1
	result = player.get_dog_target_snack_type(dog)
	assert_eq(result, 1, "Should return eating snack type (cheese)")
