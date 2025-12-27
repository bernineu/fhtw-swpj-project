# Test Plan - Dog vs Owner Game
## Detailed Test Specifications & Implementation Guide

**Projekt:** Dog vs Owner Game (Godot 4.5)  
**Version:** 1.0  
**Datum:** 10. Dezember 2025  
**Status:** Ready for Review  

---

## 1. Unit Test Specifications

### 1.1 Utility Calculation Tests

#### Test Suite: `test_utility_calculations.gd`

```gdscript
# Test ID: UTC-001
# Title: EAT_SNACK Base Score Calculation
# Priority: P1 - CRITICAL

func test_eat_snack_base_score():
    """Verify base score (0.7) is applied correctly"""
    
    # Arrange
    var calculator = UtilityCalculator.new()
    var snack = create_test_snack()
    var dog_pos = Vector3(0, 0, 0)
    
    # Act
    var utility = calculator.calculate_eat_utility(
        snack,
        dog_pos,
        dog_pos + Vector3(1, 0, 0),  # owner position (1m away)
        0.0,  # hunger level
        3     # lives
    )
    
    # Assert
    assert_greater_than_or_equal(utility, 0.7)
    assert_less_than_or_equal(utility, 1.0)
    assert_true(is_equal_approx(utility, 0.7), "Base score should be ~0.7")


# Test ID: UTC-002
# Title: EAT_SNACK Hunger Factor
# Priority: P1 - CRITICAL

func test_eat_snack_hunger_factor():
    """Verify hunger factor (0.0-0.3) is applied correctly"""
    
    var calculator = UtilityCalculator.new()
    var snack = create_test_snack()
    var dog_pos = Vector3(0, 0, 0)
    var owner_pos = Vector3(10, 0, 0)  # far away
    
    # Test with different hunger levels
    var hunger_levels = [0.0, 0.5, 1.0]
    var utilities = []
    
    for hunger in hunger_levels:
        var utility = calculator.calculate_eat_utility(
            snack, dog_pos, owner_pos, hunger, 3
        )
        utilities.append(utility)
    
    # Assert: utilities should increase with hunger
    assert_greater_than(utilities[1], utilities[0], "Higher hunger = higher utility")
    assert_greater_than(utilities[2], utilities[1], "Hunger 1.0 should give highest utility")
    
    # Check magnitude: max difference should be ~0.3
    var max_difference = utilities[2] - utilities[0]
    assert_less_than_or_equal(max_difference, 0.3)


# Test ID: UTC-003
# Title: EAT_SNACK Distance Factor
# Priority: P1 - CRITICAL

func test_eat_snack_distance_factor():
    """Verify distance factor reduces utility correctly"""
    
    var calculator = UtilityCalculator.new()
    var snack = create_test_snack()
    var dog_pos = Vector3(0, 0, 0)
    var owner_pos = Vector3(20, 0, 0)
    
    var sight_range = 50.0
    
    # Test with different distances
    var test_cases = [
        {"distance": 5.0, "expected_reduction": 0.02},
        {"distance": 25.0, "expected_reduction": 0.1},
        {"distance": 50.0, "expected_reduction": 0.2}
    ]
    
    for case in test_cases:
        var snack_pos = dog_pos + Vector3(case["distance"], 0, 0)
        snack.global_position = snack_pos
        
        var utility = calculator.calculate_eat_utility(
            snack, dog_pos, owner_pos, 0.0, 3
        )
        
        # Expected: 0.7 - distance_factor
        var expected = 0.7 - case["expected_reduction"]
        assert_true(
            is_equal_approx(utility, expected, 0.02),
            "Distance %f should reduce by %f" % [case["distance"], case["expected_reduction"]]
        )


# Test ID: UTC-004
# Title: EAT_SNACK Owner Danger Factor
# Priority: P1 - CRITICAL

func test_eat_snack_owner_danger_factor():
    """Verify owner danger factor reduces utility based on proximity"""
    
    var calculator = UtilityCalculator.new()
    var snack = create_test_snack()
    var dog_pos = Vector3(0, 0, 0)
    snack.global_position = Vector3(5, 0, 0)
    
    # Test different owner distances
    var test_cases = [
        {"owner_dist": 10.0, "reduction": 0.0},  # > 5m: no reduction
        {"owner_dist": 4.0, "reduction": 0.0},   # 3-5m: no reduction
        {"owner_dist": 2.0, "reduction": 0.3},   # < 3m: 0.3 reduction
        {"owner_dist": 0.5, "reduction": 0.3}    # very close: 0.3 reduction
    ]
    
    for case in test_cases:
        var owner_pos = dog_pos + Vector3(case["owner_dist"], 0, 0)
        
        var utility = calculator.calculate_eat_utility(
            snack, dog_pos, owner_pos, 0.0, 3
        )
        
        var expected = 0.7 - case["reduction"]
        assert_true(
            is_equal_approx(utility, expected, 0.02),
            "Owner distance %f should reduce by %f" % [case["owner_dist"], case["reduction"]]
        )


# Test ID: UTC-005
# Title: FLEE_FROM_OWNER Threat Distance Factor
# Priority: P1 - CRITICAL

func test_flee_utility_threat_distance():
    """Verify threat distance factor in FLEE utility"""
    
    var calculator = UtilityCalculator.new()
    var dog_pos = Vector3(0, 0, 0)
    
    var test_cases = [
        {"owner_dist": 1.0, "base_utility": 0.8},   # < 2m: +0.5
        {"owner_dist": 3.0, "base_utility": 0.5},   # 2-4m: +0.2
        {"owner_dist": 10.0, "base_utility": 0.3}   # > 4m: no boost
    ]
    
    for case in test_cases:
        var owner_pos = dog_pos + Vector3(case["owner_dist"], 0, 0)
        
        var utility = calculator.calculate_flee_utility(
            dog_pos, owner_pos, false, nil
        )
        
        assert_greater_than_or_equal(
            utility, case["base_utility"],
            "Threat distance %f should give at least %f utility" % [case["owner_dist"], case["base_utility"]]
        )


# Test ID: UTC-006
# Title: POOP Cooldown Enforcement
# Priority: P1 - CRITICAL

func test_poop_utility_cooldown():
    """Verify POOP utility is 0.0 when cooldown is active"""
    
    var calculator = UtilityCalculator.new()
    var dog_pos = Vector3(0, 0, 0)
    var owner_pos = Vector3(2, 0, 0)
    
    # Simulate active cooldown
    var utility_with_cooldown = calculator.calculate_poop_utility(
        dog_pos, owner_pos, true  # cooldown_active = true
    )
    
    assert_equal(
        utility_with_cooldown, 0.0,
        "POOP utility must be 0.0 when cooldown is active"
    )


# Test ID: UTC-007
# Title: Utility Clamping to [0.0, 1.0]
# Priority: P1 - CRITICAL

func test_utility_clamping():
    """Verify all utility values are clamped to [0.0, 1.0]"""
    
    var calculator = UtilityCalculator.new()
    
    # Create extreme conditions
    var extreme_cases = [
        create_test_case_extreme_negative(),
        create_test_case_extreme_positive(),
        create_test_case_all_positive_factors(),
        create_test_case_all_negative_factors()
    ]
    
    for case in extreme_cases:
        var utility = calculator.calculate_eat_utility(
            case["snack"], case["dog_pos"], case["owner_pos"],
            case["hunger"], case["lives"]
        )
        
        assert_greater_than_or_equal(utility, 0.0)
        assert_less_than_or_equal(utility, 1.0)
```

---

### 1.2 Navigation Tests

#### Test Suite: `test_navigation_system.gd`

```gdscript
# Test ID: NAV-001
# Title: Target Reachability Detection
# Priority: P1 - CRITICAL

func test_target_reachability_valid_target():
    """Verify navigation agent correctly identifies reachable targets"""
    
    # Arrange
    var scene = load("res://test_scenes/navigation_test_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var nav_agent = dog.get_node("NavigationAgent3D")
    var reachable_target = scene.get_node("ReachableTarget")
    
    # Act
    nav_agent.set_target_position(reachable_target.global_position)
    await get_tree().process_frame  # Wait for pathfinding
    
    # Assert
    assert_true(
        nav_agent.is_target_reachable(),
        "Target should be reachable on same navmesh"
    )


# Test ID: NAV-002
# Title: Unreachable Target Detection
# Priority: P1 - CRITICAL

func test_target_reachability_invalid_target():
    """Verify navigation agent detects unreachable targets"""
    
    var scene = load("res://test_scenes/navigation_test_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var nav_agent = dog.get_node("NavigationAgent3D")
    var unreachable_target = scene.get_node("UnreachableTarget")
    
    nav_agent.set_target_position(unreachable_target.global_position)
    await get_tree().process_frame
    
    assert_false(
        nav_agent.is_target_reachable(),
        "Target should be unreachable (isolated island)"
    )


# Test ID: NAV-003
# Title: Path Calculation Validity
# Priority: P1 - CRITICAL

func test_path_calculation_validity():
    """Verify pathfinding produces valid paths"""
    
    var scene = load("res://test_scenes/navigation_test_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var nav_agent = dog.get_node("NavigationAgent3D")
    var target = scene.get_node("Target")
    
    nav_agent.set_target_position(target.global_position)
    await get_tree().process_frame
    
    var path = nav_agent.get_current_navigation_path()
    
    # Assert: path should not be empty for reachable target
    assert_greater_than(path.size(), 0, "Path should have waypoints")
    
    # Assert: no extreme jumps in path
    for i in range(path.size() - 1):
        var waypoint_distance = path[i].distance_to(path[i + 1])
        assert_less_than(waypoint_distance, 50.0, "Waypoint distance should be reasonable")


# Test ID: NAV-004
# Title: Next Position Updates Correctly
# Priority: P2 - HIGH

func test_next_position_update():
    """Verify next waypoint updates as agent progresses"""
    
    var scene = load("res://test_scenes/navigation_test_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var nav_agent = dog.get_node("NavigationAgent3D")
    var target = scene.get_node("DistantTarget")
    
    nav_agent.set_target_position(target.global_position)
    await get_tree().process_frame
    
    var first_next_pos = nav_agent.get_next_path_position()
    
    # Simulate movement
    dog.global_position += (first_next_pos - dog.global_position).normalized() * 5.0
    nav_agent.set_target_position(target.global_position)
    await get_tree().process_frame
    
    var second_next_pos = nav_agent.get_next_path_position()
    
    # Next position should change as we progress
    assert_not_equal(
        first_next_pos, second_next_pos,
        "Next position should update as dog progresses"
    )
```

---

### 1.3 Animation Tests

#### Test Suite: `test_animation_system.gd`

```gdscript
# Test ID: ANIM-001
# Title: Required Animations Exist
# Priority: P1 - CRITICAL

func test_animation_exists():
    """Verify all required animations are loaded"""
    
    var scene = load("res://scenes/dog/Dog.tscn").instantiate()
    add_child(scene)
    
    var anim_player = scene.find_child("AnimationPlayer")
    var required_anims = ["Gallop", "Eating"]
    
    for anim_name in required_anims:
        assert_true(
            anim_player.has_animation(anim_name),
            "Animation '%s' must be loaded" % anim_name
        )


# Test ID: ANIM-002
# Title: Animation Playback
# Priority: P1 - CRITICAL

func test_animation_playback():
    """Verify animation plays when called"""
    
    var scene = load("res://scenes/dog/Dog.tscn").instantiate()
    add_child(scene)
    
    var anim_player = scene.find_child("AnimationPlayer")
    anim_player.play("Gallop")
    
    await get_tree().process_frame
    
    assert_equal(
        anim_player.current_animation, "Gallop",
        "Currently playing animation should be 'Gallop'"
    )


# Test ID: ANIM-003
# Title: Animation Loop Mode
# Priority: P2 - HIGH

func test_animation_loop_mode():
    """Verify loop modes are set correctly"""
    
    var scene = load("res://scenes/dog/Dog.tscn").instantiate()
    add_child(scene)
    
    var anim_player = scene.find_child("AnimationPlayer")
    
    # Gallop should loop
    var gallop_anim = anim_player.get_animation("Gallop")
    assert_equal(
        gallop_anim.loop_mode, Animation.LOOP_LINEAR,
        "Gallop animation should loop"
    )
    
    # Eating should not loop
    var eating_anim = anim_player.get_animation("Eating")
    assert_equal(
        eating_anim.loop_mode, Animation.LOOP_NONE,
        "Eating animation should not loop"
    )
```

---

### 1.4 Physics Tests

#### Test Suite: `test_physics_system.gd`

```gdscript
# Test ID: PHYS-001
# Title: Gravity Application
# Priority: P1 - CRITICAL

func test_gravity_application():
    """Verify gravity is applied correctly"""
    
    var scene = load("res://test_scenes/physics_test_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var initial_y = dog.global_position.y
    
    # Dog should not be on floor initially
    assert_false(dog.is_on_floor(), "Dog should not be on floor")
    
    # Simulate physics for a few frames
    for i in range(10):
        dog._physics_process(0.016)  # ~60 FPS
    
    var final_y = dog.global_position.y
    assert_less_than(final_y, initial_y, "Dog should fall due to gravity")


# Test ID: PHYS-002
# Title: Floor Detection
# Priority: P1 - CRITICAL

func test_floor_detection():
    """Verify floor detection works"""
    
    var scene = load("res://test_scenes/physics_test_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("DogOnFloor")
    
    assert_true(
        dog.is_on_floor(),
        "Dog standing on floor should be detected"
    )


# Test ID: PHYS-003
# Title: Movement Application
# Priority: P1 - CRITICAL

func test_move_and_slide():
    """Verify move_and_slide applies velocity correctly"""
    
    var scene = load("res://test_scenes/physics_test_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var initial_pos = dog.global_position
    
    dog.velocity = Vector3(10, 0, 10)
    dog.move_and_slide()
    
    var final_pos = dog.global_position
    var displacement = final_pos - initial_pos
    
    assert_greater_than(displacement.length(), 0.0, "Dog should move")
```

---

## 2. Integration Test Specifications

### 2.1 Dog AI System Integration

#### Test Suite: `test_dog_ai_integration.gd`

```gdscript
# Test ID: INT-DOG-001
# Title: Find Nearest Treat
# Priority: P1 - CRITICAL

func test_find_nearest_treat():
    """Verify dog finds the nearest treat among multiple options"""
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    
    # Create test treats at known distances
    var treat_1 = create_test_treat(Vector3(5, 0, 0))   # 5 units away
    var treat_2 = create_test_treat(Vector3(10, 0, 0))  # 10 units away
    var treat_3 = create_test_treat(Vector3(2, 0, 0))   # 2 units away
    
    scene.add_child(treat_1)
    scene.add_child(treat_2)
    scene.add_child(treat_3)
    
    add_to_group("treats", treat_1)
    add_to_group("treats", treat_2)
    add_to_group("treats", treat_3)
    
    # Act
    dog.find_nearest_treat()
    
    # Assert
    assert_equal(
        dog.target_treat, treat_3,
        "Dog should target closest treat (2 units)"
    )


# Test ID: INT-DOG-002
# Title: Dog Navigation to Treat
# Priority: P1 - CRITICAL

func test_dog_navigation_to_treat():
    """Verify dog navigates toward treat and reduces distance"""
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var treat = create_test_treat(Vector3(15, 0, 0))
    
    scene.add_child(treat)
    add_to_group("treats", treat)
    
    # Set up navigation
    await get_tree().process_frame
    
    dog.find_nearest_treat()
    var initial_distance = dog.global_position.distance_to(treat.global_position)
    
    # Simulate movement for several frames
    for i in range(30):
        dog._physics_process(0.016)
    
    var final_distance = dog.global_position.distance_to(treat.global_position)
    
    assert_less_than(
        final_distance, initial_distance,
        "Dog should get closer to treat"
    )


# Test ID: INT-DOG-003
# Title: Target Update Interval
# Priority: P2 - HIGH

func test_target_update_interval():
    """Verify target is updated every 0.5 seconds"""
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    
    var treats = [
        create_test_treat(Vector3(5, 0, 0)),
        create_test_treat(Vector3(20, 0, 0))
    ]
    
    for treat in treats:
        scene.add_child(treat)
        add_to_group("treats", treat)
    
    await get_tree().process_frame
    dog.find_nearest_treat()
    var first_target = dog.target_treat
    
    # Simulate 0.5 seconds of gameplay
    var total_time = 0.0
    var update_count = 0
    
    while total_time < 0.5:
        dog._physics_process(0.016)
        total_time += 0.016
        
        if dog.target_treat != first_target:
            update_count += 1
            first_target = dog.target_treat
    
    # After 0.5 seconds, at least one update should have occurred
    assert_greater_than_or_equal(
        update_count, 1,
        "Target should update within 0.5 second interval"
    )


# Test ID: INT-DOG-004
# Title: Eating Mechanics Integration
# Priority: P1 - CRITICAL

func test_eating_mechanics():
    """Verify eating animation and timer work together"""
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    
    # Initial state
    assert_false(dog.is_eating, "Dog should not be eating initially")
    
    # Trigger eating
    dog.play_eat_animation()
    
    # Immediately after call
    assert_true(dog.is_eating, "Dog should be eating after play_eat_animation()")
    assert_true(
        is_equal_approx(dog.eat_timer, dog.eat_duration),
        "Eat timer should be set to eat_duration"
    )
    
    # Simulate eating for half the duration
    dog._physics_process(dog.eat_duration / 2.0)
    assert_true(dog.is_eating, "Dog should still be eating mid-duration")
    
    # Simulate rest of eating
    dog._physics_process(dog.eat_duration / 2.0 + 0.01)
    assert_false(dog.is_eating, "Dog should finish eating")


# Test ID: INT-DOG-005
# Title: No Movement During Eating
# Priority: P1 - CRITICAL

func test_dog_movement_during_eating():
    """Verify dog doesn't move horizontally while eating"""
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    dog.velocity = Vector3(10, 0, 10)  # Set initial velocity
    
    dog.play_eat_animation()
    dog._physics_process(0.016)
    
    # During eating, horizontal velocity should be zeroed
    assert_equal(dog.velocity.x, 0.0, "X velocity should be 0 while eating")
    assert_equal(dog.velocity.z, 0.0, "Z velocity should be 0 while eating")
```

---

### 2.2 Player-Dog Interaction Tests

#### Test Suite: `test_player_dog_interaction.gd`

```gdscript
# Test ID: INT-PLAYER-001
# Title: Player Catches Dog
# Priority: P2 - HIGH

func test_player_can_catch_dog():
    """Verify player can navigate to and reach dog"""
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var player = scene.get_node("Player")
    var dog = scene.get_node("Dog")
    
    # Move player toward dog
    player.global_position = dog.global_position + Vector3(10, 0, 0)
    
    # Simulate player movement toward dog for several frames
    for i in range(100):
        var direction = (dog.global_position - player.global_position).normalized()
        player.velocity.x = direction.x * player.speed
        player.velocity.z = direction.z * player.speed
        player._physics_process(0.016)
    
    var distance = player.global_position.distance_to(dog.global_position)
    assert_less_than(distance, 2.0, "Player should be able to reach dog")


# Test ID: INT-PLAYER-002
# Title: Dog Flees from Player
# Priority: P2 - HIGH

func test_dog_flees_from_player():
    """Verify dog uses fleeing behavior when player is close"""
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var player = scene.get_node("Player")
    var dog = scene.get_node("Dog")
    
    var treats = [create_test_treat(Vector3(30, 0, 0))]
    for treat in treats:
        scene.add_child(treat)
        add_to_group("treats", treat)
    
    # Position player close to dog
    player.global_position = dog.global_position + Vector3(2, 0, 0)
    
    await get_tree().process_frame
    var initial_distance = dog.global_position.distance_to(player.global_position)
    
    # Simulate for a few frames with dog trying to flee
    for i in range(20):
        dog._physics_process(0.016)
    
    var final_distance = dog.global_position.distance_to(player.global_position)
    
    # Dog should maintain or increase distance when fleeing
    assert_greater_than_or_equal(
        final_distance, initial_distance * 0.9,
        "Dog should flee from player"
    )


# Test ID: INT-PLAYER-003
# Title: Player Camera Follows Character
# Priority: P2 - HIGH

func test_player_camera_follows():
    """Verify camera is bound to player position"""
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var player = scene.get_node("Player")
    var camera_pivot = player.get_node("CameraPivot")
    
    var initial_player_pos = player.global_position
    var initial_camera_pos = camera_pivot.global_position
    
    # Move player
    player.global_position += Vector3(10, 0, 10)
    
    await get_tree().process_frame
    
    var final_player_pos = player.global_position
    var final_camera_pos = camera_pivot.global_position
    
    # Camera should follow player movement
    var player_movement = final_player_pos - initial_player_pos
    var camera_movement = final_camera_pos - initial_camera_pos
    
    assert_true(
        is_equal_approx(player_movement.length(), camera_movement.length(), 0.1),
        "Camera should follow player movement"
    )
```

---

### 2.3 Navigation System Integration

#### Test Suite: `test_navigation_integration.gd`

```gdscript
# Test ID: INT-NAV-001
# Title: Vertical Navigation
# Priority: P2 - HIGH

func test_vertical_navigation():
    """Verify dog can navigate between different height levels"""
    
    var scene = load("res://test_scenes/multilevel_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var treat_upper = create_test_treat(Vector3(0, 5, 0))
    
    scene.add_child(treat_upper)
    add_to_group("treats", treat_upper)
    
    await get_tree().process_frame
    
    dog.find_nearest_treat()
    var initial_y = dog.global_position.y
    
    # Simulate movement toward upper level
    for i in range(100):
        dog._physics_process(0.016)
    
    var final_y = dog.global_position.y
    
    # Dog should have moved upward
    assert_greater_than(
        final_y, initial_y + 1.0,
        "Dog should navigate to higher level"
    )


# Test ID: INT-NAV-002
# Title: Path Following
# Priority: P2 - HIGH

func test_path_following():
    """Verify dog follows calculated path correctly"""
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var nav_agent = dog.get_node("NavigationAgent3D")
    
    var distant_target = Vector3(30, 0, 30)
    nav_agent.set_target_position(distant_target)
    
    await get_tree().process_frame
    
    var initial_distance = dog.global_position.distance_to(distant_target)
    
    # Follow path for multiple frames
    for i in range(200):
        dog.move_along_navigation_path(0.016)
        dog.move_and_slide()
    
    var final_distance = dog.global_position.distance_to(distant_target)
    
    assert_less_than(
        final_distance, initial_distance,
        "Dog should progress along path toward target"
    )


# Test ID: INT-NAV-003
# Title: Smooth Rotation
# Priority: P2 - HIGH

func test_smooth_rotation():
    """Verify dog rotates smoothly toward target"""
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    
    dog.global_position = Vector3(0, 0, 0)
    var target_direction = Vector3(1, 0, 0)
    
    var rotation_changes = []
    
    # Simulate rotation over multiple frames
    for i in range(20):
        var initial_rot_y = dog.rotation.y
        dog._physics_process(0.016)
        var final_rot_y = dog.rotation.y
        
        var rotation_change = final_rot_y - initial_rot_y
        rotation_changes.append(rotation_change)
    
    # Rotation should change smoothly (not all at once)
    var max_change = rotation_changes.max()
    assert_less_than(
        max_change, 0.2,
        "Rotation should change smoothly (< 0.2 rad per frame)"
    )
```

---

## 3. Gameplay Test Specifications

### 3.1 Game Flow Tests

```gdscript
# Test ID: GP-FLOW-001
# Title: Snack Catching Scenario
# Priority: P2 - HIGH

func test_snack_catching_scenario():
    """
    Scenario: Dog should find and eat multiple snacks
    Expected: At least 3 snacks eaten in 2 minutes
    """
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var snacks_eaten = 0
    
    # Spawn multiple treats
    for i in range(10):
        var treat = create_test_treat(Vector3(rand_range(-20, 20), 0, rand_range(-20, 20)))
        scene.add_child(treat)
        add_to_group("treats", treat)
    
    # Hook into eat signal
    dog.snack_eaten.connect(func(): snacks_eaten += 1)
    
    # Simulate 2 minutes of gameplay
    for frame in range(7200):  # 120 seconds * 60 FPS
        dog._physics_process(0.016)
    
    # Validate: dog should eat multiple snacks
    assert_greater_than_or_equal(
        snacks_eaten, 3,
        "Dog should eat at least 3 snacks in 2 minutes"
    )
    
    # Validate: animations should play
    assert_true(dog.anim_player.is_playing(), "Animation should be playing")


# Test ID: GP-FLOW-002
# Title: Player Chase Scenario
# Priority: P2 - HIGH

func test_player_chase_scenario():
    """
    Scenario: Player chases dog, dog should flee intelligently
    Expected: Dog maintains distance, follows logical paths
    """
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var player = scene.get_node("Player")
    var dog = scene.get_node("Dog")
    
    # Position player to chase dog
    player.global_position = dog.global_position + Vector3(8, 0, 0)
    
    var distances = []
    
    # Simulate chase for 30 seconds
    for frame in range(1800):  # 30 seconds * 60 FPS
        # Player chases dog
        var direction = (dog.global_position - player.global_position).normalized()
        player.velocity.x = direction.x * player.speed
        player.velocity.z = direction.z * player.speed
        player._physics_process(0.016)
        
        # Dog reacts
        dog._physics_process(0.016)
        
        # Log distance
        if frame % 30 == 0:  # Every half second
            distances.append(player.global_position.distance_to(dog.global_position))
    
    # Validate: dog should not always be caught
    var average_distance = distances.reduce(func(a, b): return a + b) / distances.size()
    assert_greater_than(
        average_distance, 3.0,
        "Dog should maintain reasonable distance during chase"
    )
    
    # Validate: distance should be variable (dog is intelligent)
    var distance_variance = calculate_variance(distances)
    assert_greater_than(
        distance_variance, 1.0,
        "Dog should show varied fleeing behavior"
    )


# Test ID: GP-FLOW-003
# Title: Strategic Hindrance Scenario
# Priority: P3 - MEDIUM

func test_strategic_hindrance_scenario():
    """
    Scenario: Dog places poop strategically to hinder player
    Expected: Poop appears at strategic locations
    """
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var player = scene.get_node("Player")
    
    var poop_count = 0
    
    # Monitor poop spawning
    # (Assuming signal-based poop spawning)
    if dog.has_signal("poop_created"):
        dog.poop_created.connect(func(): poop_count += 1)
    
    # Chase scenario to trigger poop
    for frame in range(1800):  # 30 seconds
        var direction = (dog.global_position - player.global_position).normalized()
        player.velocity.x = direction.x * player.speed
        player.velocity.z = direction.z * player.speed
        player._physics_process(0.016)
        
        dog._physics_process(0.016)
    
    # Validate: at least some poop should be placed
    assert_greater_than(
        poop_count, 0,
        "Dog should place poop during chase"
    )


# Test ID: GP-FLOW-004
# Title: Resource Management Scenario
# Priority: P2 - HIGH

func test_resource_management_scenario():
    """
    Scenario: Game state manages lives and poison tracking
    Expected: Game ends at proper condition
    """
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var game_state = GameState.instance()
    var dog = scene.get_node("Dog")
    
    # Test poison tracking
    var poison_count = 0
    game_state.poison_eaten.connect(func(): poison_count += 1)
    
    # Feed dog poison
    for i in range(3):
        dog.eat_poison()
    
    assert_equal(poison_count, 3, "Poison counter should track correctly")
    assert_equal(game_state.lives, 0, "Lives should be depleted after 3 poisons")
    
    # Validate: game should be over
    assert_true(game_state.is_game_over, "Game should be over")
```

---

### 3.2 AI Behavior Quality Tests

```gdscript
# Test ID: GP-AI-001
# Title: Contextual Decision Making
# Priority: P2 - HIGH

func test_contextual_decision_making():
    """
    Verify dog makes context-aware decisions
    """
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    var player = scene.get_node("Player")
    
    # Test Case 1: Safe snack far from player
    var safe_snack = create_test_snack("cheese", Vector3(20, 0, 0))
    scene.add_child(safe_snack)
    add_to_group("treats", safe_snack)
    
    player.global_position = Vector3(-20, 0, 0)  # Far away
    dog.find_nearest_treat()
    
    assert_equal(
        dog.target_treat, safe_snack,
        "Dog should prioritize safe snack when player is far"
    )
    
    # Test Case 2: Dangerous snack close to player
    var dangerous_snack = create_test_snack("chocolate", Vector3(2, 0, 0))
    scene.add_child(dangerous_snack)
    add_to_group("treats", dangerous_snack)
    
    player.global_position = Vector3(3, 0, 0)  # Very close
    dog.find_nearest_treat()
    
    # Dog should prefer safe snack or flee instead
    var flee_utility = dog.calculate_utility_flee()
    var eat_dangerous_utility = dog.calculate_utility_eat(dangerous_snack)
    
    assert_greater_than(
        flee_utility, eat_dangerous_utility * 0.8,
        "Dog should prefer fleeing over dangerous snack"
    )


# Test ID: GP-AI-002
# Title: Behavior Variety
# Priority: P2 - HIGH

func test_behavior_variety():
    """
    Verify dog shows diverse behaviors over time
    """
    
    var scene = load("res://test_scenes/gameplay_scene.tscn").instantiate()
    add_child(scene)
    
    var dog = scene.get_node("Dog")
    
    var behaviors = []
    var last_action = ""
    
    # Simulate 10 minutes of gameplay
    for frame in range(36000):  # 600 seconds * 60 FPS
        var current_action = dog.get_current_action()
        
        if current_action != last_action:
            behaviors.append(current_action)
            last_action = current_action
    
    # Validate: should see multiple different behaviors
    var unique_behaviors = []
    for behavior in behaviors:
        if not unique_behaviors.has(behavior):
            unique_behaviors.append(behavior)
    
    assert_greater_than(
        unique_behaviors.size(), 2,
        "Dog should show at least 3 different behavior types"
    )
    
    # Validate: no single behavior should dominate entirely
    var eating_count = behaviors.count("EAT_SNACK")
    var eating_percentage = (eating_count / float(behaviors.size())) * 100.0
    
    assert_less_than(eating_percentage, 95.0, "Dog should not always eat")
    assert_greater_than(eating_percentage, 20.0, "Dog should eat reasonably often")
```

---

## 4. Test Data & Test Fixtures

### 4.1 Test Helper Functions

```gdscript
# File: test_helpers.gd

extends Node

class_name TestHelpers

# Create a test snack at specific position
static func create_test_snack(snack_type: String = "cheese", position: Vector3 = Vector3.ZERO) -> Node3D:
    var snack = Node3D.new()
    snack.name = "TestSnack_%s" % snack_type
    snack.global_position = position
    snack.add_to_group("treats")
    return snack


# Create a test treat
static func create_test_treat(position: Vector3 = Vector3.ZERO) -> Node3D:
    return create_test_snack("generic", position)


# Calculate variance of values
static func calculate_variance(values: Array) -> float:
    if values.is_empty():
        return 0.0
    
    var mean = values.reduce(func(a, b): return a + b) / float(values.size())
    var variance = 0.0
    
    for value in values:
        variance += pow(value - mean, 2)
    
    return variance / float(values.size())


# Create extreme test cases
static func create_test_case_extreme_negative() -> Dictionary:
    return {
        "snack": create_test_snack("poison", Vector3(50, 0, 0)),
        "dog_pos": Vector3(0, 0, 0),
        "owner_pos": Vector3(1, 0, 0),
        "hunger": 0.0,
        "lives": 1
    }


static func create_test_case_extreme_positive() -> Dictionary:
    return {
        "snack": create_test_snack("dog_food", Vector3(1, 0, 0)),
        "dog_pos": Vector3(0, 0, 0),
        "owner_pos": Vector3(50, 0, 0),
        "hunger": 1.0,
        "lives": 3
    }
```

---

**Dokument Ende**

*Alle Test-Spezifikationen sind implementierbar mit GUT (Godot Unit Testing Framework).*
