extends Node3D

# Snack Type System
enum SnackType {
	DOG_FOOD,
	CHEESE,
	CHOCOLATE,
	POISON
}

@export var snack_type: SnackType = SnackType.DOG_FOOD

# Base utility values for each snack type (from Regelwerk)
const SNACK_UTILITY_VALUES = {
	SnackType.DOG_FOOD: 0.2,
	SnackType.CHEESE: 0.15,
	SnackType.CHOCOLATE: 0.1,
	SnackType.POISON: 0.05
}

var rotation_speed: float = 1.0    # radians per second

var player: Node3D = null
var dog: Node3D = null

@export var eating_distance: float = 3.0
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

	# 2) Check, ob er das Objekt essen darf
	if dog.has_method("can_eat_treat"):
		if not dog.can_eat_treat(self):
			return

	# Hund-Animation triggern und Snack-Typ mitteilen
	if dog.has_method("play_eat_animation"):
		dog.play_eat_animation()

	# Inform dog about what snack type was eaten
	if dog.has_method("on_snack_eaten"):
		dog.on_snack_eaten(snack_type)

	# Dieses Objekt verschwinden lassen
	GameState.remove_object()
	queue_free()


func get_snack_utility_value() -> float:
	"""Returns the base utility value for this snack type"""
	return SNACK_UTILITY_VALUES.get(snack_type, 0.0)


func get_snack_type_name() -> String:
	"""Returns the string name of the snack type"""
	match snack_type:
		SnackType.DOG_FOOD:
			return "DOG_FOOD"
		SnackType.CHEESE:
			return "CHEESE"
		SnackType.CHOCOLATE:
			return "CHOCOLATE"
		SnackType.POISON:
			return "POISON"
		_:
			return "UNKNOWN"


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
	visible = false
	set_process(false)
	# optional collision disable, falls vorhanden:
	# $CollisionShape3D.disabled = true
	await get_tree().create_timer(dog.eat_duration).timeout
	queue_free()
