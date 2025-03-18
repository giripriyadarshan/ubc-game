extends CharacterBody2D

# Control configuration
var control_set: String = "player1" # Can be "player1" or "player2"

# Health and Endurance
var current_health: int = 100
var current_endurance: int = 100
const MAX_HEALTH: int = 100
const MAX_ENDURANCE: int = 100
const MAX_ENDURANCE_SPENT: int = 50 # 25 for a regular punch, 50 for fist bump (simultaneaus punch)
const MAX_DAMAGE_DEALT: int = 10
const ENDURANCE_HEALING_RATE: int = 2 # per second


# Movement parameters
const WALK_DISTANCE: float = 50.0
const SPEED: float         = 200.0

# Player information
var player_color: Color = Color(1, 1, 1, 1)

# animation and movement state
var current_animation: String = "idle"
var walk_in_progress: bool    = false
var walk_direction: int           = 0
var walk_start_position: Vector2  = Vector2.ZERO
var walk_target_position: Vector2 = Vector2.ZERO
var walk_progress: float          = 0.0
var desired_direction: int        = 0
@onready var animation_player = $AnimationPlayer
@onready var hit_box = $hit_area
@onready var camera = get_tree().get_first_node_in_group("camera")

# set camera zoom and shake when punching using:
# camera.set_zoom_str(1.01)
# camera.set_shake_str(Vector2(4,4))

func _ready():
	# Set the animation
	animation_player.play("idle")
	animation_player.animation_finished.connect(_on_animation_finished)

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
		desired_direction = Input.get_axis("p1_left", "p1_right")
	else:
		desired_direction = Input.get_axis("p2_left", "p2_right")
	
	if control_set != "player1":
		hit_box.position.x = -132

	if walk_in_progress:
		# Currently in a walk cycle
		process_walk_cycle(delta)
	else:
		# Not in a walk cycle - check if we should start one
		if desired_direction != 0:
			start_walk_cycle(desired_direction)
		else:
			# Idle state - no horizontal velocity
			velocity.x = 0
			if current_animation != "idle":
				play_animation("idle")

	# Apply movement
	move_and_slide()



func play_animation(anim_name):
	animation_player.play(anim_name)
	current_animation = anim_name


func start_walk_cycle(direction):
	# Set walk parameters
	walk_in_progress = true
	walk_direction = direction
	walk_start_position = global_position
	walk_target_position = walk_start_position + Vector2(direction * WALK_DISTANCE, 0)
	walk_progress = 0.0

	if (walk_direction > 0 and control_set == "player1") or (walk_direction<0 and control_set != "player1"):
		play_animation("walk")
	elif (walk_direction < 0 and control_set == "player1") or (walk_direction>0 and control_set != "player1"):
		play_animation("walk_backwards")


func process_walk_cycle(delta):
	# Get animation length to calculate progress speed
	var anim_length = animation_player.current_animation_length

	# Calculate how much to advance this frame
	var progress_increment = delta / anim_length
	walk_progress += progress_increment

	# Cap progress at 1.0 (should be handled by animation_finished but this is a safeguard)
	walk_progress = min(walk_progress, 1.0)

	# Update position based on linear interpolation
	global_position = walk_start_position.lerp(walk_target_position, walk_progress)

	# Set velocity to match the visual movement (for physics interactions)
	velocity.x = walk_direction * WALK_DISTANCE / anim_length

func _on_animation_finished(anim_name):
	if (anim_name == "walk" or anim_name == "walk_backwards") and walk_in_progress:
		walk_in_progress = false

		# If player is still holding direction, start a new walk cycle
		if desired_direction != 0:
			# Start a new walk cycle
			start_walk_cycle(desired_direction)
		else:
			# Return to idle
			play_animation("idle")
