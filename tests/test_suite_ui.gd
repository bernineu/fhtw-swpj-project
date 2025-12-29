extends Control

# Interactive test suite selector
# Add this script to a Control node in a test scene

@onready var test_list: ItemList = $VBoxContainer/TestList
@onready var run_button: Button = $VBoxContainer/RunButton
@onready var run_all_button: Button = $VBoxContainer/RunAllButton
@onready var results_label: Label = $VBoxContainer/ResultsLabel
@onready var output_text: TextEdit = $VBoxContainer/OutputText

var gut_instance: Node
var available_tests = []

func _ready():
	# Scan for test files
	scan_test_files()
	
	# Connect signals
	run_button.pressed.connect(_on_run_selected_pressed)
	run_all_button.pressed.connect(_on_run_all_pressed)
	test_list.item_selected.connect(_on_test_selected)
	
	# Initialize GUT
	gut_instance = load("res://addons/gut/gut.gd").new()
	add_child(gut_instance)
	gut_instance.tests_finished.connect(_on_tests_finished)

func scan_test_files():
	available_tests.clear()
	test_list.clear()
	
	# Scan unit tests
	var unit_tests = _scan_directory("res://tests/unit")
	for test in unit_tests:
		available_tests.append({"path": test, "type": "Unit"})
		test_list.add_item("[Unit] " + test.get_file().replace(".gd", ""))
	
	# Scan integration tests
	var integration_tests = _scan_directory("res://tests/integration")
	for test in integration_tests:
		available_tests.append({"path": test, "type": "Integration"})
		test_list.add_item("[Integration] " + test.get_file().replace(".gd", ""))

func _scan_directory(path: String) -> Array:
	var tests = []
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".gd") and file_name.begins_with("test_"):
				tests.append(path + "/" + file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return tests

func _on_test_selected(index: int):
	if index >= 0 and index < available_tests.size():
		var test = available_tests[index]
		results_label.text = "Selected: %s (%s)" % [test.path.get_file(), test.type]

func _on_run_selected_pressed():
	var selected = test_list.get_selected_items()
	if selected.size() == 0:
		results_label.text = "No test selected!"
		return
	
	var index = selected[0]
	var test = available_tests[index]
	
	output_text.text = "Running: %s\n" % test.path.get_file()
	results_label.text = "Running test..."
	
	# Clear previous tests
	gut_instance.clear_text()
	
	# Add and run test
	gut_instance.add_script(test.path)
	gut_instance.test_scripts()

func _on_run_all_pressed():
	output_text.text = "Running all tests...\n"
	results_label.text = "Running all tests..."
	
	gut_instance.clear_text()
	gut_instance.add_directory("res://tests/unit")
	gut_instance.add_directory("res://tests/integration")
	gut_instance.test_scripts()

func _on_tests_finished():
	var passed = gut_instance.get_pass_count()
	var failed = gut_instance.get_fail_count()
	var total = gut_instance.get_test_count()
	
	results_label.text = "Results: %d/%d passed (%d failed)" % [passed, total, failed]
	
	if failed == 0:
		results_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		results_label.add_theme_color_override("font_color", Color.RED)
	
	# Update output
	var separator = ""
	for i in range(50):
		separator += "="
	
	output_text.text += "\n" + separator + "\n"
	output_text.text += "SUMMARY\n"
	output_text.text += "Total: %d\n" % total
	output_text.text += "Passed: %d\n" % passed
	output_text.text += "Failed: %d\n" % failed
