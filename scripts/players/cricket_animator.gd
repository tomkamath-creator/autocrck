# scripts/players/cricket_animator.gd
# Procedural Skeletal Animation Engine for CricStrike 3D
# Enforces 100% upright kinematics and drives realistic batting, bowling, fielding, and umpire animations.
class_name CricketAnimator
extends RefCounted

var model_root: Node3D
var current_anim: String = "stance"
var anim_time: float = 0.0
var anim_speed: float = 1.0
var is_looping: bool = true

# Skeleton joint references
var hips: Node3D
var spine: Node3D
var chest: Node3D
var head: Node3D
var left_shoulder: Node3D
var right_shoulder: Node3D
var left_elbow: Node3D
var right_elbow: Node3D
var left_hip: Node3D
var right_hip: Node3D
var left_knee: Node3D
var right_knee: Node3D
var bat: Node3D

func init(root: Node3D) -> void:
	model_root = root
	_cache_bones()

func _cache_bones() -> void:
	if not model_root:
		return
	hips = model_root.get_node_or_null("Hips")
	if hips:
		spine = hips.get_node_or_null("Spine")
		left_hip = hips.get_node_or_null("LeftHipJoint")
		right_hip = hips.get_node_or_null("RightHipJoint")
		if left_hip:
			left_knee = left_hip.get_node_or_null("LeftKnee")
		if right_hip:
			right_knee = right_hip.get_node_or_null("RightKnee")
	if spine:
		chest = spine.get_node_or_null("Chest")
	if chest:
		var neck = chest.get_node_or_null("Neck")
		if neck:
			head = neck.get_node_or_null("Head")
		left_shoulder = chest.get_node_or_null("LeftShoulder")
		right_shoulder = chest.get_node_or_null("RightShoulder")
		if left_shoulder:
			left_elbow = left_shoulder.get_node_or_null("LeftElbow")
		if right_shoulder:
			right_elbow = right_shoulder.get_node_or_null("RightElbow")
			var r_hand = right_elbow.get_node_or_null("RightHand") if right_elbow else null
			if r_hand:
				bat = r_hand.get_node_or_null("CricketBat")

func play(anim_name: String, speed: float = 1.0, loop: bool = false) -> void:
	if current_anim != anim_name:
		current_anim = anim_name
		anim_time = 0.0
	anim_speed = speed
	is_looping = loop

func update(delta: float) -> void:
	anim_time += delta * anim_speed
	_apply_animation_pose(current_anim, anim_time)

func _apply_animation_pose(anim: String, t: float) -> void:
	if not hips:
		return
	
	match anim:
		# ----------------- BATTING ANIMATIONS -----------------
		"stance":
			# Balanced sideways stance at popping crease, rhythmic bat tap
			var tap = sin(t * 7.0) * 0.5 + 0.5 # Bat tap cycle
			hips.rotation_degrees = Vector3(0, 75, 0) # Sideways body
			if chest: chest.rotation_degrees = Vector3(0, -10, 0)
			if head: head.rotation_degrees = Vector3(0, -65, 0) # Head facing bowler
			if left_hip: left_hip.rotation_degrees = Vector3(15, 0, 0)
			if right_hip: right_hip.rotation_degrees = Vector3(12, 0, 0)
			if left_knee: left_knee.rotation_degrees = Vector3(-25, 0, 0)
			if right_knee: right_knee.rotation_degrees = Vector3(-20, 0, 0)
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(-25, 0, -20)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(-15, 0, 15)
			if right_elbow: right_elbow.rotation_degrees = Vector3(-45, 0, 0)
			if bat: bat.rotation_degrees = Vector3(-35 + (tap * 20.0), 10, 0)

		"front_foot_drive":
			# Fluid stride forward, high elbow, bat swings down the line
			var p = clampf(t / 0.45, 0.0, 1.0)
			hips.rotation_degrees = Vector3(0, lerp(75.0, 30.0, p), 0)
			if left_hip: left_hip.rotation_degrees = Vector3(lerp(15.0, 50.0, p), 0, 0) # Front foot stride
			if left_knee: left_knee.rotation_degrees = Vector3(lerp(-25.0, -45.0, p), 0, 0)
			if right_hip: right_hip.rotation_degrees = Vector3(lerp(12.0, -20.0, p), 0, 0) # Back foot anchor
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(lerp(-25.0, -85.0, p), 0, -35) # High lead elbow
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(lerp(-15.0, -70.0, p), 0, 15)
			if right_elbow: right_elbow.rotation_degrees = Vector3(lerp(-45.0, -15.0, p), 0, 0)
			if bat: bat.rotation_degrees = Vector3(lerp(-40.0, 65.0, p), 10, 0) # Full forward swing

		"lofted_drive":
			# Explosive upward bat swing through the line, high backlift and follow-through
			var p = clampf(t / 0.50, 0.0, 1.0)
			hips.rotation_degrees = Vector3(0, lerp(75.0, 20.0, p), 0)
			if spine: spine.rotation_degrees = Vector3(-lerp(0.0, 20.0, p), 0, 0) # Torso arch
			if left_hip: left_hip.rotation_degrees = Vector3(45, 0, 0)
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(lerp(-25.0, -135.0, p), 0, -25)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(lerp(-15.0, -130.0, p), 0, 20)
			if bat: bat.rotation_degrees = Vector3(lerp(-60.0, 110.0, p), 0, 0) # High finish over shoulder

		"pull_shot":
			# Back foot pivot, horizontal bat blade pulling the ball
			var p = clampf(t / 0.42, 0.0, 1.0)
			hips.rotation_degrees = Vector3(0, lerp(75.0, -45.0, p), 0) # Pivot towards leg side
			if right_hip: right_hip.rotation_degrees = Vector3(30, 0, 0) # Deep back foot
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(-45, lerp(0.0, 60.0, p), 0)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(-40, lerp(0.0, -70.0, p), 0)
			if bat: bat.rotation_degrees = Vector3(10, lerp(-30.0, 95.0, p), -60) # Horizontal sweep

		"cut_shot":
			# Back foot stride, slicing the bat down through point/third man
			var p = clampf(t / 0.40, 0.0, 1.0)
			hips.rotation_degrees = Vector3(0, 60, 0)
			if right_hip: right_hip.rotation_degrees = Vector3(25, 0, 0)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(lerp(-80.0, -10.0, p), 35, 10)
			if bat: bat.rotation_degrees = Vector3(lerp(-70.0, 30.0, p), 45, 25)

		"helicopter_shot":
			# Low wrist flick whipping over deep mid-wicket with full 360 bat twirl
			var p = clampf(t / 0.55, 0.0, 1.0)
			hips.rotation_degrees = Vector3(0, lerp(70.0, -30.0, p), 0)
			if left_hip: left_hip.rotation_degrees = Vector3(40, 0, 0)
			if left_knee: left_knee.rotation_degrees = Vector3(-55, 0, 0) # Deep flex
			var twirl = p * 360.0
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(-60, 0, 45)
			if bat: bat.rotation_degrees = Vector3(30, sin(deg_to_rad(twirl)) * 60.0, twirl)

		"defend_forward":
			# Soft hands forward defensive block deadening ball into turf
			var p = clampf(t / 0.35, 0.0, 1.0)
			hips.rotation_degrees = Vector3(0, 65, 0)
			if left_hip: left_hip.rotation_degrees = Vector3(lerp(15.0, 40.0, p), 0, 0)
			if left_knee: left_knee.rotation_degrees = Vector3(-35, 0, 0)
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(-55, 0, -20)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(-45, 0, 15)
			if bat: bat.rotation_degrees = Vector3(lerp(-30.0, 25.0, p), 0, 0) # Angled face down

		"leave":
			# High bat lift and recoil letting ball sail to keeper
			var p = clampf(t / 0.35, 0.0, 1.0)
			hips.rotation_degrees = Vector3(0, 80, 0)
			if chest: chest.rotation_degrees = Vector3(-15, -15, 0) # Recoil back
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(-95, 0, 20) # Bat high up
			if bat: bat.rotation_degrees = Vector3(-85, 0, 0)

		"celebration_bat_raise":
			# Batsman raises bat vertically to pavilion on 50 or 100 runs
			hips.rotation_degrees = Vector3(0, 0, 0)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(-160, 0, 15)
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(-160, 0, -15)
			if bat: bat.rotation_degrees = Vector3(-10, 0, 0)

		# ----------------- BOWLING ANIMATIONS -----------------
		"runup":
			# Athletic sprint approach strides with alternating arms and legs
			var stride = sin(t * 14.0)
			hips.rotation_degrees = Vector3(10, 0, 0) # Slight forward lean
			if left_hip: left_hip.rotation_degrees = Vector3(stride * 45.0, 0, 0)
			if right_hip: right_hip.rotation_degrees = Vector3(-stride * 45.0, 0, 0)
			if left_knee: left_knee.rotation_degrees = Vector3(clampf(-stride * 55.0, -70.0, 0.0), 0, 0)
			if right_knee: right_knee.rotation_degrees = Vector3(clampf(stride * 55.0, -70.0, 0.0), 0, 0)
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(-stride * 50.0, 0, -15)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(stride * 50.0, 0, 15)

		"delivery_stride":
			# Crease bound, front foot plant, 360 overarm windmill rotation & release
			var p = clampf(t / 0.65, 0.0, 1.0)
			var windmill_arm = -p * 360.0 # 360 degree overarm bowling action
			hips.rotation_degrees = Vector3(lerp(0.0, 25.0, p), lerp(20.0, -15.0, p), 0)
			if left_hip: left_hip.rotation_degrees = Vector3(lerp(-10.0, 50.0, p), 0, 0) # Solid front foot brace
			if left_knee: left_knee.rotation_degrees = Vector3(-15, 0, 0) # Braced front leg
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(windmill_arm, 0, 10) # 360 windmill
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(lerp(-120.0, 40.0, p), 0, -20) # Non-bowling arm pull down

		"celebration_wicket":
			# Bowler leaps in jubilation, fist-pumping and high-five gesture
			var leap = sin(t * 8.0) * 0.15
			hips.position.y = 0.98 + maxf(0.0, leap)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(-150, 0, 30) # High fist pump
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(-120, 0, -25)

		# ----------------- FIELDING & KEEPING ANIMATIONS -----------------
		"keeper_crouch":
			# Low athletic squat behind stumps with gloves raised
			hips.position.y = 0.62 # Lowered hips in squat
			if left_hip: left_hip.rotation_degrees = Vector3(65, 0, -15)
			if right_hip: right_hip.rotation_degrees = Vector3(65, 0, 15)
			if left_knee: left_knee.rotation_degrees = Vector3(-85, 0, 0)
			if right_knee: right_knee.rotation_degrees = Vector3(-85, 0, 0)
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(-35, 0, -20)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(-35, 0, 20)
			if left_elbow: left_elbow.rotation_degrees = Vector3(-45, 0, 0)
			if right_elbow: right_elbow.rotation_degrees = Vector3(-45, 0, 0)

		"fielder_ready":
			# Athletic slip/ring crouch with hands on knees
			hips.position.y = 0.85
			if left_hip: left_hip.rotation_degrees = Vector3(35, 0, 0)
			if right_hip: right_hip.rotation_degrees = Vector3(35, 0, 0)
			if left_knee: left_knee.rotation_degrees = Vector3(-40, 0, 0)
			if right_knee: right_knee.rotation_degrees = Vector3(-40, 0, 0)
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(-25, 0, -15)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(-25, 0, 15)

		"fielder_sprint":
			# Dynamic pursuit sprint
			var stride = sin(t * 16.0)
			hips.rotation_degrees = Vector3(15, 0, 0)
			if left_hip: left_hip.rotation_degrees = Vector3(stride * 55.0, 0, 0)
			if right_hip: right_hip.rotation_degrees = Vector3(-stride * 55.0, 0, 0)
			if left_knee: left_knee.rotation_degrees = Vector3(clampf(-stride * 65.0, -80.0, 0.0), 0, 0)
			if right_knee: right_knee.rotation_degrees = Vector3(clampf(stride * 65.0, -80.0, 0.0), 0, 0)
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(-stride * 60.0, 0, -15)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(stride * 60.0, 0, 15)

		"fielder_slide_pickup":
			# Sliding ground pickup scoop
			var p = clampf(t / 0.5, 0.0, 1.0)
			hips.position.y = lerp(0.98, 0.35, sin(p * PI))
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(lerp(0.0, 45.0, sin(p * PI)), 0, 0)

		"fielder_throw":
			# Overarm rocket throw back to stumps
			var p = clampf(t / 0.45, 0.0, 1.0)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(lerp(-140.0, 30.0, p), 0, 15)
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(lerp(0.0, -50.0, p), 0, -20)

		# ----------------- UMPIRE SIGNALS -----------------
		"umpire_out":
			# Slow dramatic raised index finger
			var p = clampf(t / 0.8, 0.0, 1.0)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(lerp(0.0, -165.0, p), 0, 10)

		"umpire_four":
			# Side to side arm wave across the waist
			var wave = sin(t * 6.0) * 35.0
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(-20, wave, 45)

		"umpire_six":
			# Both arms raised high overhead
			var p = clampf(t / 0.6, 0.0, 1.0)
			if right_shoulder: right_shoulder.rotation_degrees = Vector3(lerp(0.0, -170.0, p), 0, 15)
			if left_shoulder: left_shoulder.rotation_degrees = Vector3(lerp(0.0, -170.0, p), 0, -15)
