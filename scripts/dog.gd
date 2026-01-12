extends CharacterBody3D

@export var speed: float = 12.0
@export var turn_min_deg: float = 30.0
@export var turn_max_deg: float = 800.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var rotation_speed: float = 5.0  # How fast the dog turns toward target (radians/sec)

var pending_snack_type: int = -1
var is_eating: bool = false
var eat_timer: float = 0.0
var current_eating_snack_type: int = -1  # Track what snack is being eaten
@export var eat_duration: float = 4.0

# Carrying food state (when fleeing while eating)
var carrying_food: bool = false
var carried_snack_type: int = -1
var carrying_food_timer: float = 0.0
const FINISH_CARRIED_FOOD_DELAY: float = 3.0  # Seconds before finishing carried food
var carried_food_visual: Node3D = null  # Reference to the visual food node

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
signal discipline_changed(snack_type: int, count: int)

var anim_player: AnimationPlayer
var nav_agent: NavigationAgent3D
var target_treat: Node3D = null

# Stuck detection for unreachable snacks
var stuck_detection_timer: float = 0.0
var last_position: Vector3 = Vector3.ZERO
const STUCK_TIMEOUT: float = 5.0  # Give up on snack after 5 seconds of being stuck
const STUCK_DISTANCE_THRESHOLD: float = 0.5  # If moved less than 0.5 units, consider stuck

# --- Learning / Discipline memory (per snack type) ---
const SNACK_COUNT := 4  # DOG_FOOD, CHEESE, CHOCOLATE, POISON
@export var discipline_threshold_block := 3
# how many times dog was disciplined for each snack
var discipline_counts: Array[int] = [0, 0, 0, 0]
# strength of penalty per discipline (anpassbar!)
@export var discipline_penalty_per_count: float = 0.25  # 0.25*3 = 0.75 reduction

func is_snack_blocked(snack_type: int) -> bool:
	return snack_type >= 0 and snack_type < SNACK_COUNT and discipline_counts[snack_type] >= discipline_threshold_block


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
	
func _apply_eaten_snack_effect(snack_type: int) -> void:
	if snack_type < 0:
		return

	var snack_names = ["DOG_FOOD", "CHEESE", "CHOCOLATE", "POISON"]
	print("🐕 Finished eating:", snack_names[snack_type])

	# POISON -> death
	if snack_type == 3:
		die()
		return

	# Hunger reduzieren
	hunger -= HUNGER_REDUCTION_PER_SNACK
	hunger = clamp(hunger, 0.0, 1.0)
	hunger_changed.emit(hunger)

	# Chocolate -> life lose, und nach 3 chocolates sterben
	if snack_type == 2:
		chocolate_eaten += 1
		lose_life()  # <-- emits lives_changed, HUD updated
		print("🍫 Chocolate eaten: %d/3" % chocolate_eaten)

		if chocolate_eaten >= 3:
			die()


func can_eat_treat(treat: Node) -> bool:
	if treat == null or !is_instance_valid(treat):
		return false


	# snack type holen
	var st := -1
	if "snack_type" in treat:
		st = treat.snack_type
	elif treat.get_parent() and "snack_type" in treat.get_parent():
		st = treat.get_parent().snack_type

	# blocked?
	if st != -1 and is_snack_blocked(st):
		print("BLOCKED eat attempt:", st)
		return false
		

	# nur essen, wenn der Hund diese Aktion gewählt hat UND genau dieses Treat targetet
	if current_action != "EAT_SNACK":
		return false

	if target_treat == null or !is_instance_valid(target_treat):
		return false

	return target_treat == treat



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
	# nur merken, Effekt kommt erst am Ende
	current_eating_snack_type = snack_type
	pending_snack_type = snack_type

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
		lose_life()
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


		# 7. Discipline Modifier (learning system)
	# If snack is blocked after 3 disciplines -> never eat
	if snack_type >= 0 and snack_type < SNACK_COUNT:
		if is_snack_blocked(snack_type):
			return 0.0

		# otherwise reduce utility progressively
		var count := discipline_counts[snack_type]
		var discipline_penalty := float(count) * discipline_penalty_per_count
		utility -= discipline_penalty


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


func calculate_idle_utility() -> float:
	"""Calculate utility score for idling (doing nothing)

	Formula (from Regelwerk 3.4):
	Utility_IDLE = Base_Score + Orientierungs_Faktor + Disziplin_Faktor

	Returns: Utility score clamped to [0.0, 1.0]
	"""
	var utility: float = 0.0

	# 1. Base Score = 0.1 (low priority)
	const BASE_SCORE = 0.1
	utility += BASE_SCORE

	# 2. Orientation Factor (Orientierungs-Faktor)
	# If no clear action options, add bonus
	var orientation_factor = 0.0
	var treats = get_tree().get_nodes_in_group("treats")
	var player = get_tree().get_first_node_in_group("player")

	var has_treats = treats.size() > 0
	var player_nearby = false
	if player and is_instance_valid(player):
		var player_distance = global_position.distance_to(player.global_position)
		player_nearby = player_distance < 4.0

	# No clear options: no treats and player not nearby
	if not has_treats and not player_nearby:
		orientation_factor = 0.2
	utility += orientation_factor

	# 3. Discipline Factor (Disziplin-Faktor)
	# If recently disciplined (< 2 seconds), increase idle utility
	var discipline_factor = 0.0
	if is_being_disciplined:
		discipline_factor = 0.3
	utility += discipline_factor

	# Clamp final result to [0.0, 1.0]
	utility = clamp(utility, 0.0, 1.0)

	# Debug output
	if utility > 0.1:  # Only print if not baseline
		print("  💤 IDLE utility: %.2f (base:%.2f orientation:%.2f discipline:%.2f)"
			% [utility, BASE_SCORE, orientation_factor, discipline_factor])

	return utility


func evaluate_and_choose_action() -> void:
	"""Evaluate all possible actions and choose the one with highest utility

	Task 6: EAT_SNACK utility for all treats ✅
	Task 7: FLEE_FROM_OWNER utility ✅
	Task 8: Complete decision loop ✅
	"""

	print("🧠 Evaluating actions...")

	# Get all available treats
	var treats = get_tree().get_nodes_in_group("treats")

	# Calculate EAT_SNACK utility for each treat
	var best_eat_utility = 0.0
	var best_treat: Node3D = null

	for treat in treats:
		if treat and is_instance_valid(treat):
			var st := -1
			if "snack_type" in treat:
				st = treat.snack_type
			if st != -1 and is_snack_blocked(st):
				continue  # ignore blocked snacks completely			
			
			var utility = calculate_eat_utility(treat)
			if utility > best_eat_utility:
				best_eat_utility = utility
				best_treat = treat

	# Calculate FLEE utility
	var flee_utility = calculate_flee_utility()

	# Calculate IDLE utility
	var idle_utility = calculate_idle_utility()

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
	# Build list of possible actions with their utilities
	var actions = []
	if best_treat != null:
		actions.append({"name": "EAT_SNACK", "utility": best_eat_utility, "treat": best_treat})
	actions.append({"name": "FLEE", "utility": flee_utility, "treat": null})
	actions.append({"name": "IDLE", "utility": idle_utility, "treat": null})

	# Find maximum utility
	var max_utility = 0.0
	for action in actions:
		if action.utility > max_utility:
			max_utility = action.utility

	# Find all actions with max utility (handle ties)
	var best_actions = []
	for action in actions:
		if abs(action.utility - max_utility) < 0.001:  # Float comparison tolerance
			best_actions.append(action)

	# Choose action (random selection if tie)
	var chosen_action = null
	if best_actions.size() > 1:
		# Tie! Choose randomly
		var random_index = randi() % best_actions.size()
		chosen_action = best_actions[random_index]
		print("⚖️ Tie between %d actions - choosing randomly" % best_actions.size())
	else:
		chosen_action = best_actions[0]

	# Execute chosen action
	var previous_target = target_treat
	current_action = chosen_action.name
	target_treat = chosen_action.treat

	# Reset stuck timer if targeting a new snack
	if target_treat != previous_target:
		stuck_detection_timer = 0.0
		last_position = global_position

	if current_action == "EAT_SNACK":
		# Set navigation target
		if nav_agent and target_treat:
			nav_agent.set_target_position(target_treat.global_position)
		print("✅ Action: EAT_SNACK (utility: %.2f)" % best_eat_utility)
	elif current_action == "FLEE":
		print("✅ Action: FLEE (utility: %.2f)" % flee_utility)
	else:
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
		stuck_detection_timer = 0.0  # Reset timer when no target
		return

	# Check if dog is stuck (not moving much)
	var distance_moved = global_position.distance_to(last_position)

	if distance_moved < STUCK_DISTANCE_THRESHOLD:
		stuck_detection_timer += delta

		# Give up on snack if stuck too long
		if stuck_detection_timer >= STUCK_TIMEOUT:
			print("⚠️ Dog stuck trying to reach snack for %.1fs - giving up!" % stuck_detection_timer)
			target_treat = null
			stuck_detection_timer = 0.0
			velocity.x = 0
			velocity.z = 0
			return
	else:
		# Dog is moving, reset stuck timer
		stuck_detection_timer = 0.0

	# Update last position for next frame
	last_position = global_position

	# Navigate to treat
	if nav_agent.is_navigation_finished():
		velocity.x = 0
		velocity.z = 0
	elif !nav_agent.is_target_reachable():
		# Immediately give up on unreachable targets
		print("⚠️ Target not reachable - giving up on this snack!")
		target_treat = null
		stuck_detection_timer = 0.0
		velocity.x = 0
		velocity.z = 0
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

	Attaches/removes a small version of the snack model to the dog's mouth marker
	when carrying_food state changes.
	"""
	var food_carrier_marker = get_node_or_null("FoodCarrierMarker")

	if food_carrier_marker == null:
		push_error("FoodCarrierMarker not found in dog scene!")
		return

	# Remove existing visual if present
	if carried_food_visual != null and is_instance_valid(carried_food_visual):
		carried_food_visual.queue_free()
		carried_food_visual = null

	# Add new visual if carrying food
	if carrying_food and carried_snack_type >= 0:
		# Map snack type to scene path
		var snack_scene_paths = [
			"res://scenes/objects/dogfood.tscn",   # 0 = DOG_FOOD
			"res://scenes/objects/cheese.tscn",     # 1 = CHEESE
			"res://scenes/objects/chocolate.tscn",  # 2 = CHOCOLATE
			"res://scenes/objects/dogfood.tscn"     # 3 = POISON (use dogfood model for now)
		]

		if carried_snack_type < snack_scene_paths.size():
			var snack_scene = load(snack_scene_paths[carried_snack_type])
			if snack_scene:
				var snack_instance = snack_scene.instantiate()

				# Find the MeshInstance3D child (the visual part)
				var mesh_instance = snack_instance.find_child("MeshInstance3D", true, false)

				if mesh_instance:
					# Create a new Node3D to hold only the visual
					carried_food_visual = Node3D.new()
					food_carrier_marker.add_child(carried_food_visual)

					# Remove the mesh from the snack instance and add to our visual node
					mesh_instance.get_parent().remove_child(mesh_instance)
					carried_food_visual.add_child(mesh_instance)

					# Remove any physics bodies from the mesh instance
					for child in mesh_instance.get_children():
						if child is StaticBody3D or child is RigidBody3D or child is CharacterBody3D:
							child.queue_free()

					# Scale down the food (smaller in mouth)
					carried_food_visual.scale = Vector3(0.4, 0.4, 0.4)

					print("🍖 Visual: Dog now carrying %s" % ["DOG_FOOD", "CHEESE", "CHOCOLATE", "POISON"][carried_snack_type])
				else:
					push_error("MeshInstance3D not found in snack scene!")

				# Clean up the original snack instance
				snack_instance.queue_free()
			else:
				push_error("Failed to load snack scene: %s" % snack_scene_paths[carried_snack_type])
		else:
			push_error("Invalid snack type: %d" % carried_snack_type)
	else:
		print("🍖 Visual: Dog no longer carrying food")


## ============================================================================
## END PHASE 2 FRAMEWORK
## ============================================================================

func get_discipline_count(snack_type: int) -> int:  ## nur für initiierung
	if snack_type < 0 or snack_type >= SNACK_COUNT:
		return 0
	return discipline_counts[snack_type]


func on_disciplined(snack_type) -> void:
	"""Called when player disciplines the dog
	This will be expanded in Phase 4 with learning system (Tasks 9-11)
	snack_type: The type of snack the dog is targeting/eating
	"""
	var snack_names = ["DOG_FOOD", "CHEESE", "CHOCOLATE", "POISON"]
	var snack_name = snack_names[snack_type] if snack_type < snack_names.size() else "UNKNOWN"

	print("🚫 Dog disciplined for: ", snack_name)
	print("   Current action: ", "EATING" if is_eating else "MOVING_TO_SNACK")

		# --- Learning update ---
	if snack_type >= 0 and snack_type < SNACK_COUNT:
		discipline_counts[snack_type] = min(discipline_counts[snack_type] + 1, discipline_threshold_block)
		discipline_changed.emit(snack_type, discipline_counts[snack_type])
		print("📘 Learned: discipline for %s = %d/%d"
			% [snack_name, discipline_counts[snack_type], discipline_threshold_block])

		# If now blocked, immediately drop target if it's that snack
		if is_snack_blocked(snack_type):
			print("🚫 %s is now BLOCKED. Dog will not eat it anymore." % snack_name)

	# Stop current action and pause
	is_being_disciplined = true
	discipline_pause_timer = DISCIPLINE_PAUSE_DURATION

	# Stop eating if currently eating
	is_eating = false
	eat_timer = 0.0
	current_eating_snack_type = -1  # Clear eating snack type

	# Drop carried food if carrying
	if carrying_food:
		print("🍖 Dog disciplined while carrying food - dropping it!")
		carrying_food = false
		carried_snack_type = -1
		carrying_food_timer = 0.0
		update_carrying_food_visual()  # Remove visual

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
