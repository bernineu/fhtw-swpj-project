extends CharacterBody3D

@export var speed: float = 12.0
@export var fall_acceleration: float = 75.0
@export var discipline_snack_radius: float = 3.0


# Discipline mechanic
@export_group("Discipline")
@export var discipline_range: float = 5.0  # Maximum range for discipline
@export var discipline_cooldown_duration: float = 1.0  # Cooldown in seconds
var discipline_cooldown: float = 0.0  # Current cooldown timer

var RUN_ANIM  := ""
var IDLE_ANIM := ""
var PICKUP_ANIM := ""
var DISCIPLINE_ANIM := ""

var anim: AnimationPlayer
var _is_playing_pickup := false
var _is_playing_discipline := false
@onready var pivot: Node3D = $Pivot

# 3rd Person camera
@export_group("Camera")
@export_range(0.0,1.0) var mouse_sensitivity := 0.25
var _camera_input_direction := Vector2.ZERO
@onready var _camera_pivot: Node3D = %CameraPivot


func _ready() -> void:
	# In Gruppe "player", damit Items uns finden können
	add_to_group("player")

	anim = pivot.find_child("AnimationPlayer", true, false)
	if anim:
		# Callback für Animationsende
		anim.animation_finished.connect(_on_animation_finished)

		for name in anim.get_animation_list():
			var lname := name.to_lower()

			if RUN_ANIM == "" and ("run" in lname or "walk" in lname):
				RUN_ANIM = name

			if IDLE_ANIM == "" and "idle" in lname:
				IDLE_ANIM = name

			# Neu: Sword/Pickup-Animation automatisch finden
			if PICKUP_ANIM == "" and ("sword" in lname or "slash" in lname or "attack" in lname):
				PICKUP_ANIM = name

			# Discipline animation: clapping
			if DISCIPLINE_ANIM == "" and "clap" in lname:
				DISCIPLINE_ANIM = name

		# Fallback, falls die obige Suche nichts findet
		if PICKUP_ANIM == "" and anim.has_animation("Female_SwordSlash"):
			PICKUP_ANIM = "Female_SwordSlash"

		# Debug:
		print("RUN_ANIM =", RUN_ANIM)
		print("IDLE_ANIM =", IDLE_ANIM)
		print("PICKUP_ANIM =", PICKUP_ANIM)
		print("DISCIPLINE_ANIM =", DISCIPLINE_ANIM)

		if RUN_ANIM != "" and anim.has_animation(RUN_ANIM):
			var a := anim.get_animation(RUN_ANIM)
			if a:
				a.loop_mode = Animation.LOOP_LINEAR


func _physics_process(delta: float) -> void:
	# --- CAMERA ROTATION ---
	_camera_pivot.rotation.x -= _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI / 6.0, PI / 3.0)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO

	# --- INPUT AS 2D VECTOR ---
	var input_vec := Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input_vec.x += 1.0
	if Input.is_action_pressed("move_left"):
		input_vec.x -= 1.0
	if Input.is_action_pressed("move_back"):
		input_vec.y -= 1.0      # -y = backwards
	if Input.is_action_pressed("move_forward"):
		input_vec.y += 1.0      # +y = forwards

	var dir := Vector3.ZERO

	if input_vec != Vector2.ZERO:
		input_vec = input_vec.normalized()

		# --- CAMERA-RELATIVE MOVEMENT ---
		var cam_basis := _camera_pivot.global_basis
		var forward := -cam_basis.z             # camera looks along -Z
		var right   := cam_basis.x

		# Combine forward/right using input
		dir = (right * input_vec.x) + (forward * input_vec.y)
		dir.y = 0.0                             # stay on ground
		dir = dir.normalized()

		# Turn the character in movement direction
		pivot.basis = Basis.looking_at(-dir, Vector3.UP)

	# --- VELOCITY ---
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	else:
		velocity.y = min(velocity.y, 0.0)

	move_and_slide()

	# --- DISCIPLINE MECHANIC ---
	# Update cooldown timer
	if discipline_cooldown > 0:
		discipline_cooldown -= delta

	# --- ANIMATION ---
	if anim and not _is_playing_pickup and not _is_playing_discipline:
		if dir != Vector3.ZERO and RUN_ANIM != "" and anim.current_animation != RUN_ANIM:
			anim.play(RUN_ANIM)
		elif dir == Vector3.ZERO and IDLE_ANIM != "" and anim.current_animation != IDLE_ANIM:
			anim.play(IDLE_ANIM)


func play_pickup_animation() -> void:
	if not anim:
		return
	if PICKUP_ANIM == "":
		print("play_pickup_animation: Keine Pickup-Animation gesetzt")
		return

	_is_playing_pickup = true
	anim.play(PICKUP_ANIM)
	print("Spiele Pickup-Animation:", PICKUP_ANIM)
	speed=0.0
	


func play_discipline_animation() -> void:
	if not anim:
		return
	if DISCIPLINE_ANIM == "":
		print("play_discipline_animation: Keine Discipline-Animation gesetzt")
		return

	_is_playing_discipline = true
	anim.play(DISCIPLINE_ANIM)
	print("Spiele Discipline-Animation:", DISCIPLINE_ANIM)
	speed = 0.0


func _on_animation_finished(anim_name: StringName) -> void:
	# Wenn die Pickup-Animation fertig ist, darf wieder Run/Idle laufen
	if anim_name == PICKUP_ANIM:
		_is_playing_pickup = false
		speed=12.0

	# Wenn die Discipline-Animation fertig ist, darf wieder Run/Idle laufen
	if anim_name == DISCIPLINE_ANIM:
		_is_playing_discipline = false
		speed=12.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lmb"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Handle discipline input (E key)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			attempt_discipline()


func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity


func attempt_discipline() -> void:
	"""Attempt to discipline the dog if within range and not on cooldown"""
	# Check cooldown
	if discipline_cooldown > 0:
		print("⏳ Discipline on cooldown: %.1f seconds remaining" % discipline_cooldown)
		return

	# Find the dog
	var dogs = get_tree().get_nodes_in_group("dog")
	if dogs.is_empty():
		print("❌ No dog found in scene")
		return

	var dog = dogs[0]  # Get the first dog

	# Check if dog is within discipline range
	var distance = global_position.distance_to(dog.global_position)
	if distance > discipline_range:
		print("❌ Dog too far away: %.1f units (max: %.1f)" % [distance, discipline_range])
		return

	# Nur disziplinieren, wenn Hund nahe bei einem Snack ist (oder isst/trägt)
	var snack_type := -1

	# Wenn Hund gerade isst: ok
	if "is_eating" in dog and dog.is_eating and "current_eating_snack_type" in dog:
		snack_type = dog.current_eating_snack_type
	# Wenn Hund Futter trägt (carrying_food): auch ok
	elif "carrying_food" in dog and dog.carrying_food and "carried_snack_type" in dog:
		snack_type = dog.carried_snack_type
	else:
		var nearby_treat: Node3D = null

		# 1) Wenn Hund ein target_treat hat und es ist nah: nimm das (am fairsten)
		if "target_treat" in dog and dog.target_treat != null and is_instance_valid(dog.target_treat):
			var dtt = dog.global_position.distance_to(dog.target_treat.global_position)
			if dtt <= discipline_snack_radius:
				nearby_treat = dog.target_treat

		# 2) Sonst: nimm nächstes Treat in Radius
		if nearby_treat == null:
			nearby_treat = get_nearby_treat_for_dog(dog, discipline_snack_radius)

		if nearby_treat == null:
			print("❌ Discipline: Hund ist nicht nahe bei einem Snack")
			return

		# snack_type aus dem Treat lesen
		if "snack_type" in nearby_treat:
			snack_type = nearby_treat.snack_type
		elif nearby_treat.get_parent() and "snack_type" in nearby_treat.get_parent():
			snack_type = nearby_treat.get_parent().snack_type

		if snack_type == -1:
			print("❌ Discipline: Treat hat keinen snack_type")
			return


	# Discipline the dog
	print("✅ Disciplining dog at distance: %.1f units" % distance)
	dog.on_disciplined(snack_type)

	# Set cooldown
	discipline_cooldown = discipline_cooldown_duration

	# Visual feedback - play clapping animation
	play_discipline_animation()

	# TODO: Add particle effect
	# TODO: Add sound effect


	
func get_nearby_treat_for_dog(dog: Node3D, radius: float) -> Node3D:
	# Sucht ein Treat in der Nähe des Hundes (innerhalb radius)
	var treats = get_tree().get_nodes_in_group("treats")
	var best: Node3D = null
	var best_dist := INF

	for t in treats:
		if t and is_instance_valid(t):
			var d = dog.global_position.distance_to(t.global_position)
			if d <= radius and d < best_dist:
				best_dist = d
				best = t

	return best
