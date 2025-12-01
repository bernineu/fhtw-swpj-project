extends Node3D

var rotation_speed: float = 1.0    # radians per second

var player: Node3D = null

@export var pickup_distance: float = 3.0          # wie nah der Player sein muss
@export_range(0.0, 1.0)
var pickup_forward_dot: float = 0.5               # wie sehr "vorne" der Player stehen soll (Winkel)

func _ready() -> void:
	# Add this treat to the "treats" group so the dog can find it
	add_to_group("treats")

	# Player aus Gruppe "player" suchen (siehe player.gd → add_to_group("player"))
	player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	# weiter rotieren
	rotate_y(rotation_speed * delta)

	if player == null:
		return

	# Wenn Leertaste (Action "pickup") gedrückt wurde
	if Input.is_action_just_pressed("pickup"):
		_try_pickup()


func _try_pickup() -> void:
	# Vektor vom Objekt zum Player
	var to_player: Vector3 = player.global_transform.origin - global_transform.origin
	var distance := to_player.length()

	# 1) Distanz-Check
	if distance > pickup_distance:
		return

	# 2) Check ob der Player ungefähr vor dem Objekt steht
	var forward: Vector3 = -global_transform.basis.z          # lokale Vorwärtsrichtung des Objekts
	to_player = to_player.normalized()

	# Dot-Produkt: 1 = genau vorne, 0 = 90°, -1 = hinten
	var dot_val := forward.dot(to_player)
	if dot_val < pickup_forward_dot:
		return

	# Wenn wir hier sind: Player steht nah und vorne -> aufheben
	if player.has_method("play_pickup_animation"):
		player.play_pickup_animation()

	# Dieses Objekt verschwinden lassen
	GameState.remove_object()
	GameState.add_pickup_score()
	queue_free()
	
