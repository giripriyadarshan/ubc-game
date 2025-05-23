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

# Fist bump detection variables
var can_check_simultaneous: bool = true
var simultaneous_cooldown: float = 0.5
var simultaneous_timer: float = 0.0

# Game over variables
var game_over: bool = false
var game_over_panel: Panel
var winner_label: Label
var restart_button: Button

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
	
	# Set opponent references for each player
	player1.opponent = player2
	player2.opponent = player1
	
	# Make sure both hit_areas can detect each other
	player1.get_node("hit_area").set_collision_layer_value(2, true)
	player1.get_node("hit_area").set_collision_mask_value(2, true)
	player2.get_node("hit_area").set_collision_layer_value(2, true)
	player2.get_node("hit_area").set_collision_mask_value(2, true)

	var animation_player: Node = player2_instance.get_node("CharacterBody2D/AnimationPlayer")
	animation_player.play("idle")
	animation_player.seek(0.8)  # Fast-forward to 0.8 seconds into the animation

	# Create UI 
	setup_ui()

	# Setup game over UI (but don't show it yet)
	setup_game_over_ui()

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
	player1_health_label.text = "HEALTH"  # Removed percentage display
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
	player2_health_label.text = "HEALTH"  # Removed percentage display
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


func setup_game_over_ui():
	# Create a CanvasLayer for game over UI (higher layer to appear on top)
	var canvas = CanvasLayer.new()
	canvas.layer = 10  # Higher layer
	add_child(canvas)
	
	# Game over panel
	game_over_panel = Panel.new()
	game_over_panel.set_anchors_preset(Control.PRESET_CENTER)
	game_over_panel.custom_minimum_size = Vector2(400, 250)
	game_over_panel.visible = false  # Hidden by default
	canvas.add_child(game_over_panel)
	
	# Center the panel
	game_over_panel.position = Vector2(
		(get_viewport_rect().size.x - game_over_panel.custom_minimum_size.x) / 2,
		(get_viewport_rect().size.y - game_over_panel.custom_minimum_size.y) / 2
	)
	
	# Container for content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	game_over_panel.add_child(vbox)
	
	# Add some margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(inner_vbox)
	
	# Game over label
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_size_override("font_size", 32)
	inner_vbox.add_child(game_over_label)
	
	# Winner label
	winner_label = Label.new()
	winner_label.text = "PLAYER X WINS!"
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_label.add_theme_font_size_override("font_size", 24)
	inner_vbox.add_child(winner_label)
	
	# Restart button
	restart_button = Button.new()
	restart_button.text = "RESTART MATCH"
	restart_button.custom_minimum_size = Vector2(200, 50)
	restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner_vbox.add_child(restart_button)
	
	# Connect button signals
	restart_button.pressed.connect(_on_restart_button_pressed)
	

# Update UI every frame
func _process(delta) -> void:
	# If game is already over, don't process anything else
	if game_over:
		return
		
	# Check for game over condition
	check_game_over()
	
	# Check for simultaneous punch opportunity
	check_simultaneous_punch(delta)
	
	# Update Player 1 UI
	if player1:
		player1_health_bar.value = player1.current_health
		# Removed numerical health display

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
		# Removed numerical health display

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

func check_game_over():
	# Check if either player's health has reached 0
	if player1 and player1.current_health <= 0:
		show_game_over("PLAYER 2")
	elif player2 and player2.current_health <= 0:
		show_game_over("PLAYER 1")

func show_game_over(winner_name):
	# Set game over state
	game_over = true
	
	# Update winner text
	winner_label.text = winner_name + " WINS!"
	
	# Apply color to winner text based on player
	if winner_name == "PLAYER 1":
		winner_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))  # Green
	else:
		winner_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.8))  # Blue
	
	# Show the game over panel
	game_over_panel.visible = true
	
	# Apply dramatic camera effect
	var camera: Node = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.set_zoom_str(1.2)  # Dramatic zoom
		camera.set_shake_str(Vector2(10, 10))  # Strong shake
	
	
	# Disable player controls
	player1.set_process_input(false)
	player2.set_process_input(false)

func _on_restart_button_pressed():
	# Reload the current scene to restart the game
	get_tree().reload_current_scene()

func check_simultaneous_punch(delta) -> void:
	# If we're in cooldown, decrement the timer
	if !can_check_simultaneous:
		simultaneous_timer -= delta
		if simultaneous_timer <= 0:
			can_check_simultaneous = true
			return
			
	# Only check if both players can still take action (not already in a special move)
	if can_check_simultaneous and player1 and player2:
		if !player1.is_in_simultaneous_punch and !player2.is_in_simultaneous_punch:
			# Check if both players want to punch at the same time and are close enough to each other
			if player1.wants_to_punch and player2.wants_to_punch:
				# Calculate distance between players
				var distance = abs(player1.global_position.x - player2.global_position.x)
				
				# If they're within punching range (adjust distance as needed)
				if distance < 100:
					
					# Check if both have enough endurance
					if player1.current_endurance >= player1.SIMULTANEOUS_PUNCH_COST or player2.current_endurance >= player2.SIMULTANEOUS_PUNCH_COST or player1.current_endurance < player1.SIMULTANEOUS_PUNCH_COST or player2.current_endurance < player2.SIMULTANEOUS_PUNCH_COST:
						
						# Trigger special animation on both
						var success1 = player1.start_simultaneous_punch()
						var success2 = player2.start_simultaneous_punch()
						
						if success1 and success2:
							# Special camera effect
							var camera: Node = get_tree().get_first_node_in_group("camera")
							if camera:
								camera.set_zoom_str(1.1)  # Dramatic zoom for special move
								camera.set_shake_str(Vector2(8, 8))  # Strong shake
							
							# Set cooldown to prevent immediate re-triggering
							can_check_simultaneous = false
							simultaneous_timer = simultaneous_cooldown

func calculate_damage(player) -> int:
	var min_damage: int = 1
	var max_damage: int = 10

	if player.current_endurance <= 0:
		return min_damage

	var damage_percent = float(player.current_endurance) / player.MAX_ENDURANCE
	return int(min_damage + damage_percent * (max_damage - min_damage))

func _setup_input_actions():
	# Player 1 movement (WASD)
	_add_key_action("p1_left", KEY_A)
	_add_key_action("p1_right", KEY_D)
	_add_key_action("p1_attack", KEY_W)
	_add_key_action("p1_block", KEY_S)  # 's' for player 1 block

	# Player 2 movement (Arrow keys)
	_add_key_action("p2_left", KEY_LEFT)
	_add_key_action("p2_right", KEY_RIGHT)
	_add_key_action("p2_attack", KEY_UP)
	_add_key_action("p2_block", KEY_DOWN)  # down arrow for player 2 block

# Helper function to add key actions if they don't exist
func _add_key_action(action_name, key_scancode):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event = InputEventKey.new()
		event.keycode = key_scancode
		InputMap.action_add_event(action_name, event)
