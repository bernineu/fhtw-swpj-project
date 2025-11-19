extends Node3D
@onready var spawn_point: Node3D = $SpawnPoint

# declare two points for spawning
var point_1: Vector3
var point_2: Vector3

# find the object i'll spawn
@onready var object_resource: Resource = preload("res://scenes/objects/cheese.tscn")

@onready var object_resources = [
	preload("res://scenes/objects/cheese.tscn"),
	preload("res://scenes/objects/chocolate.tscn"),
	preload("res://scenes/objects/dogfood.tscn")
]

#@onready var spawn_timer: Timer = $SpawnTimer
var spawn_timer: Timer

func _ready():
	var scene: PackedScene = GameState.get_selected_player_scene()
	var player: Node3D = scene.instantiate()
	add_child(player)
	player.global_transform = spawn_point.global_transform
	
	# Setup timer for automatic spawning
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = 3.0  # 3 seconds
	spawn_timer.connect("timeout", spawn_object)
	spawn_timer.start()

	# for spawning:
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
	var object_instance: Node = get_random_object().instantiate()
	# place the object in the scene tree so we can see it
	add_child(object_instance)
	
	# generate a random spawn location
	var spawn_location: Vector3 = get_random_point_inside(point_1, point_2)
	# set the position to the random spawn location
	object_instance.position = spawn_location
	GameState.add_object()


func get_random_object() -> Resource:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var idx = rng.randi_range(0, object_resources.size() - 1)
	return object_resources[idx]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	GameState.update_time_score(_delta)
	if Input.is_action_just_pressed("lmb"):
		spawn_object()
