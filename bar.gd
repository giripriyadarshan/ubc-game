extends Node2D

# Player scenes
var player_scene: PackedScene = preload("res://stickman.tscn")

func _ready():
	# Setup input actions first
	_setup_input_actions()

	# Spawn player 1
	var player1: Node = player_scene.instantiate()
	player1.position = $PlayerPositions/Player1Position.position
	add_child(player1)

	# Set up player 1 controller
	var script1 = load("res://stickman_character.gd")
	player1.get_node("CharacterBody2D").set_script(script1)
	player1.get_node("CharacterBody2D").control_set = "player1"
	player1.get_node("CharacterBody2D").player_color = Color(0.2, 0.8, 0.2)  # Green

	# Spawn player 2
	var player2: Node = player_scene.instantiate()
	player2.position = $PlayerPositions/Player2Position.position
	add_child(player2)

	# Set up player 2 controller
	var script2 = load("res://stickman_character.gd")
	player2.get_node("CharacterBody2D").set_script(script2)
	player2.get_node("CharacterBody2D").control_set = "player2"
	player2.get_node("CharacterBody2D").player_color = Color(0.2, 0.2, 0.8)  # Blue
	player2.get_node("CharacterBody2D/Skeleton2D").scale.x = -1
	
	var animation_player: Node = player2.get_node("CharacterBody2D/AnimationPlayer")
	animation_player.play("idle")
	animation_player.seek(0.8)  # Fast-forward to 0.2 seconds into the animation


func _setup_input_actions():
	# Player 1 movement (WASD)
	_add_key_action("p1_left", KEY_A)
	_add_key_action("p1_right", KEY_D)
	_add_key_action("p1_attack", KEY_W)

	# Player 2 movement (Arrow keys)
	_add_key_action("p2_left", KEY_LEFT)
	_add_key_action("p2_right", KEY_RIGHT)
	_add_key_action("p2_attack", KEY_UP)


# Helper function to add key actions if they don't exist
func _add_key_action(action_name, key_scancode):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event = InputEventKey.new()
		event.keycode = key_scancode
		InputMap.action_add_event(action_name, event)
