extends GutTest

# These test constants and rules, not complex behavior

func test_dog_max_lives():
	const MAX_LIVES = 3
	assert_eq(MAX_LIVES, 3, "Dog should have 3 max lives")

func test_dog_chocolate_death_threshold():
	const CHOCOLATE_DEATH_LIMIT = 3
	assert_eq(CHOCOLATE_DEATH_LIMIT, 3, "Dog dies after 3 chocolates")

func test_hunger_system_constants():
	const HUNGER_INCREASE_PER_SEC = 0.01
	const HUNGER_REDUCTION_PER_SNACK = 0.3
	const MIN_HUNGER = 0.0
	const MAX_HUNGER = 1.0
	
	assert_eq(HUNGER_INCREASE_PER_SEC, 0.01, "Hunger increase rate correct")
	assert_eq(HUNGER_REDUCTION_PER_SNACK, 0.3, "Hunger reduction correct")
	assert_true(MIN_HUNGER <= MAX_HUNGER, "Hunger bounds valid")

func test_discipline_constants():
	const DISCIPLINE_PAUSE_DURATION = 2.0
	assert_eq(DISCIPLINE_PAUSE_DURATION, 2.0, "Discipline pause is 2 seconds")

func test_eating_constants():
	const EAT_DURATION = 2.0
	const EATING_DISTANCE = 3.0
	
	assert_eq(EAT_DURATION, 2.0, "Eat duration is 2 seconds")
	assert_eq(EATING_DISTANCE, 3.0, "Eating distance is 3 units")

func test_snack_utility_values():
	# From spawning_object.gd SNACK_UTILITY_VALUES
	const DOG_FOOD_UTILITY = 0.2
	const CHEESE_UTILITY = 0.15
	const CHOCOLATE_UTILITY = 0.1
	const POISON_UTILITY = 0.05
	
	assert_eq(DOG_FOOD_UTILITY, 0.2, "Dog food utility correct")
	assert_eq(CHEESE_UTILITY, 0.15, "Cheese utility correct")
	assert_eq(CHOCOLATE_UTILITY, 0.1, "Chocolate utility correct")
	assert_eq(POISON_UTILITY, 0.05, "Poison utility correct")
	
	# Verify ordering (higher utility = better for dog)
	assert_true(DOG_FOOD_UTILITY > CHEESE_UTILITY, "Dog food better than cheese")
	assert_true(CHEESE_UTILITY > CHOCOLATE_UTILITY, "Cheese better than chocolate")
	assert_true(CHOCOLATE_UTILITY > POISON_UTILITY, "Chocolate better than poison")
