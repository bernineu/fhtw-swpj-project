extends GutTest

var test_scene: Node3D
var dog: CharacterBody3D

func before_each():
	test_scene = TestHelpers.create_test_scene()
	add_child_autofree(test_scene)
	dog = TestHelpers.create_mock_dog(test_scene, Vector3.ZERO)

func after_each():
	if is_instance_valid(test_scene):
		test_scene.queue_free()

# TC-AI-010: Dog reduces hunger when eating
func test_dog_hunger_reduces_on_eating():
	dog.hunger = 0.5
	assert_eq(dog.hunger, 0.5, "Initial hunger should be 0.5")
	
	# Simulate eating dog food (type 0)
	dog.on_snack_eaten(0)
	
	assert_almost_eq(dog.hunger, 0.2, 0.01, "Hunger should reduce by 0.3 to 0.2")

# TC-AI-015: Dog hunger increases over time
func test_dog_hunger_increases_over_time():
	dog.hunger = 0.0
	
	# Simulate 10 seconds passing
	for i in range(10):
		dog.update_hunger(1.0)
	
	assert_almost_eq(dog.hunger, 0.1, 0.01, "Hunger should increase by 0.01/sec")

# TC-NEG-014: Dog hunger clamped at 1.0
func test_dog_hunger_clamped_at_max():
	dog.hunger = 0.95
	
	# Simulate 10 seconds (would go to 1.05)
	for i in range(10):
		dog.update_hunger(1.0)
	
	assert_eq(dog.hunger, 1.0, "Hunger should be clamped at 1.0")

# TC-AI-011: Dog tracks chocolate consumption
func test_dog_tracks_chocolate_eaten():
	dog.lives = 3
	dog.chocolate_eaten = 0
	
	# Eat first chocolate
	dog.on_snack_eaten(2)  # Type 2 = chocolate
	assert_eq(dog.chocolate_eaten, 1, "Chocolate counter should be 1")
	assert_eq(dog.lives, 3, "Lives should still be 3")
	
	# Eat second chocolate
	dog.on_snack_eaten(2)
	assert_eq(dog.chocolate_eaten, 2, "Chocolate counter should be 2")
	assert_eq(dog.lives, 3, "Lives should still be 3")

# TC-AI-012: Dog dies after 3 chocolates
func test_dog_dies_after_three_chocolates():
	dog.lives = 3
	dog.chocolate_eaten = 2
	var death_signaled = false
	
	dog.dog_died.connect(func(): death_signaled = true)
	
	# Eat third chocolate
	dog.on_snack_eaten(2)
	
	assert_true(dog.is_dead, "Dog should be dead after 3 chocolates")
	assert_true(death_signaled, "Death signal should be emitted")

# TC-AI-013: Dog dies instantly on poison
func test_dog_dies_instantly_on_poison():
	dog.lives = 3
	dog.is_dead = false
	var death_signaled = false
	
	dog.dog_died.connect(func(): death_signaled = true)
	
	# Eat poison (type 3)
	dog.on_snack_eaten(3)
	
	assert_true(dog.is_dead, "Dog should die instantly from poison")
	assert_true(death_signaled, "Death signal should be emitted")

# TC-AI-016: Dog pauses when disciplined
func test_dog_pauses_when_disciplined():
	dog.is_being_disciplined = false
	dog.current_eating_snack_type = 2  # Chocolate
	
	dog.on_disciplined(2)
	
	assert_true(dog.is_being_disciplined, "Dog should be in disciplined state")
	assert_almost_eq(dog.discipline_pause_timer, 2.0, 0.01, "Pause timer should be 2.0 seconds")
	assert_false(dog.is_eating, "Dog should stop eating")
	assert_null(dog.target_treat, "Target should be cleared")

# TC-AI-018: Dog resumes after discipline pause
func test_dog_resumes_after_discipline():
	dog.is_being_disciplined = true
	dog.discipline_pause_timer = 2.0
	
	# Simulate 2.1 seconds passing
	dog._physics_process(2.1)
	
	assert_false(dog.is_being_disciplined, "Dog should no longer be disciplined")

# Test dog doesn't move when eating
func test_dog_stops_moving_when_eating():
	dog.is_eating = true
	dog.eat_timer = 2.0
	dog.velocity = Vector3(5, 0, 5)
	
	dog._physics_process(0.1)
	
	assert_eq(dog.velocity.x, 0, "X velocity should be 0 when eating")
	assert_eq(dog.velocity.z, 0, "Z velocity should be 0 when eating")

# Test dog doesn't move when disciplined
func test_dog_stops_moving_when_disciplined():
	dog.is_being_disciplined = true
	dog.discipline_pause_timer = 1.0
	dog.velocity = Vector3(5, 0, 5)
	
	dog._physics_process(0.1)
	
	assert_eq(dog.velocity.x, 0, "X velocity should be 0 when disciplined")
	assert_eq(dog.velocity.z, 0, "Z velocity should be 0 when disciplined")

# Test dog lives system
func test_dog_lose_life():
	dog.lives = 3
	var signal_received = false
	var received_lives = -1
	
	dog.lives_changed.connect(func(new_lives):
		signal_received = true
		received_lives = new_lives
	)
	
	dog.lose_life()
	
	assert_eq(dog.lives, 2, "Lives should decrease to 2")
	assert_true(signal_received, "lives_changed signal should emit")
	assert_eq(received_lives, 2, "Signal should contain new lives value")

# Test dog dies at 0 lives
func test_dog_dies_at_zero_lives():
	dog.lives = 1
	dog.is_dead = false
	
	dog.lose_life()
	
	assert_true(dog.is_dead, "Dog should be dead at 0 lives")
	assert_eq(dog.lives, 0, "Lives should be 0")

# Test death state prevents duplicate deaths
func test_death_prevents_duplicate_trigger():
	dog.is_dead = true
	var death_count = 0
	
	dog.dog_died.connect(func(): death_count += 1)
	
	# Try to trigger death again
	dog.die()
	dog.die()
	
	assert_eq(death_count, 0, "Death should not trigger when already dead")
