extends Node
class_name TestHelpers

# ============================================================================
# SCENE CREATION HELPERS
# ============================================================================

# Helper function to create a test scene with essential nodes
static func create_test_scene() -> Node3D:
	var scene = Node3D.new()
	scene.name = "TestScene"
	return scene

# ============================================================================
# ENTITY CREATION HELPERS
# ============================================================================

# Helper to create a mock player
static func create_mock_player(scene: Node3D) -> CharacterBody3D:
	var player_scene = preload("res://scenes/player/player_male.tscn")
	var player = player_scene.instantiate()
	player.add_to_group("player")
	scene.add_child(player)
	return player

# Helper to create a mock dog - FIXED VERSION
static func create_mock_dog(scene: Node3D, position: Vector3 = Vector3.ZERO) -> CharacterBody3D:
	var dog_script = preload("res://scripts/dog.gd")
	var dog = CharacterBody3D.new()
	dog.set_script(dog_script)
	dog.name = "TestDog"
	dog.add_to_group("dog")
	
	# Add required child nodes BEFORE adding to scene
	var nav_agent = NavigationAgent3D.new()
	nav_agent.name = "NavigationAgent3D"
	dog.add_child(nav_agent)
	
	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.0
	collision.shape = shape
	dog.add_child(collision)
	
	# Add to scene FIRST, then set position
	scene.add_child(dog)
	dog.global_position = position
	
	return dog

# Helper to create a snack - FIXED VERSION
static func create_snack(scene: Node3D, snack_type: int, position: Vector3 = Vector3.ZERO) -> Node3D:
	var snack_scene: PackedScene
	match snack_type:
		0: snack_scene = preload("res://scenes/objects/dogfood.tscn")
		1: snack_scene = preload("res://scenes/objects/cheese.tscn")
		2: snack_scene = preload("res://scenes/objects/chocolate.tscn")
		_: snack_scene = preload("res://scenes/objects/cheese.tscn")
	
	var snack = snack_scene.instantiate()
	scene.add_child(snack)
	snack.global_position = position
	
	return snack

# Create multiple snacks in a pattern
static func create_snack_grid(scene: Node3D, count: int, spacing: float = 2.0) -> Array:
	var snacks = []
	var grid_size = ceil(sqrt(count))
	var snack_index = 0
	
	for x in range(grid_size):
		for z in range(grid_size):
			if snack_index >= count:
				break
			
			var pos = Vector3(x * spacing, 0.5, z * spacing)
			var snack_type = snack_index % 3  # Rotate through types
			var snack = create_snack(scene, snack_type, pos)
			snacks.append(snack)
			snack_index += 1
	
	return snacks

# ============================================================================
# TIMING HELPERS
# ============================================================================

# Wait for a specific amount of frames
static func wait_frames(test_instance, frames: int):
	for i in range(frames):
		await test_instance.get_tree().process_frame

# Wait for seconds in test
static func wait_seconds(test_instance, seconds: float):
	await test_instance.get_tree().create_timer(seconds).timeout

# Wait for a condition to become true (with timeout)
static func wait_for_condition(test_instance, callable: Callable, timeout_sec: float = 5.0) -> bool:
	var elapsed = 0.0
	var delta = 0.016  # Approximate frame time
	
	while elapsed < timeout_sec:
		if callable.call():
			return true
		await test_instance.get_tree().create_timer(delta).timeout
		elapsed += delta
	
	return false

# ============================================================================
# ASSERTION HELPERS
# ============================================================================

# Assert Vector3 approximately equal
static func assert_vector3_approx(test_instance, actual: Vector3, expected: Vector3, tolerance: float = 0.01, message: String = ""):
	var diff = actual - expected
	var distance = diff.length()
	test_instance.assert_true(distance <= tolerance, 
		"%s - Expected: %s, Got: %s, Distance: %.3f" % [message, expected, actual, distance])

# ============================================================================
# CLEANUP HELPERS
# ============================================================================

# Clean up all nodes in a group
static func cleanup_group(tree: SceneTree, group_name: String) -> void:
	var nodes = tree.get_nodes_in_group(group_name)
	for node in nodes:
		if is_instance_valid(node):
			node.queue_free()

# Force free all children of a node
static func cleanup_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

# ============================================================================
# DEBUG HELPERS
# ============================================================================

# Print detailed test state
static func print_test_state(label: String, data: Dictionary) -> void:
	print("")
	print("==================================================")
	print("TEST STATE: %s" % label)
	print("==================================================")
	for key in data.keys():
		print("  %s: %s" % [key, data[key]])
	print("==================================================")
	print("")

# ============================================================================
# SIGNAL HELPERS
# ============================================================================

# Wait for a signal to be emitted
static func wait_for_signal(test_instance, target: Object, signal_name: String, timeout_sec: float = 5.0) -> bool:
	var signal_received = false
	var timeout_reached = false
	
	# Connect to signal
	var callable = func(): signal_received = true
	target.connect(signal_name, callable)
	
	# Start timeout
	var timer = test_instance.get_tree().create_timer(timeout_sec)
	timer.timeout.connect(func(): timeout_reached = true)
	
	# Wait for either signal or timeout
	while not signal_received and not timeout_reached:
		await test_instance.get_tree().process_frame
	
	# Cleanup
	if target.is_connected(signal_name, callable):
		target.disconnect(signal_name, callable)
	
	return signal_received
