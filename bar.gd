extends Node2D

# Player scenes
var player_scene: PackedScene = preload("res://stickman.tscn")

# References to players for easy access
var player1: CharacterBody2D
var player2: CharacterBody2D

# UI elements
var player1_health_bar: ProgressBar
var player1_endurance_bar: ProgressBar
var player1_health_label: Label

var player2_health_bar: ProgressBar
var player2_endurance_bar: ProgressBar
var player2_health_label: Label

func _ready():
	# Setup input actions first
	_setup_input_actions()

	# Spawn player 1
	var player1_instance: Node = player_scene.instantiate()
	player1_instance.position = $PlayerPositions/Player1Position.position
	add_child(player1_instance)

	# Set up player 1 controller
	var script1 = load("res://stickman_character.gd")
	player1_instance.get_node("CharacterBody2D").set_script(script1)
	player1_instance.get_node("CharacterBody2D").control_set = "player1"
	player1_instance.get_node("CharacterBody2D").player_color = Color(0.2, 0.8, 0.2)  # Green
	player1 = player1_instance.get_node("CharacterBody2D")

	# Spawn player 2
	var player2_instance: Node = player_scene.instantiate()
	player2_instance.position = $PlayerPositions/Player2Position.position
	add_child(player2_instance)

	# Set up player 2 controller
	var script2 = load("res://stickman_character.gd")
	player2_instance.get_node("CharacterBody2D").set_script(script2)
	player2_instance.get_node("CharacterBody2D").control_set = "player2"
	player2_instance.get_node("CharacterBody2D").player_color = Color(0.2, 0.2, 0.8)  # Blue
	player2_instance.get_node("CharacterBody2D/Skeleton2D").scale.x = -1
	player2 = player2_instance.get_node("CharacterBody2D")

	var animation_player: Node = player2_instance.get_node("CharacterBody2D/AnimationPlayer")
	animation_player.play("idle")
	animation_player.seek(0.8)  # Fast-forward to 0.8 seconds into the animation

	# Create UI 
	setup_ui()

	print("Bar scene ready with players and UI")

func setup_ui():
	# Create a CanvasLayer for UI
	var canvas = CanvasLayer.new()
	add_child(canvas)

	# Main container
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(control)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	control.add_child(margin)

	var hbox = HBoxContainer.new()
	margin.add_child(hbox)

	# Player 1 UI
	var p1_container = VBoxContainer.new()
	p1_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(p1_container)

	var p1_header = Label.new()
	p1_header.text = "PLAYER 1"
	p1_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_container.add_child(p1_header)

	player1_health_label = Label.new()
	player1_health_label.text = "HEALTH: 100%"
	p1_container.add_child(player1_health_label)

	player1_health_bar = ProgressBar.new()
	player1_health_bar.custom_minimum_size = Vector2(0, 25)
	player1_health_bar.max_value = 100
	player1_health_bar.value = 100
	player1_health_bar.show_percentage = false
	player1_health_bar.modulate = Color(0.9, 0.2, 0.2)
	p1_container.add_child(player1_health_bar)

	var p1_endurance_label = Label.new()
	p1_endurance_label.text = "ENDURANCE"
	p1_container.add_child(p1_endurance_label)

	player1_endurance_bar = ProgressBar.new()
	player1_endurance_bar.custom_minimum_size = Vector2(0, 20)
	player1_endurance_bar.max_value = 100
	player1_endurance_bar.value = 100
	player1_endurance_bar.show_percentage = false
	player1_endurance_bar.modulate = Color(0.2, 0.7, 0.9)
	p1_container.add_child(player1_endurance_bar)

	# Note: Punch power label removed

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(spacer)

	# Player 2 UI
	var p2_container = VBoxContainer.new()
	p2_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(p2_container)

	var p2_header = Label.new()
	p2_header.text = "PLAYER 2"
	p2_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_container.add_child(p2_header)

	player2_health_label = Label.new()
	player2_health_label.text = "HEALTH: 100%"
	p2_container.add_child(player2_health_label)

	player2_health_bar = ProgressBar.new()
	player2_health_bar.custom_minimum_size = Vector2(0, 25)
	player2_health_bar.max_value = 100
	player2_health_bar.value = 100
	player2_health_bar.show_percentage = false
	player2_health_bar.modulate = Color(0.9, 0.2, 0.2)
	p2_container.add_child(player2_health_bar)

	var p2_endurance_label = Label.new()
	p2_endurance_label.text = "ENDURANCE"
	p2_container.add_child(p2_endurance_label)

	player2_endurance_bar = ProgressBar.new()
	player2_endurance_bar.custom_minimum_size = Vector2(0, 20)
	player2_endurance_bar.max_value = 100
	player2_endurance_bar.value = 100
	player2_endurance_bar.show_percentage = false
	player2_endurance_bar.modulate = Color(0.2, 0.7, 0.9)
	p2_container.add_child(player2_endurance_bar)

	# Note: Punch power label removed

	print("UI setup complete")

# Update UI every frame
func _process(_delta):
	# Update Player 1 UI
	if player1:
		player1_health_bar.value = player1.current_health
		player1_health_label.text = "HEALTH: " + str(int(player1.current_health)) + "%"

		player1_endurance_bar.value = player1.current_endurance

		# Visual effects for health
		if player1.current_health < 30:
			player1_health_bar.modulate = Color(1, 0, 0)  # Bright red for low health
		else:
			player1_health_bar.modulate = Color(0.9, 0.2, 0.2)  # Normal red

		# Visual effects for endurance
		if player1.current_endurance < player1.PUNCH_ENDURANCE_COST:
			player1_endurance_bar.modulate = Color(0.2, 0.7, 0.9, 0.5)  # Dim blue for low endurance
		else:
			player1_endurance_bar.modulate = Color(0.2, 0.7, 0.9)  # Normal blue

	# Update Player 2 UI
	if player2:
		player2_health_bar.value = player2.current_health
		player2_health_label.text = "HEALTH: " + str(int(player2.current_health)) + "%"

		player2_endurance_bar.value = player2.current_endurance

		# Visual effects for health
		if player2.current_health < 30:
			player2_health_bar.modulate = Color(1, 0, 0)  # Bright red for low health
		else:
			player2_health_bar.modulate = Color(0.9, 0.2, 0.2)  # Normal red

		# Visual effects for endurance
		if player2.current_endurance < player2.PUNCH_ENDURANCE_COST:
			player2_endurance_bar.modulate = Color(0.2, 0.7, 0.9, 0.5)  # Dim blue for low endurance
		else:
			player2_endurance_bar.modulate = Color(0.2, 0.7, 0.9)  # Normal blue

func calculate_damage(player):
	var min_damage = 1
	var max_damage = 10

	if player.current_endurance <= 0:
		return min_damage

	var damage_percent = float(player.current_endurance) / player.MAX_ENDURANCE
	return int(min_damage + damage_percent * (max_damage - min_damage))

func _setup_input_actions():
	# Player 1 movement (WASD)
	_add_key_action("p1_left", KEY_A)
	_add_key_action("p1_right", KEY_D)
	_add_key_action("p1_attack", KEY_W)
	_add_key_action("p1_block", KEY_S)  # Added block action for player 1

	# Player 2 movement (Arrow keys)
	_add_key_action("p2_left", KEY_LEFT)
	_add_key_action("p2_right", KEY_RIGHT)
	_add_key_action("p2_attack", KEY_UP)
	_add_key_action("p2_block", KEY_DOWN)  # Added block action for player 2

# Helper function to add key actions if they don't exist
func _add_key_action(action_name, key_scancode):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event = InputEventKey.new()
		event.keycode = key_scancode
		InputMap.action_add_event(action_name, event)
