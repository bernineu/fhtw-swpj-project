extends Node
class_name TestHelpers

# Helper function to create a test scene with essential nodes
static func create_test_scene() -> Node3D:
	var scene = Node3D.new()
	scene.name = "TestScene"
	return scene

# Helper to create a mock player
static func create_mock_player(scene: Node3D) -> CharacterBody3D:
	var player_scene = preload("res://scenes/player/player_male.tscn")
	var player = player_scene.instantiate()
	player.add_to_group("player")
	scene.add_child(player)
	return player

# Helper to create a mock dog
static func create_mock_dog(scene: Node3D, position: Vector3 = Vector3.ZERO) -> CharacterBody3D:
	var dog_script = preload("res://scripts/dog.gd")
	var dog = CharacterBody3D.new()
	dog.set_script(dog_script)
	dog.name = "TestDog"
	dog.global_position = position
	dog.add_to_group("dog")
	
	# Add required child nodes
	var nav_agent = NavigationAgent3D.new()
	nav_agent.name = "NavigationAgent3D"
	dog.add_child(nav_agent)
	
	scene.add_child(dog)
	return dog

# Helper to create a snack
static func create_snack(scene: Node3D, snack_type: int, position: Vector3 = Vector3.ZERO) -> Node3D:
	var snack_scene: PackedScene
	match snack_type:
		0: snack_scene = preload("res://scenes/objects/dogfood.tscn")
		1: snack_scene = preload("res://scenes/objects/cheese.tscn")
		2: snack_scene = preload("res://scenes/objects/chocolate.tscn")
		_: snack_scene = preload("res://scenes/objects/cheese.tscn")
	
	var snack = snack_scene.instantiate()
	snack.global_position = position
	scene.add_child(snack)
	return snack

# Wait for a specific amount of frames
static func wait_frames(test_instance, frames: int):
	for i in range(frames):
		await test_instance.get_tree().process_frame

# Wait for seconds in test
static func wait_seconds(test_instance, seconds: float):
	await test_instance.get_tree().create_timer(seconds).timeout
