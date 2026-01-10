extends SceneTree

# Automated test runner script
# Run from command line: godot --headless -s tests/run_all_tests.gd

var results = {
	"total": 0,
	"passed": 0,
	"failed": 0,
	"skipped": 0,
	"duration_ms": 0
}

func _init():
	print("============================================================")
	print("         HUNGRY DOG - AUTOMATED TEST SUITE")
	print("============================================================")
	print("")
	
	var start_time = Time.get_ticks_msec()
	
	# Create a root node for GUT
	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)
	
	# IMPORTANT: Load GameState autoload manually
	var GameStateScript = load("res://autoload/GameState.gd")
	var game_state = GameStateScript.new()
	game_state.name = "GameState"
	root.add_child(game_state)
	
	# Make it available globally (like an autoload)
	Engine.register_singleton("GameState", game_state)
	
	# Initialize GUT
	var gut = load("res://addons/gut/gut.gd").new()
	root.add_child(gut)
	
	# Add test directories
	print("Loading test suites...")
	gut.add_directory("res://tests/unit")
	gut.add_directory("res://tests/integration")
	print("   - Unit tests loaded")
	print("   - Integration tests loaded")
	print("")
	
	# Run tests
	print("Running tests...")
	print("------------------------------------------------------------")
	gut.test_scripts()
	
	# Wait for completion
	await gut.tests_finished
	
	var end_time = Time.get_ticks_msec()
	results.duration_ms = end_time - start_time
	
	# Collect results
	results.total = gut.get_test_count()
	results.passed = gut.get_pass_count()
	results.failed = gut.get_fail_count()
	results.skipped = gut.get_pending_count()
	
	# Print summary
	print_results()
	
	# Generate reports
	generate_console_report()
	
	# Cleanup
	Engine.unregister_singleton("GameState")
	
	# Exit with appropriate code
	var exit_code = 0 if results.failed == 0 else 1
	quit(exit_code)

func print_results():
	print("------------------------------------------------------------")
	print("")
	print("============================================================")
	print("                    TEST RESULTS SUMMARY")
	print("============================================================")
	print("")
	
	print("  Total Tests:    %d" % results.total)
	print("  Passed:         %d" % results.passed)
	print("  Failed:         %d" % results.failed)
	print("  Skipped:        %d" % results.skipped)
	print("")
	print("  Duration:       %.2f seconds" % (results.duration_ms / 1000.0))
	print("")
	
	if results.failed == 0:
		print("  ALL TESTS PASSED!")
	else:
		print("  SOME TESTS FAILED - CHECK LOGS")
	
	print("")
	print("============================================================")

func generate_console_report():
	var report_path = "user://test_results.txt"
	var file = FileAccess.open(report_path, FileAccess.WRITE)
	
	if file:
		file.store_line("HUNGRY DOG - Test Results")
		file.store_line("============================================================")
		file.store_line("")
		file.store_line("Timestamp: %s" % Time.get_datetime_string_from_system())
		file.store_line("Total Tests: %d" % results.total)
		file.store_line("Passed: %d" % results.passed)
		file.store_line("Failed: %d" % results.failed)
		file.store_line("Skipped: %d" % results.skipped)
		file.store_line("Duration: %.2fs" % (results.duration_ms / 1000.0))
		file.store_line("")
		
		if results.failed == 0:
			file.store_line("Status: ALL TESTS PASSED")
		else:
			file.store_line("Status: SOME TESTS FAILED")
		
		file.close()
		print("Console report saved: %s" % report_path)
