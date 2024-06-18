extends CharacterBody2D

const SPEED = 400.0
const JUMP_VELOCITY = -500.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Sprite animation node
@onready var anim_node: AnimatedSprite2D = get_node("AnimatedSprite2D")

# Timer for briefly limiting movement during bounces and injuries
@onready var bounce_timer: Timer = get_node("BounceTimer")

func _physics_process(delta):
	# Make the DebugSprite invisible
	$DebugSprite.visible = false
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("left", "right")
	if bounce_timer.is_stopped():
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, (SPEED / 8))
		
	# Add the gravity with terminal velocity
	# Modify velocity if we are "wall sliding"
	if not is_on_floor():
		if is_on_wall() and velocity.y > -10 and direction != 0:
			# In case we hit are able to latch onto a wall after falling a while
			# check the velocity and quarter it until we are under a sliding speed
			if velocity.y > 100:
				velocity.y = velocity.y * .25
		if velocity.y < 800:
			velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_wall()):
		$JumpSound.play()
		anim_node.play("jump")
		velocity.y = JUMP_VELOCITY
		if is_on_wall_only():
			velocity.x = -50 * anim_node.scale.x
			bounce_timer.start()
		
	# Set direction based on velocity
	if velocity.x >= 0:
		anim_node.scale.x = 1
	else:
		anim_node.scale.x = -1
	# make sure there is always some animation playing
	# play appropriate sounds for movement
	if is_on_floor():
		if velocity.x == 0:
			anim_node.play("default")
		else:
			anim_node.play("move")
			if $StepSounds.is_playing() == false:
				$StepSounds.play()
	else:
		if velocity.y >= 0:
			if is_on_wall() and direction != 0:
				anim_node.play("dodge_stop")
			else:
				anim_node.play("fall")
		else:
			anim_node.play("jump")
	move_and_slide()

func _on_animated_sprite_2d_animation_finished():
	if velocity.y > 0:
		anim_node.play("fall")
	if is_on_floor():
		if velocity.x == 0:
			anim_node.play("default")
		else:
			anim_node.play("move")
		

func _on_step_sounds_finished():
	if anim_node.animation == "move":
		$StepSounds.play()
