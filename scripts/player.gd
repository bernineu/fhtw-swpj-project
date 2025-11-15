extends CharacterBody3D

@export var speed: float = 15.0
@export var fall_acceleration: float = 75.0

var RUN_ANIM  := ""
var IDLE_ANIM := ""
var PICKUP_ANIM := ""

var anim: AnimationPlayer
var _is_playing_pickup := false
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

		# Fallback, falls die obige Suche nichts findet
		if PICKUP_ANIM == "" and anim.has_animation("Female_SwordSlash"):
			PICKUP_ANIM = "Female_SwordSlash"

		# Debug:
		print("RUN_ANIM =", RUN_ANIM)
		print("IDLE_ANIM =", IDLE_ANIM)
		print("PICKUP_ANIM =", PICKUP_ANIM)

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

	# --- ANIMATION ---
	if anim and not _is_playing_pickup:
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


func _on_animation_finished(anim_name: StringName) -> void:
	# Wenn die Pickup-Animation fertig ist, darf wieder Run/Idle laufen
	if anim_name == PICKUP_ANIM:
		_is_playing_pickup = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lmb"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity
