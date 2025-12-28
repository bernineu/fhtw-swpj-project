extends CharacterBody3D

@export var speed: float = 14.0
@export var turn_min_deg: float = 30.0
@export var turn_max_deg: float = 800.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var rotation_speed: float = 5.0  # How fast the dog turns toward target (radians/sec)

var is_eating: bool = false
var eat_timer: float = 0.0
var current_eating_snack_type: int = -1  # Track what snack is being eaten
@export var eat_duration: float = 2.0

# Carrying food state (when fleeing while eating)
var carrying_food: bool = false
var carried_snack_type: int = -1
var carrying_food_timer: float = 0.0
const FINISH_CARRIED_FOOD_DELAY: float = 3.0  # Seconds before finishing carried food

# Lives and Hunger System
var lives: int = 3
const MAX_LIVES: int = 3
var hunger: float = 0.0
const HUNGER_INCREASE_PER_SEC: float = 0.01
const HUNGER_REDUCTION_PER_SNACK: float = 0.3

# Chocolate counter for death mechanic
var chocolate_eaten: int = 0

# Death state
var is_dead: bool = false

# Discipline state
var is_being_disciplined: bool = false
var discipline_pause_timer: float = 0.0
const DISCIPLINE_PAUSE_DURATION: float = 2.0  # Dog pauses for 2 seconds when disciplined

# Utility AI state tracking (Phase 2)
var current_action: String = "IDLE"
var utility_update_timer: float = 0.0
const UTILITY_UPDATE_INTERVAL: float = 0.3  # Evaluate utility every 0.3 seconds

# Signals for UI updates
signal lives_changed(new_lives: int)
signal hunger_changed(new_hunger: float)
signal dog_died

var anim_player: AnimationPlayer
var nav_agent: NavigationAgent3D
var target_treat: Node3D = null

func _ready():
	add_to_group("dog")
	anim_player = find_child("AnimationPlayer")
	if anim_player and anim_player.has_animation("Gallop"):
		var anim = anim_player.get_animation("Gallop")
		anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.play("Gallop")

	nav_agent = $NavigationAgent3D
	call_deferred("_setup_navigation")

	# Debug: Print initial state
	print("🐕 Dog initialized - Lives: %d, Hunger: %.2f" % [lives, hunger])                

func play_eat_animation():
	# Wird vom spawning_object.gd aufgerufen
	is_eating = true
	eat_timer = eat_duration

	# Aktuelles Ziel verwerfen (dieses Treat verschwindet ja gleich)
	target_treat = null
	if nav_agent:
		nav_agent.set_target_position(global_position)

	if anim_player and anim_player.has_animation("Eating"):
		var anim = anim_player.get_animation("Eating")
		anim.loop_mode = Animation.LOOP_NONE
		anim_player.play("Eating")


func _setup_navigation():
	"""Called after navigation is ready"""
	print("🐕 Dog navigation setup complete")
	# Wait for the navigation map to be ready
	await get_tree().physics_frame
	# Initial target search
	find_nearest_treat()


func _physics_process(delta):
	# Death check (highest priority)
	if is_dead:
		return

	# keep the dog upright
	rotation.x = 0.0
	rotation.z = 0.0

	# Update hunger (increases over time)
	update_hunger(delta)

	# --- Discipline pause (second priority) ---
	if is_being_disciplined:
		discipline_pause_timer -= delta
		if discipline_pause_timer <= 0.0:
			is_being_disciplined = false
			# Resume normal animation
			if anim_player and anim_player.has_animation("Gallop"):
				anim_player.play("Gallop")

		# Stop all movement while disciplined
		velocity.x = 0
		velocity.z = 0

		# Gravity still applies
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0

		move_and_slide()
		return

	# Update eating timer (but allow utility AI to interrupt)
	if is_eating:
		eat_timer -= delta
		if eat_timer <= 0.0:
			is_eating = false
			current_eating_snack_type = -1  # Clear eating snack type
			# Nach dem Fressen wieder Gallop
			if anim_player and anim_player.has_animation("Gallop"):
				anim_player.play("Gallop")
		# Note: No early return - let utility AI decide whether to continue eating or flee

	# Update carrying food timer
	if carrying_food:
		carrying_food_timer += delta
		if carrying_food_timer >= FINISH_CARRIED_FOOD_DELAY:
			finish_carried_food()
			carrying_food_timer = 0.0

	# =========================================================================
	# PHASE 2: UTILITY AI DECISION LOOP
	# =========================================================================

	# Utility evaluation (every 0.3 seconds)
	utility_update_timer += delta
	if utility_update_timer >= UTILITY_UPDATE_INTERVAL:
		utility_update_timer = 0.0
		evaluate_and_choose_action()

	# Check if we need to navigate vertically (to disable gravity)
	var navigating_vertically = false
	if nav_agent.get_current_navigation_path().size() > 0:
		var next_pos = nav_agent.get_next_path_position()
		navigating_vertically = abs(next_pos.y - global_position.y) >= 0.5

	# Apply gravity only when not navigating vertically
	if not navigating_vertically:
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0

	# Execute current action (replaces old movement logic)
	execute_current_action(delta)

	move_and_slide()


func find_nearest_treat():
	"""Find the nearest treat in the scene and set it as navigation target"""
	var treats = get_tree().get_nodes_in_group("treats")

	print("🍖 Found ", treats.size(), " treats in scene")

	if treats.is_empty():
		target_treat = null
		print("⚠️ No treats available")
		return

	var nearest_dist = INF
	var nearest_treat = null

	for treat in treats:
		if treat and is_instance_valid(treat):
			var dist = global_position.distance_to(treat.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_treat = treat

	target_treat = nearest_treat

	# Set navigation target to the nearest treat
	if target_treat != null:
		# Use treat's actual position - the navmesh will handle the Y coordinate
		nav_agent.set_target_position(target_treat.global_position)
		print("🎯 Target set to treat at: ", target_treat.global_position)
		print("🗺️ Navigation map valid: ", nav_agent.get_navigation_map().is_valid())
		print("📍 Dog position: ", global_position)
		print("🔢 Nav layers: ", nav_agent.navigation_layers)


func move_along_navigation_path(delta: float):
	"""Follow the path calculated by NavigationAgent3D"""

	# Check if navigation agent has a valid path
	if nav_agent.get_current_navigation_path().size() == 0:
		print("❌ No navigation path available")
		return

	# Get the next position in the path
	var next_path_position = nav_agent.get_next_path_position()

	# Debug: Uncomment for detailed navigation debugging
	# print("📍 Dog at: ", global_position, " | Next waypoint: ", next_path_position)
	# print("🗺️ Path length: ", nav_agent.get_current_navigation_path().size())

	# Calculate direction to next waypoint
	var direction = (next_path_position - global_position).normalized()

	# Only zero out Y if we're close to the navmesh height, otherwise allow vertical movement
	var y_distance = abs(next_path_position.y - global_position.y)
	if y_distance < 0.5:
		direction.y = 0  # Keep movement horizontal when close to target height

	# Debug: Uncomment for direction debugging
	# print("➡️ Direction: ", direction, " | Length: ", direction.length())

	if direction.length() > 0.01:
		# Calculate target rotation to face the next waypoint (for visual orientation)
		var horizontal_dir = Vector3(direction.x, 0, direction.z).normalized()
		if horizontal_dir.length() > 0.01:
			var target_rotation = atan2(horizontal_dir.x, horizontal_dir.z)
			var current_rotation = rotation.y

			# Smoothly rotate toward target
			var angle_diff = target_rotation - current_rotation
			# Normalize angle to -PI to PI range
			while angle_diff > PI:
				angle_diff -= 2 * PI
			while angle_diff < -PI:
				angle_diff += 2 * PI

			# Apply smooth rotation
			rotation.y += sign(angle_diff) * min(abs(angle_diff), rotation_speed * delta)

		# Always move directly toward the waypoint (not based on rotation)
		if y_distance >= 0.5:
			# Allow vertical movement when far from target height
			velocity = direction * speed
		else:
			# Move horizontally toward waypoint
			velocity.x = horizontal_dir.x * speed
			velocity.z = horizontal_dir.z * speed
		# Debug: Uncomment for velocity debugging
		# print("🏃 Moving! Velocity: ", velocity)
	else:
		velocity.x = 0
		velocity.z = 0
		# Debug: Uncomment for movement debugging
		# print("⏸️ Not moving - direction too small")


func update_hunger(delta: float) -> void:
	"""Increase hunger over time"""
	var old_hunger = hunger
	hunger += HUNGER_INCREASE_PER_SEC * delta
	hunger = clamp(hunger, 0.0, 1.0)

	# Only log every 5 seconds to avoid spam
	if int(old_hunger * 100) % 50 == 0 and int(hunger * 100) % 50 != 0:
		print("😋 Hunger level: %.2f" % hunger)

	hunger_changed.emit(hunger)


func on_snack_eaten(snack_type) -> void:
	"""Called by spawning_object when dog eats a snack"""
	# Store the snack type being eaten (for discipline mechanic)
	current_eating_snack_type = snack_type

	var snack_names = ["DOG_FOOD", "CHEESE", "CHOCOLATE", "POISON"]
	var snack_name = snack_names[snack_type] if snack_type < snack_names.size() else "UNKNOWN"

	print("🐕 Dog ate: ", snack_name)

	# Debug: Uncomment for detailed hunger tracking
	# var old_hunger = hunger
	# print("   Hunger before: %.2f" % old_hunger)

	# Check for POISON (instant death)
	# 0=DOG_FOOD, 1=CHEESE, 2=CHOCOLATE, 3=POISON
	if snack_type == 3:  # POISON
		die()  # die() will print the death message
		return

	# Reduce hunger
	hunger -= HUNGER_REDUCTION_PER_SNACK
	hunger = clamp(hunger, 0.0, 1.0)
	# Debug: Uncomment for detailed hunger tracking
	# print("   Hunger after: %.2f" % hunger)
	hunger_changed.emit(hunger)

	# Track chocolate consumption for death mechanic
	if snack_type == 2:  # CHOCOLATE
		chocolate_eaten += 1
		print("🍫 Chocolate eaten: %d/3" % chocolate_eaten)

		# Check if dog ate 3 chocolates (death condition)
		if chocolate_eaten >= 3:
			die()  # die() will print the death message


func lose_life() -> void:
	"""Reduce lives by 1 and emit signal"""
	lives -= 1
	lives = max(lives, 0)
	lives_changed.emit(lives)
	print("💔 Dog lost a life! Lives remaining: ", lives)

	# Check if out of lives
	if lives <= 0:
		die()


func die() -> void:
	"""Handle dog death"""
	if is_dead:
		return  # Already dead

	is_dead = true
	print("💀 Dog died! Game Over!")

	# Stop all movement
	velocity = Vector3.ZERO
	target_treat = null

	# Stop eating animation if active
	is_eating = false

	# Play death animation if available
	if anim_player and anim_player.has_animation("Death"):
		anim_player.play("Death")
	else:
		# Fallback: stop current animation
		if anim_player:
			anim_player.stop()

	# Emit death signal
	dog_died.emit()

	# Trigger game over in GameState
	if GameState.has_method("trigger_dog_death_game_over"):
		GameState.trigger_dog_death_game_over()


## ============================================================================
## PHASE 2: UTILITY AI FRAMEWORK
## ============================================================================

func calculate_eat_utility(treat: Node3D) -> float:
	"""Calculate utility score for eating a specific treat

	Formula (from Regelwerk 3.1):
	Utility_EAT = Base_Score + Hunger_Faktor + Snack_Wert_Faktor
	              - Distanz_Faktor - Besitzer_Gefahr_Faktor
	              - Leben_Risiko_Faktor + Disziplin_Modifier

	Returns: Utility score clamped to [0.0, 1.0]
	"""
	if treat == null or !is_instance_valid(treat):
		return 0.0

	var utility: float = 0.0

	# 1. Base Score = 0.7
	const BASE_SCORE = 0.7
	utility += BASE_SCORE

	# 2. Hunger Factor: hunger * 0.3 (linear scaling, max 0.3)
	var hunger_factor = hunger * 0.3
	utility += hunger_factor

	# 3. Snack Value Factor (from Regelwerk Section 3.1, lines 66-70)
	var snack_value_factor = 0.0
	var snack_type = -1
	if "snack_type" in treat:
		snack_type = treat.snack_type
		# Enum: DOG_FOOD=0, CHEESE=1, CHOCOLATE=2, POISON=3
		match snack_type:
			0:  # Hundefutter (DOG_FOOD)
				snack_value_factor = 0.2
			1:  # Käse (CHEESE)
				snack_value_factor = 0.15
			2:  # Schokolade (CHOCOLATE)
				snack_value_factor = 0.1
			3:  # Gift (POISON)
				snack_value_factor = 0.05
	utility += snack_value_factor

	# 4. Distance Factor: (distance / max_sight_range) * 0.2
	const MAX_SIGHT_RANGE = 20.0
	var distance = global_position.distance_to(treat.global_position)
	var distance_factor = (distance / MAX_SIGHT_RANGE) * 0.2
	utility -= distance_factor

	# 5. Player Danger Factor (Besitzer-Gefahr-Faktor)
	var player_danger_factor = 0.0
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var player_distance = global_position.distance_to(player.global_position)
		if player_distance < 3.0:
			player_danger_factor = 0.3  # High danger
		# 3-5 units and >5 units: 0.0 (no penalty)
	utility -= player_danger_factor

	# 6. Life Risk Factor (Leben-Risiko-Faktor) - from Regelwerk lines 82-90
	var life_risk_factor = 0.0
	if snack_type == 2:  # CHOCOLATE
		match lives:
			3:
				life_risk_factor = 0.0
			2:
				life_risk_factor = 0.1  # Increased caution
			1:
				life_risk_factor = 0.3  # Strong caution
			_:
				life_risk_factor = 0.5  # 0 lives - maximum caution
	elif snack_type == 3:  # POISON
		match lives:
			3:
				life_risk_factor = 0.0
			2:
				life_risk_factor = 0.0  # No extra caution yet
			1:
				life_risk_factor = 0.2  # Light caution
			_:
				life_risk_factor = 0.5  # Maximum caution
	utility -= life_risk_factor

	# 7. Discipline Modifier (placeholder for Phase 4, Tasks 9-11)
	# TODO Phase 4: Implement discipline learning system
	var discipline_modifier = 0.0
	utility += discipline_modifier

	# Clamp final result to [0.0, 1.0]
	utility = clamp(utility, 0.0, 1.0)

	# Debug output (can be removed later)
	if utility > 0.0:
		var snack_name = ["DOG_FOOD", "CHEESE", "CHOCOLATE", "POISON"][snack_type] if snack_type >= 0 else "UNKNOWN"
		print("  🍖 %s utility: %.2f (base:%.2f hunger:%.2f snack:%.2f -dist:%.2f -danger:%.2f -risk:%.2f)"
			% [snack_name, utility, BASE_SCORE, hunger_factor, snack_value_factor,
			   distance_factor, player_danger_factor, life_risk_factor])

	return utility


func calculate_flee_utility() -> float:
	"""Calculate utility score for fleeing from the player

	Formula (from Regelwerk 3.2):
	Utility_FLEE = Base_Score + Bedrohungs_Faktor + Fress_Schutz_Faktor
	               - Snack_Opportunitäts_Faktor

	Returns: Utility score clamped to [0.0, 1.0]
	"""
	var utility: float = 0.0

	# 1. Base Score = 0.3
	const BASE_SCORE = 0.3
	utility += BASE_SCORE

	# 2. Threat Factor (Bedrohungs-Faktor) based on player distance
	var threat_factor = 0.0
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var player_distance = global_position.distance_to(player.global_position)
		if player_distance < 2.0:
			threat_factor = 0.5  # Very close - high threat
		elif player_distance < 4.0:
			threat_factor = 0.2  # Medium distance - moderate threat
		# > 4 units: 0.0 (no threat)
	utility += threat_factor

	# 3. Eating Protection Factor (Fress-Schutz-Faktor)
	var eating_protection_factor = 0.0
	if is_eating:
		eating_protection_factor = 0.4  # Want to flee while eating to protect food
	utility += eating_protection_factor

	# 4. Snack Opportunity Factor (Snack-Opportunitäts-Faktor)
	# If there's a safe snack nearby, reduce flee utility (prefer eating)
	var snack_opportunity_factor = 0.0
	if player and is_instance_valid(player):
		var treats = get_tree().get_nodes_in_group("treats")
		for treat in treats:
			if treat and is_instance_valid(treat):
				var player_to_treat = player.global_position.distance_to(treat.global_position)
				if player_to_treat > 5.0:
					# Safe snack found (far from player)
					snack_opportunity_factor = 0.2
					break
	utility -= snack_opportunity_factor

	# Clamp final result to [0.0, 1.0]
	utility = clamp(utility, 0.0, 1.0)

	# Debug output
	if utility > 0.0:
		print("  🏃 FLEE utility: %.2f (base:%.2f threat:%.2f eating:%.2f -opportunity:%.2f)"
			% [utility, BASE_SCORE, threat_factor, eating_protection_factor, snack_opportunity_factor])

	return utility


func evaluate_and_choose_action() -> void:
	"""Evaluate all possible actions and choose the one with highest utility

	Task 6: EAT_SNACK utility for all treats ✅
	Task 7: FLEE_FROM_OWNER utility ✅
	TODO Task 8: Compare utilities and choose best action
	"""

	print("🧠 Evaluating actions...")

	# Get all available treats
	var treats = get_tree().get_nodes_in_group("treats")

	# Calculate EAT_SNACK utility for each treat
	var best_eat_utility = 0.0
	var best_treat: Node3D = null

	for treat in treats:
		if treat and is_instance_valid(treat):
			var utility = calculate_eat_utility(treat)
			if utility > best_eat_utility:
				best_eat_utility = utility
				best_treat = treat

	# Calculate FLEE utility
	var flee_utility = calculate_flee_utility()

	# TODO Task 8: Calculate other action utilities (IDLE, POOP, etc.)
	var idle_utility = 0.1  # Low baseline

	# Special handling: If currently eating, decide whether to interrupt
	if is_eating:
		# While eating, only flee if flee utility is significantly high
		if flee_utility > 0.6:  # High threshold to interrupt eating
			# Interrupt eating to flee WITH the food!
			carrying_food = true
			carried_snack_type = current_eating_snack_type
			carrying_food_timer = 0.0  # Reset timer
			is_eating = false
			current_eating_snack_type = -1

			if anim_player and anim_player.has_animation("Gallop"):
				anim_player.play("Gallop")

			current_action = "FLEE"
			target_treat = null
			print("⚠️ Interrupting eating to FLEE WITH FOOD! (utility: %.2f)" % flee_utility)

			# TODO: Visualize carrying food (assign to team member)
			update_carrying_food_visual()
		else:
			# Continue eating (stay idle)
			current_action = "IDLE"
			print("✅ Action: Continue eating (flee utility too low: %.2f)" % flee_utility)
		return

	# Normal utility comparison when not eating
	var max_utility = max(best_eat_utility, flee_utility, idle_utility)

	if max_utility == best_eat_utility and best_treat != null:
		current_action = "EAT_SNACK"
		target_treat = best_treat
		# Set navigation target
		if nav_agent:
			nav_agent.set_target_position(best_treat.global_position)
		print("✅ Action: EAT_SNACK (utility: %.2f)" % best_eat_utility)
	elif max_utility == flee_utility:
		current_action = "FLEE"
		target_treat = null
		print("✅ Action: FLEE (utility: %.2f)" % flee_utility)
	else:
		current_action = "IDLE"
		target_treat = null
		print("✅ Action: IDLE (utility: %.2f)" % idle_utility)


func execute_current_action(delta: float) -> void:
	"""Execute the currently selected action
	This will be expanded in Task 8 with FLEE and other actions"""

	match current_action:
		"EAT_SNACK":
			execute_eat_snack(delta)
		"FLEE":
			execute_flee(delta)
		"IDLE":
			execute_idle(delta)
		_:
			# Default to idle if unknown action
			execute_idle(delta)


func execute_eat_snack(delta: float) -> void:
	"""Navigate to and eat the target treat"""
	# Move toward navigation target using NavigationAgent3D
	if target_treat == null or !is_instance_valid(target_treat):
		velocity.x = 0
		velocity.z = 0
	elif nav_agent.is_navigation_finished():
		velocity.x = 0
		velocity.z = 0
	elif !nav_agent.is_target_reachable():
		velocity.x = 0
		velocity.z = 0
		print("⚠️ Target not reachable!")
	else:
		move_along_navigation_path(delta)


func execute_flee(delta: float) -> void:
	"""Flee away from the player"""
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		# Calculate direction away from player
		var to_player = player.global_position - global_position
		to_player.y = 0  # Keep on horizontal plane
		var flee_direction = -to_player.normalized()  # Opposite of player direction

		# Move directly away (simple flee - no pathfinding)
		velocity.x = flee_direction.x * speed
		velocity.z = flee_direction.z * speed

		# Rotate to face flee direction
		if flee_direction.length() > 0.01:
			var target_rotation = atan2(flee_direction.x, flee_direction.z)
			rotation.y = target_rotation
	else:
		# No player found - stop
		velocity.x = 0
		velocity.z = 0


func execute_idle(delta: float) -> void:
	"""Do nothing - stand still"""
	velocity.x = 0
	velocity.z = 0


func finish_carried_food() -> void:
	"""Finish eating the food the dog is carrying
	Called after fleeing to safety or after enough time has passed"""
	if not carrying_food:
		return

	var snack_names = ["DOG_FOOD", "CHEESE", "CHOCOLATE", "POISON"]
	var snack_name = snack_names[carried_snack_type] if carried_snack_type < snack_names.size() else "UNKNOWN"

	print("🐕 Dog finished eating carried food: ", snack_name)

	# Apply the food effects (hunger reduction, chocolate counter, etc.)
	# Reduce hunger
	hunger -= HUNGER_REDUCTION_PER_SNACK
	hunger = clamp(hunger, 0.0, 1.0)
	hunger_changed.emit(hunger)

	# Track chocolate consumption
	if carried_snack_type == 2:  # CHOCOLATE
		chocolate_eaten += 1
		print("🍫 Chocolate eaten: %d/3" % chocolate_eaten)
		if chocolate_eaten >= 3:
			die()

	# Check for POISON
	if carried_snack_type == 3:  # POISON
		die()

	# Clear carrying state
	carrying_food = false
	carried_snack_type = -1

	# TODO: Remove visual indicator (assign to team member)
	update_carrying_food_visual()


func update_carrying_food_visual() -> void:
	"""Update visual representation of dog carrying food

	TODO: Implement visual feedback (assign to team member)
	Options:
	- Attach treat model to dog's mouth/head
	- Show particle effects (food crumbs)
	- Display icon above dog
	- Play special animation if available
	- Change dog's appearance/color tint

	Current state can be checked with:
	- carrying_food (bool): Is the dog carrying food?
	- carried_snack_type (int): What type of snack? (0=DOG_FOOD, 1=CHEESE, 2=CHOCOLATE, 3=POISON)
	"""
	# Placeholder - no visual changes yet
	pass


## ============================================================================
## END PHASE 2 FRAMEWORK
## ============================================================================

func on_disciplined(snack_type) -> void:
	"""Called when player disciplines the dog
	This will be expanded in Phase 4 with learning system (Tasks 9-11)
	snack_type: The type of snack the dog is targeting/eating
	"""
	var snack_names = ["DOG_FOOD", "CHEESE", "CHOCOLATE", "POISON"]
	var snack_name = snack_names[snack_type] if snack_type < snack_names.size() else "UNKNOWN"

	print("🚫 Dog disciplined for: ", snack_name)
	print("   Current action: ", "EATING" if is_eating else "MOVING_TO_SNACK")

	# Stop current action and pause
	is_being_disciplined = true
	discipline_pause_timer = DISCIPLINE_PAUSE_DURATION

	# Stop eating if currently eating
	is_eating = false
	eat_timer = 0.0
	current_eating_snack_type = -1  # Clear eating snack type

	# Clear current target
	target_treat = null
	if nav_agent:
		nav_agent.set_target_position(global_position)

	# Play submissive/disciplined animation (head low = ashamed)
	if anim_player:
		if anim_player.has_animation("Idle_2_HeadLow"):
			anim_player.play("Idle_2_HeadLow")
		elif anim_player.has_animation("Idle"):
			anim_player.play("Idle")

	print("   Dog paused for %.1f seconds" % DISCIPLINE_PAUSE_DURATION)

	# TODO Phase 4 (Task 9): Increment discipline counter for this snack type
	# TODO Phase 4 (Task 10): Start 10-second short-term learning timer
	# TODO Phase 4 (Task 11): Apply progressive learning modifiers

	# Placeholder: Just log for now
	# In Phase 4, this will affect the dog's utility calculations
