extends Node3D
@onready var spawn_point: Node3D = $SpawnPoint
@onready var nav_region: NavigationRegion3D = $NavigationRegion3D

# Floor height - adjust this to match your floor level
@export var floor_height: float = 0.5

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

func get_random_navmesh_point() -> Vector3:
	var map_rid: RID = nav_region.get_navigation_map()
	# 1 = Navigation-Layer-Maske (anpassen, falls du andere Layer nutzt)
	var nav_point: Vector3 = NavigationServer3D.map_get_random_point(map_rid, 1, false)
	
	# Höhe anpassen, falls nötig
	nav_point.y = floor_height
	return nav_point

func _ready():
	# Adjust furniture height first
	adjust_furniture_height()

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


func adjust_furniture_height():
	"""Adjust all furniture to sit on the floor at the correct height"""
	var furniture_node = get_node_or_null("furniture")
	if furniture_node:
		# Move the entire furniture container to the floor height
		furniture_node.position.y = floor_height
		print("✅ Furniture adjusted to floor height: ", floor_height)


func get_random_floor_point(max_tries := 20) -> Vector3:
	var map_rid: RID = nav_region.get_navigation_map()
	if map_rid == RID():
		push_warning("❗ Navigation map RID ist leer.")
		return Vector3.ZERO

	var space_state := get_world_3d().direct_space_state

	for i in range(max_tries):
		var p := NavigationServer3D.map_get_random_point(
			map_rid,
			nav_region.navigation_layers,
			false
		)

		var from := p + Vector3.UP * 2.0
		var to   := p + Vector3.DOWN * 5.0

		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = false
		query.collide_with_bodies = true

		var result := space_state.intersect_ray(query)

		if result and result.collider.is_in_group("floor"):
			var hit_pos: Vector3 = result.position
			hit_pos.y += 0.1  # bisschen über Boden spawnen
			return hit_pos

	# Fallback, wenn alles schiefgeht
	push_warning("⚠️ Kein gültiger Boden-Hit gefunden, nutze Fallback.")
	return Vector3(0, floor_height + 0.1, 0)



func spawn_object() -> void:
	var scene: PackedScene = object_resources[randi() % object_resources.size()]
	var obj: Node3D = scene.instantiate()

	obj.global_position = get_random_floor_point()
	add_child(obj)
	GameState.add_object()
	
	var dog := get_tree().get_first_node_in_group("dog")
	if dog and is_instance_valid(dog) and ("snack_type" in obj) and dog.has_method("is_snack_blocked"):
		if dog.is_snack_blocked(obj.snack_type) and dog.has_method("make_treat_non_blocking"):
			dog.make_treat_non_blocking(obj)

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
