extends CharacterBody2D

# Control configuration
var control_set: String = "player1" 			# Can be "player1" or "player2"

# Health and Endurance
var current_health: int = 100
var current_endurance: float = 100.0
const MAX_HEALTH: int = 100
const MAX_ENDURANCE: int = 100
const MAX_ENDURANCE_SPENT: int = 50
const MAX_DAMAGE_DEALT: int = 40
const MIN_DAMAGE_DEALT: int = 5
const ENDURANCE_HEALING_RATE: float = 2.0
const PUNCH_ENDURANCE_COST: int = 25
const PUNCH_COOLDOWN: float = 0.5     			# Time between punches
const SIMULTANEOUS_PUNCH_COST: int = 50

# Block-related constants
const BLOCK_ENDURANCE_COST: int = 15
const BLOCK_ATTACKER_ENDURANCE_COST: int = 10
const BLOCK_COOLDOWN: float = 0.2				# Short cooldown before blocking again
const KNOCKBACK_DISTANCE: float = 20.0			# Distance to push back when hit

# Movement parameters
const WALK_DISTANCE: float = 30.0

# Player information
var player_color: Color = Color(1, 1, 1, 1)

# animation and movement state
var current_animation: String = "idle"
var walk_in_progress: bool = false
var walk_direction: int = 0
var walk_start_position: Vector2 = Vector2.ZERO
var walk_target_position: Vector2 = Vector2.ZERO
var walk_progress: float = 0.0
var desired_direction: int = 0
var can_punch: bool = true
var is_punching: bool = false
var punch_timer: float = 0.0
var stagger_timer: float = 0.0
# blocking variables
var is_blocking: bool = false
var can_block: bool = true
var block_timer: float = 0.0
# Knockback variables
var is_knocked_back: bool = false
var knockback_direction: int = 0
var knockback_start_position: Vector2 = Vector2.ZERO
var knockback_target_position: Vector2 = Vector2.ZERO
var knockback_progress: float = 0.0
# Simultaneous punch variables
var is_in_simultaneous_punch: bool = false
var wants_to_punch: bool = false  # Tracks if player just pressed the punch button
# Fist collision
var detected_fist_collision: bool = false
# Reference to opponent
var opponent: CharacterBody2D = null

@onready var animation_player = $AnimationPlayer
@onready var hit_box = $hit_area
@onready var knuckle_box = $hit_area/knuckle_box
@onready var camera: Node = get_tree().get_first_node_in_group("camera")

func _ready():
	# Set the animation
	animation_player.play("idle")
	animation_player.animation_finished.connect(_on_animation_finished)

	# Apply color to all body parts
	apply_player_color(player_color)
	
	# Setup collision detection
	$hit_area/knuckle_box.disabled = true
	$hit_area.body_entered.connect(_on_hit_area_body_entered)
	# Add area_entered connection for knuckle box collision
	$hit_area.area_entered.connect(_on_hit_area_area_entered)
	

func apply_player_color(color):
	# Apply color to torso and limbs
	$Skeleton2D/Hip/Torso/TorsoSprite.color = color
	$Skeleton2D/Hip/ThighL/ThighSpriteL.color = color
	$Skeleton2D/Hip/ThighR/ThighSpriteR.color = color
	$Skeleton2D/Hip/ThighL/LowerLegL/LowerLegSpriteL.color = color
	$Skeleton2D/Hip/ThighR/LowerLegR/LowerLegSpriteR.color = color
	$Skeleton2D/Hip/Torso/ShoulderL/UpperArmL/UpperArmSpriteL.color = color
	$Skeleton2D/Hip/Torso/ShoulderR/UpperArmR/UpperArmSpriteR.color = color

func _physics_process(delta) -> void:
	
	if current_endurance < MAX_ENDURANCE:
		var healing_amount = ENDURANCE_HEALING_RATE * delta
		current_endurance = min(current_endurance + healing_amount, MAX_ENDURANCE)
		
	if !can_punch:
		punch_timer -= delta
		if punch_timer <= 0:
			can_punch = true
	
	if !can_block:
		block_timer -= delta
		if block_timer <= 0:
			can_block = true
			
	if stagger_timer > 0:
		stagger_timer -= delta
		return
	
	# If in a simultaneous punch, don't process regular inputs
	if is_in_simultaneous_punch:
		velocity.x = 0
		return
		
	# Process inputs based on control set
	var block_input: bool = false
	wants_to_punch = false  # Reset at the start of each frame
	
	if control_set == "player1":
		desired_direction = Input.get_axis("p1_left", "p1_right")
		wants_to_punch = Input.is_action_just_pressed("p1_attack")
		handle_punch_input(wants_to_punch)
		block_input = Input.is_action_pressed("p1_block")
	else:
		desired_direction = Input.get_axis("p2_left", "p2_right")
		wants_to_punch = Input.is_action_just_pressed("p2_attack")
		handle_punch_input(wants_to_punch)
		block_input = Input.is_action_pressed("p2_block")
	
	# Handle blocking
	handle_block_input(block_input)
	
	if control_set != "player1":
		hit_box.scale.x = -1

	if is_knocked_back:
		# Process knockback
		process_knockback(delta)
	elif is_punching:
		# Currently in punch animation - don't allow movement
		velocity.x = 0
		
		# Check for fist collision when both players are punching
		if detected_fist_collision and opponent and opponent.is_punching:
			# Both players are punching and a fist collision was detected
			detected_fist_collision = false  # Reset flag
			try_start_simultaneous_punch()
			
	elif is_blocking:
		# Can't move while blocking
		velocity.x = 0
	elif walk_in_progress:
		# Currently in a walk cycle
		process_walk_cycle(delta)
	else:
		# Not in a walk cycle - check if we should start one
		if desired_direction != 0:
			start_walk_cycle(desired_direction)
		else:
			# Idle state - no horizontal velocity
			velocity.x = 0
			if current_animation != "idle" and !is_punching and !is_blocking:
				play_animation("idle")

	# Apply movement
	move_and_slide()

func handle_punch_input(is_punch_pressed):
	if is_punch_pressed and can_punch and !is_punching and !walk_in_progress and !is_blocking and !is_knocked_back:
		throw_punch()

func handle_block_input(is_block_pressed):
	if is_block_pressed and can_block and !is_punching and !walk_in_progress and !is_knocked_back and !is_in_simultaneous_punch:
		if !is_blocking:
			start_blocking()
	elif is_blocking:  # If we were blocking but now released the button
		stop_blocking()

func start_blocking():
	# Begin blocking stance
	is_blocking = true
	play_animation("block")

func stop_blocking():
	# End blocking stance
	is_blocking = false
	can_block = false
	block_timer = BLOCK_COOLDOWN
	
	if current_animation == "block":
		play_animation("idle")
	

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

func throw_punch():
	# Perform punch
	is_punching = true
	can_punch = false
	punch_timer = PUNCH_COOLDOWN
	
	# Play punch animation
	play_animation("punch1")
	
	# Enable the knuckle hitbox during punch
	$hit_area/knuckle_box.disabled = false
	
	# Reset fist collision detection
	detected_fist_collision = false
	
	# Add camera effects
	var effect_magnitude = max(0.2, float(current_endurance) / MAX_ENDURANCE)
	camera.set_zoom_str(1.0 + (0.01 * effect_magnitude))
	camera.set_shake_str(Vector2(2, 2) * effect_magnitude)

func try_start_simultaneous_punch() -> bool:
	# Check if both players can perform simultaneous punch
	if is_in_simultaneous_punch or !opponent or opponent.is_in_simultaneous_punch:
		return false
		
	
	# Check if both have enough endurance
	if current_endurance >= SIMULTANEOUS_PUNCH_COST or opponent.current_endurance >= SIMULTANEOUS_PUNCH_COST or current_endurance < SIMULTANEOUS_PUNCH_COST or opponent.current_endurance < SIMULTANEOUS_PUNCH_COST:
		var success1: bool = start_simultaneous_punch()
		var success2       = opponent.start_simultaneous_punch()
		
		if success1 and success2:
			# Add special camera effect
			camera.set_zoom_str(1.1)  # Dramatic zoom
			camera.set_shake_str(Vector2(8, 8))  # Strong shake
			return true
	
	return false

func start_simultaneous_punch() -> bool:
		
	# Set state for simultaneous punch
	is_in_simultaneous_punch = true
	is_punching = false  # Reset regular punch state
	
	# Deduct endurance - now using exactly 50 points
	var endurance_before: float = current_endurance
	current_endurance = max(0, current_endurance - SIMULTANEOUS_PUNCH_COST)
	
	# Play the special animation
	play_animation("simultaneous_punch")
	
	# Disable hitbox
	$hit_area/knuckle_box.disabled = true
	
	# Add special camera effects
	camera.set_zoom_str(1.05)  # More dramatic zoom for the special move
	camera.set_shake_str(Vector2(4, 4))  # More dramatic shake
	
	return true

func end_simultaneous_punch():
	is_in_simultaneous_punch = false
	can_punch = false  # Brief cooldown after the special move
	punch_timer = PUNCH_COOLDOWN * 2  # Longer cooldown for special move
	
	play_animation("idle")

func start_knockback(direction):
	# Set knockback parameters
	is_knocked_back = true
	knockback_direction = direction
	knockback_start_position = global_position
	
	# The direction passed should already account for relative positions
	knockback_target_position = knockback_start_position + Vector2(direction * KNOCKBACK_DISTANCE, 0)
	knockback_progress = 0.0
	
	# Play stagger animation
	play_animation("stagger")
	
func process_knockback(delta):
	# Use a fixed time for the knockback (0.3 seconds)
	var knockback_time: float = 0.3
	
	# Calculate how much to advance this frame
	var progress_increment = delta / knockback_time
	knockback_progress += progress_increment
	
	# Cap progress at 1.0
	knockback_progress = min(knockback_progress, 1.0)
	
	# Update position based on linear interpolation
	global_position = knockback_start_position.lerp(knockback_target_position, knockback_progress)
	
	# Set velocity to match the visual movement (for physics interactions)
	velocity.x = knockback_direction * KNOCKBACK_DISTANCE / knockback_time
	
	# End knockback when complete
	if knockback_progress >= 1.0:
		is_knocked_back = false
		
# The editor says this is unused, but it's used
func take_damage(damage_amount, attacker_position) -> void:
	# Skip damage if in simultaneous punch animation
	if is_in_simultaneous_punch:
		return
		
	# Determine knockback direction based on attacker position
	var knockback_dir: int = 0
	if attacker_position.x < global_position.x:
		knockback_dir = 1  # Knock to the right
	else:
		knockback_dir = -1  # Knock to the left
		
	# If blocking, prevent damage but consume endurance
	if is_blocking:
		
		# Reduce endurance from blocking the hit (15 points)
		var endurance_before: float = current_endurance
		if current_endurance >= BLOCK_ENDURANCE_COST:
			current_endurance -= BLOCK_ENDURANCE_COST
		else:
			current_endurance = 0
			stop_blocking()  # Can't block without endurance
			
		
		# Camera effects for block impact - less than taking damage
		camera.set_zoom_str(1.01)
		camera.set_shake_str(Vector2(2, 2))
		
		# Still apply knockback and animation when blocking
		start_knockback(knockback_dir)
		
		return
	
	# Apply damage to health if not blocking
	var health_before: int = current_health
	current_health = max(0, current_health - damage_amount)
	
	# Visual feedback
	stagger_timer = 0.3  # Brief stagger effect
	
	# Camera effects for hit impact
	camera.set_zoom_str(1.03)
	camera.set_shake_str(Vector2(4, 4))
	
	# Apply knockback
	start_knockback(knockback_dir)
	

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
	if (anim_name == "walk" or anim_name == "walk_backwards"):
		walk_in_progress = false
		play_animation("idle")
	elif anim_name == "punch1":
		# End punch state
		is_punching = false
		$hit_area/knuckle_box.disabled = true
		play_animation("idle")
	elif anim_name == "stagger":
		play_animation("idle")
	elif anim_name == "block":
		# The block animation continues looping as long as the button is held
		if is_blocking:
			play_animation("block")  # Replay the animation to continue blocking
	elif anim_name == "simultaneous_punch":
		# End simultaneous punch state
		end_simultaneous_punch()

# Called when another area enters the hit_area
func _on_hit_area_area_entered(area) -> void:
	# Skip if in simultaneous punch or not punching
	if is_in_simultaneous_punch or !is_punching:
		return
		
	# Check if this is a hit_area from another player
	if area is Area2D and area.get_parent() != self and area.get_parent() is CharacterBody2D:
		var other_player: Node = area.get_parent()
		
		# Check if this is the opponent's hit_area
		if other_player == opponent and opponent.is_punching:
			# Detect collision between active knuckle boxes
			if !$hit_area/knuckle_box.disabled and !opponent.get_node("hit_area/knuckle_box").disabled:
				detected_fist_collision = true
				
				# Try to start simultaneous punch immediately
				try_start_simultaneous_punch()

func _on_hit_area_body_entered(body) -> void:
	# Skip hit detection if in simultaneous punch
	if is_in_simultaneous_punch:
		return
		
	# Check if we hit the other player
	if body is CharacterBody2D and body != self:
		# Make sure we're in a punch animation and our knuckle box is enabled
		if is_punching and !$hit_area/knuckle_box.disabled:
			# NOW we deduct endurance for a successful hit (25 points)
			var endurance_before: float = current_endurance
			
			# Deduct endurance but don't go below 0
			if current_endurance >= PUNCH_ENDURANCE_COST:
				current_endurance -= PUNCH_ENDURANCE_COST
			else:
				current_endurance = 0
			
			# Calculate damage based on current endurance - enhanced formula
			# Use a more exponential curve to reward high endurance
			var damage_percent: float = pow(float(current_endurance) / MAX_ENDURANCE, 1.5)
			
			# At 0 endurance = MIN_DAMAGE, at full endurance = MAX_DAMAGE
			var damage: int = MIN_DAMAGE_DEALT
			if current_endurance > 0:
				damage = int(MIN_DAMAGE_DEALT + damage_percent * (MAX_DAMAGE_DEALT - MIN_DAMAGE_DEALT))
				
			# Ensure damage doesn't exceed maximum
			damage = min(damage, MAX_DAMAGE_DEALT)
			
			# Apply damage to the other fighter - pass our position for knockback direction
			body.take_damage(damage, global_position)
			
			# If opponent is blocking, attacker also loses some endurance from hitting the block (10 points)
			if body.is_blocking:
				endurance_before = current_endurance
				if current_endurance >= BLOCK_ATTACKER_ENDURANCE_COST:
					current_endurance -= BLOCK_ATTACKER_ENDURANCE_COST
				else:
					current_endurance = 0
			
			# Disable knuckle box to prevent multiple hits
			$hit_area/knuckle_box.disabled = true
			
			# Add extra camera shake on impact based on damage
			var impact_strength: float = float(damage) / MAX_DAMAGE_DEALT
			camera.set_shake_str(Vector2(5, 5) * impact_strength)
