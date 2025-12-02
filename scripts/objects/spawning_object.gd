extends Node3D

var rotation_speed: float = 1.0    # radians per second

var player: Node3D = null
var dog: Node3D = null

@export var eating_distance: float = 4.0    
@export var pickup_distance: float = 3.0       # wie nah der Player sein muss
@export_range(0.0, 1.0)
var pickup_forward_dot: float = 0.5            # wie sehr "vorne" der Player stehen soll (Winkel)

func _ready() -> void:
	add_to_group("treats")

	player = get_tree().get_first_node_in_group("player")
	dog = get_tree().get_first_node_in_group("dog")

func _process(delta: float) -> void:
	# weiter rotieren
	rotate_y(rotation_speed * delta)

	# Falls Player/Hund später gespawnt sind, nochmal suchen
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if dog == null:
		dog = get_tree().get_first_node_in_group("dog")

	# Player-Pickup per Taste
	if player and Input.is_action_just_pressed("pickup"):
		_try_pickup()

	# Hund frisst automatisch, wenn er nah genug ist
	if dog:
		_try_eating()


func _try_eating() -> void:
	if dog == null or !is_instance_valid(dog):
		
		return

	# Vektor vom Objekt zum Hund
	var to_dog: Vector3 = dog.global_transform.origin - global_transform.origin
	var distance := to_dog.length()

	# 1) Distanz-Check
	if distance > eating_distance:
		return

	# 2) Optional: Check, ob das Objekt grob vor dem Hund ist
	var dog_forward: Vector3 = -dog.global_transform.basis.z
	var to_object_from_dog: Vector3 = (global_transform.origin - dog.global_transform.origin).normalized()
	# var dot_val := dog_forward.dot(to_object_from_dog)
	# 0.3 ≈ ca. 70° vor dem Hund; 
	# if dot_val < 0.3:
		# return

	# Hund-Animation triggern
	if dog.has_method("play_eat_animation"):
		
		dog.play_eat_animation()

	# Dieses Objekt verschwinden lassen
	GameState.remove_object()
	# Falls du extra Hund-Score willst:
	# GameState.add_dog_score()
	queue_free()


func _try_pickup() -> void:
	var to_player: Vector3 = player.global_transform.origin - global_transform.origin
	var distance := to_player.length()

	if distance > pickup_distance:
		return

	var forward: Vector3 = -global_transform.basis.z
	to_player = to_player.normalized()

	var dot_val := forward.dot(to_player)
	if dot_val < pickup_forward_dot:
		return

	if player.has_method("play_pickup_animation"):
		player.play_pickup_animation()

	GameState.remove_object()
	GameState.add_pickup_score()
	queue_free()
