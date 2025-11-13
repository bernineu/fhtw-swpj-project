extends CharacterBody3D

@export var speed: float = 15.0

@export var fall_acceleration: float = 75.0

var RUN_ANIM  := ""
var IDLE_ANIM := ""

var anim: AnimationPlayer
@onready var pivot: Node3D = $Pivot

func _ready() -> void:
	# AnimationPlayer irgendwo unter Pivot finden (Male/Female egal)
	anim = $Pivot.find_child("AnimationPlayer", true, false)
	if anim:
		# passende Clips heuristisch wählen
		for name in anim.get_animation_list():
			var lname := name.to_lower()
			if RUN_ANIM == "" and ("run" in lname or "walk" in lname):
				RUN_ANIM = name
			if IDLE_ANIM == "" and "idle" in lname:
				IDLE_ANIM = name
		# Loopen erzwingen, wenn möglich
		if RUN_ANIM != "" and anim.has_animation(RUN_ANIM):
			var a := anim.get_animation(RUN_ANIM)
			if a: a.loop_mode = Animation.LOOP_LINEAR

func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_right"):  dir.x -= 1.0
	if Input.is_action_pressed("move_left"):   dir.x += 1.0
	if Input.is_action_pressed("move_back"):   dir.z -= 1.0
	if Input.is_action_pressed("move_forward"):dir.z += 1.0
	
	_camera_pivot.rotation.x+= _camera_input_direction.y * delta
	_camera_pivot.rotation.x= clamp(_camera_pivot.rotation.x,-PI / 6.0,PI/ 3.0)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_input_direction= Vector2.ZERO

	if dir != Vector3.ZERO:
		dir = dir.normalized()
		pivot.basis = Basis.looking_at(-dir, Vector3.UP)

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	else:
		velocity.y = min(velocity.y, 0.0)
	move_and_slide()

	# Animation
	if anim:
		if dir != Vector3.ZERO and RUN_ANIM != "" and anim.current_animation != RUN_ANIM:
			anim.play(RUN_ANIM)
		elif dir == Vector3.ZERO and IDLE_ANIM != "" and anim.current_animation != IDLE_ANIM:
			anim.play(IDLE_ANIM)
			
# 3rd PErson camera
@export_group("Camera")
@export_range(0.0,1.0) var mouse_sensitivity := 0.25
var _camera_input_direction:= Vector2.ZERO
@onready var _camera_pivot: Node3D = %CameraPivot

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lmb"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion:= (
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity
