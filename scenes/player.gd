extends CharacterBody3D

@export var speed: float = 10.0
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
	if Input.is_action_pressed("move_right"):  dir.x += 1.0
	if Input.is_action_pressed("move_left"):   dir.x -= 1.0
	if Input.is_action_pressed("move_back"):   dir.z += 1.0
	if Input.is_action_pressed("move_forward"):dir.z -= 1.0

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
