extends Node


# spawning random objects - plan
	# choose one of the options: cheese, chocolate, dog food, poison
		# for the first test, only spawn cheese
	# find a random position
	# make sure that position is "free", and the new object wouldn't collide with any other, or any of the furniture
	# next-level solution: make sure the object doesn't spawn too close to the dog or the player
	# create the object

# declare two points
var point_1: Vector3
var point_2: Vector3
#@onready var spawn_point: Node3D = $SpawnPoint

# find the object i'll use
@onready var object_resource: Resource = preload("res://scenes/objects/cheese.tscn")

func _ready() -> void:
	randomize()		# this makes sure every playthrough is different
	# define two points
	point_1 = $Point1.position
	point_2 = $Point2.position

func get_random_point_inside(p1: Vector3, p2: Vector3) -> Vector3:
	var x_value: float = randf_range(p1.x, p2.x)
	var z_value: float = randf_range(p1.z, p2.z)
	
	var random_point_inside: Vector3 = Vector3(x_value, 0, z_value)
	
	return(random_point_inside)

func spawn_object():
	# build the object behind the scenes
	var object_instance: Node = object_resource.instantiate()
	# place the object in the scene tree so we can see it
	add_child(object_instance)

	# generate a random spawn location
	var spawn_location: Vector3 = get_random_point_inside(point_1, point_2)
	# set the position to the random spawn location
	object_instance.position = spawn_location

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("lmb"):
		spawn_object()
