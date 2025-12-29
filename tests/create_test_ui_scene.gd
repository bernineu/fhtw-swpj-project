# Manual scene creation script (run once in editor)
# Save this as tests/create_test_ui_scene.gd and run it

@tool
extends EditorScript

func _run():
	var scene_root = Control.new()
	scene_root.name = "TestSuiteUI"
	scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	scene_root.add_child(vbox)
	vbox.owner = scene_root
	
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "Hungry Dog Test Suite"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	title.owner = scene_root
	
	var test_list = ItemList.new()
	test_list.name = "TestList"
	test_list.custom_minimum_size = Vector2(400, 200)
	vbox.add_child(test_list)
	test_list.owner = scene_root
	
	var button_hbox = HBoxContainer.new()
	button_hbox.name = "ButtonContainer"
	vbox.add_child(button_hbox)
	button_hbox.owner = scene_root
	
	var run_button = Button.new()
	run_button.name = "RunButton"
	run_button.text = "Run Selected"
	button_hbox.add_child(run_button)
	run_button.owner = scene_root
	
	var run_all_button = Button.new()
	run_all_button.name = "RunAllButton"
	run_all_button.text = "Run All Tests"
	button_hbox.add_child(run_all_button)
	run_all_button.owner = scene_root
	
	var results_label = Label.new()
	results_label.name = "ResultsLabel"
	results_label.text = "Select a test to run"
	results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(results_label)
	results_label.owner = scene_root
	
	var output_text = TextEdit.new()
	output_text.name = "OutputText"
	output_text.custom_minimum_size = Vector2(400, 300)
	output_text.editable = false
	vbox.add_child(output_text)
	output_text.owner = scene_root
	
	# Attach script
	var script = load("res://tests/test_suite_ui.gd")
	scene_root.set_script(script)
	
	# Save scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(scene_root)
	ResourceSaver.save(packed_scene, "res://tests/test_suite_ui.tscn")
	
	print("Test UI scene created at res://tests/test_suite_ui.tscn")
