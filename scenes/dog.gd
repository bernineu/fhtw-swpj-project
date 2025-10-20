extends CharacterBody3D

@export var speed: float = 14.0
@export var turn_min_deg: float = 30.0
@export var turn_max_deg: float = 800.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var anim_player: AnimationPlayer

func _ready():
	anim_player = find_child("AnimationPlayer")
	if anim_player and anim_player.has_animation("Gallop"):
		var anim = anim_player.get_animation("Gallop")
		anim.loop_mode = Animation.LOOP_LINEAR  
		anim_player.play("Gallop")                


func _physics_process(delta):
	# keep the dog upright
	rotation.x = 0.0
	rotation.z = 0.0

	# forward is -Z in Godot
	var forward := global_transform.basis.z.normalized()

	# apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# walk forward
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed

	# move and slide
	move_and_slide()

	# if we bumped into a wall, turn
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		# ignore floor/ground: only react to mostly-horizontal normals
		if col.get_normal().y < 0.5:
			var turn_rad := deg_to_rad(randf_range(turn_min_deg, turn_max_deg))
			rotate_y(turn_rad)
			# tiny nudge away from the wall to avoid sticking
			global_translate(col.get_normal() * 0.05)
			break
