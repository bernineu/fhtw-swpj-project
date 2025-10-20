extends CharacterBody3D

@export var speed: float = 10.0
@export var fall_acceleration: float = 75.0

const RUN_ANIM  := "HumanArmature|Man_Run"
const IDLE_ANIM := "HumanArmature|Man_Idle" # optional if you have it

@onready var anim: AnimationPlayer = $"Pivot/Male_Casual/AnimationPlayer"
@onready var pivot: Node3D = $Pivot

func _ready() -> void:
	# Ensure the run animation loops (do this once, not every frame)
	if anim.has_animation(RUN_ANIM):
		var a := anim.get_animation(RUN_ANIM)
		if a:
			a.loop_mode = Animation.LOOP_LINEAR

func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO

	if Input.is_action_pressed("move_right"):
		dir.x += 1.0
	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_back"):
		dir.z += 1.0
	if Input.is_action_pressed("move_forward"):
		dir.z -= 1.0

	if dir != Vector3.ZERO:
		dir = dir.normalized()
		
		pivot.basis = Basis.looking_at(-dir, Vector3.UP)

	# Horizontal velocity
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	# Gravity (vertical)
	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	else:
		# keep a tiny downward bias to stay grounded
		velocity.y = min(velocity.y, 0.0)

	# Move
	move_and_slide()

	# --- Animations ---
	if dir != Vector3.ZERO:
		if anim.has_animation(RUN_ANIM) and anim.current_animation != RUN_ANIM:
			anim.play(RUN_ANIM)
	else:
		# Optional idle fallback
		if anim.has_animation(IDLE_ANIM) and anim.current_animation != IDLE_ANIM:
			anim.play(IDLE_ANIM)
