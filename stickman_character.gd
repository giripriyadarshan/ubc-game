extends CharacterBody2D

# Control configuration
var control_set: String = "player1" # Can be "player1" or "player2"

# Movement parameters
const SPEED: float = 300.0

# Player information
var player_color: Color = Color(1, 1, 1, 1)


func _ready():
	# Set the animation
	$AnimationPlayer.play("idle")

	# Apply color to all body parts
	apply_player_color(player_color)



func apply_player_color(color):
	# Apply color to torso and limbs
	$Skeleton2D/Hip/Torso/TorsoSprite.color = color
	$Skeleton2D/Hip/ThighL/ThighSpriteL.color = color
	$Skeleton2D/Hip/ThighR/ThighSpriteR.color = color
	$Skeleton2D/Hip/ThighL/LowerLegL/LowerLegSpriteL.color = color
	$Skeleton2D/Hip/ThighR/LowerLegR/LowerLegSpriteR.color = color
	$Skeleton2D/Hip/Torso/ShoulderL/UpperArmL/UpperArmSpriteL.color = color
	$Skeleton2D/Hip/Torso/ShoulderR/UpperArmR/UpperArmSpriteR.color = color

func _physics_process(delta):
	# Process inputs based on control set
	if control_set == "player1":
		process_player1_controls(delta)
	else:
		process_player2_controls(delta)

	move_and_slide()

func process_player1_controls(delta):
	# Handle left/right movement (A/D keys)
	var direction: float = Input.get_axis("p1_left", "p1_right")
	velocity.x = direction * SPEED

func process_player2_controls(delta):
	# Handle left/right movement (Left/Right arrows)
	var direction: float = Input.get_axis("p2_left", "p2_right")
	velocity.x = direction * SPEED
