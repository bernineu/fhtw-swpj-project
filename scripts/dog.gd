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

# Signals for UI updates
signal lives_changed(new_lives: int)
signal hunger_changed(new_hunger: float)
signal dog_died

var anim_player: AnimationPlayer
var nav_agent: NavigationAgent3D
var target_treat: Node3D = null
var target_update_timer: float = 0.0
const TARGET_UPDATE_INTERVAL: float = 0.5  # Update target every 0.5 seconds

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

	# --- NEU: Wenn der Hund frisst, nur Animation laufen lassen ---
	if is_eating:
		eat_timer -= delta
		if eat_timer <= 0.0:
			is_eating = false
			current_eating_snack_type = -1  # Clear eating snack type
			# Nach dem Fressen wieder Gallop + neues Ziel suchen
			if anim_player and anim_player.has_animation("Gallop"):
				anim_player.play("Gallop")
			find_nearest_treat()

		# Während des Fressens nicht horizontal bewegen
		velocity.x = 0
		velocity.z = 0

		# Gravity trotzdem normal
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0

		move_and_slide()
		return
	# --- ENDE NEU ---

	# Update target treat periodically
	target_update_timer += delta
	if target_update_timer >= TARGET_UPDATE_INTERVAL:
		target_update_timer = 0.0
		find_nearest_treat()

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

	print("📍 Dog at: ", global_position, " | Next waypoint: ", next_path_position)
	print("🗺️ Path length: ", nav_agent.get_current_navigation_path().size())

	# Calculate direction to next waypoint
	var direction = (next_path_position - global_position).normalized()

	# Only zero out Y if we're close to the navmesh height, otherwise allow vertical movement
	var y_distance = abs(next_path_position.y - global_position.y)
	if y_distance < 0.5:
		direction.y = 0  # Keep movement horizontal when close to target height

	print("➡️ Direction: ", direction, " | Length: ", direction.length())

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
		print("🏃 Moving! Velocity: ", velocity)
	else:
		velocity.x = 0
		velocity.z = 0
		print("⏸️ Not moving - direction too small")


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

	var old_hunger = hunger
	print("🐕 Dog ate: ", snack_name, " (type: ", snack_type, ")")
	print("   Hunger before: %.2f" % old_hunger)

	# Check for POISON (instant death)
	# 0=DOG_FOOD, 1=CHEESE, 2=CHOCOLATE, 3=POISON
	if snack_type == 3:  # POISON
		print("☠️ Dog ate POISON - instant death!")
		die()
		return

	# Reduce hunger
	hunger -= HUNGER_REDUCTION_PER_SNACK
	hunger = clamp(hunger, 0.0, 1.0)
	print("   Hunger after: %.2f" % hunger)
	hunger_changed.emit(hunger)

	# Track chocolate consumption for death mechanic
	if snack_type == 2:  # CHOCOLATE
		chocolate_eaten += 1
		print("🍫 Chocolate eaten: ", chocolate_eaten, "/3")

		# Check if dog ate 3 chocolates (death condition)
		if chocolate_eaten >= 3:
			print("☠️ Dog ate 3 chocolates - death!")
			die()


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

	# Play idle animation
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle")

	print("   Dog paused for %.1f seconds" % DISCIPLINE_PAUSE_DURATION)

	# TODO Phase 4 (Task 9): Increment discipline counter for this snack type
	# TODO Phase 4 (Task 10): Start 10-second short-term learning timer
	# TODO Phase 4 (Task 11): Apply progressive learning modifiers

	# Placeholder: Just log for now
	# In Phase 4, this will affect the dog's utility calculations
