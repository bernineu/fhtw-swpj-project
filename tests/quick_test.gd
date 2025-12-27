extends SceneTree

# Quick test runner for development
# Run specific test file: godot -s tests/quick_test.gd --test-file=test_game_state

var test_file = ""

func _init():
	# Parse command line arguments
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--test-file="):
			test_file = arg.replace("--test-file=", "")
	
	if test_file == "":
		print("Usage: godot -s tests/quick_test.gd --test-file=<test_name>")
		print("Example: godot -s tests/quick_test.gd --test-file=test_game_state")
		quit(1)
		return
	
	print("Running quick test: %s" % test_file)
	
	# Create a root node for GUT
	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)
	
	var gut = load("res://addons/gut/gut.gd").new()
	root.add_child(gut)
	
	# Add specific test file
	var test_path = "res://tests/unit/%s.gd" % test_file
	if not FileAccess.file_exists(test_path):
		test_path = "res://tests/integration/%s.gd" % test_file
	
	if not FileAccess.file_exists(test_path):
		print("ERROR: Test file not found: %s" % test_path)
		quit(1)
		return
	
	gut.add_script(test_path)
	gut.test_scripts()
	
	await gut.tests_finished
	
	print("\nResults:")
	print("  Passed: %d" % gut.get_pass_count())
	print("  Failed: %d" % gut.get_fail_count())
	
	quit(0 if gut.get_fail_count() == 0 else 1)
