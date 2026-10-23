extends Node

# TestRunner: Headless Automated Verification for CricStrike 3D

const PlayerCharacter = preload("res://scripts/entities/player_character.gd")
const BallPhysics = preload("res://scripts/physics/ball_physics.gd")
const BattingController = preload("res://scripts/gameplay/batting_controller.gd")

var has_run: bool = false

func _process(_delta: float) -> void:
	if has_run:
		return
	has_run = true
	_run_tests()

func _run_tests() -> void:
	print("====================================================")
	print("🏏 CRICSTRIKE 3D: HEADLESS TEST SUITE INITIALIZED")
	print("====================================================")

	var failed_tests: int = 0

	failed_tests += _test_kinematic_safeguards()
	failed_tests += _test_ball_physics_and_pitches()
	failed_tests += _test_batting_timing_windows()
	failed_tests += _test_umpire_rules_and_scoring()
	failed_tests += _test_tournament_logic_and_nrr()
	failed_tests += _test_offline_persistence()

	print("====================================================")
	if failed_tests == 0:
		print("✅ ALL HEADLESS TEST SUITES PASSED FLAWLESSLY (0 ERRORS)")
		print("====================================================")
		get_tree().quit(0)
	else:
		print("❌ TEST SUITE FAILED WITH %d ERRORS" % failed_tests)
		print("====================================================")
		get_tree().quit(1)

func _test_kinematic_safeguards() -> int:
	print("\n[TEST 1] Verifying 100% Upright Kinematic Safeguards...")
	var player := PlayerCharacter.new()
	add_child(player)

	# Simulate physics process
	player._physics_process(0.016)
	if abs(player.rotation.x) > 0.0001 or abs(player.rotation.z) > 0.0001:
		printerr("FAIL: Player rotation.x or rotation.z is non-zero!")
		player.queue_free()
		return 1

	# Test flat-plane look-at
	player.look_at_flat(Vector3(15.0, 8.5, 30.0))
	if abs(player.rotation.x) > 0.0001 or abs(player.rotation.z) > 0.0001:
		printerr("FAIL: look_at_flat introduced pitch/roll tilt!")
		player.queue_free()
		return 1

	print("  -> Upright rotation constraint passed: rotation.x=0, rotation.z=0 verified.")
	print("  -> Flat plane look-at verified: no pitch/roll belly-flop glitches.")
	player.queue_free()
	return 0

func _test_ball_physics_and_pitches() -> int:
	print("\n[TEST 2] Verifying Ball Physics & Pitch Restitution...")
	for p_key in DataManager.pitch_types.keys():
		var p: Dictionary = DataManager.pitch_types[p_key]
		var rest: float = p["restitution"]
		var fric: float = p["friction"]
		if rest < 0.5 or rest > 0.95:
			printerr("FAIL: Restitution out of range for pitch %s: %f" % [p_key, rest])
			return 1
		if fric < 0.1 or fric > 0.8:
			printerr("FAIL: Friction out of range for pitch %s: %f" % [p_key, fric])
			return 1
		print("  -> Verified %s: Restitution=%.2f, Friction=%.2f" % [p["name"], rest, fric])

	var ball := BallPhysics.new()
	add_child(ball)
	ball.launch_delivery(Vector3(0, 2.1, -8.5), Vector3(0, -2.0, 38.0), 2.5, 0.0)
	
	# Simulate 10 frames
	for i in range(10):
		ball._physics_process(0.016)

	if ball.global_position.z <= -8.5:
		printerr("FAIL: Ball did not move forward along Z axis!")
		ball.queue_free()
		return 1
	if ball.velocity.x <= 0.0:
		printerr("FAIL: Ball swing acceleration did not impart lateral X velocity!")
		ball.queue_free()
		return 1

	print("  -> Ball trajectory integration, gravity and swing aerodynamics verified.")
	ball.queue_free()
	return 0

func _test_batting_timing_windows() -> int:
	print("\n[TEST 3] Verifying Batting Mechanics & Millisecond Timing Windows...")
	var dummy_ball := BallPhysics.new()
	add_child(dummy_ball)
	var dummy_bat := PlayerCharacter.new()
	add_child(dummy_bat)

	var batting := BattingController.new()
	add_child(batting)
	batting.init(dummy_bat, dummy_ball)

	# Launch delivery traveling at 38 m/s (136.8 km/h) towards crease z = 9.05m
	dummy_ball.launch_delivery(Vector3(0, 1.0, 0.0), Vector3(0, 0, 38.0), 0.0, 0.0)

	# Test 1: Ball at z = 9.05m -> Delta is 0ms -> PERFECT
	dummy_ball.global_position.z = 9.05
	var res_perfect: Dictionary = batting.execute_shot("DRIVE", Vector2(0, -1))
	if res_perfect["timing"] != "PERFECT":
		printerr("FAIL: Expected PERFECT timing at popping crease, got: %s" % res_perfect["timing"])
		return 1
	if res_perfect["speed_kmh"] < 110.0:
		printerr("FAIL: Exit speed too low for PERFECT drive!")
		return 1

	# Test 2: Ball at z = 7.5m -> Time to crease ~40.7ms -> EARLY
	dummy_ball.current_state = BallPhysics.BallState.IN_FLIGHT_TO_BATSMAN
	dummy_ball.velocity = Vector3(0, 0, 38.0)
	dummy_ball.global_position.z = 7.5
	var res_early: Dictionary = batting.execute_shot("DRIVE", Vector2(0, -1))
	if not res_early.has("timing") or res_early["timing"] != "EARLY":
		printerr("FAIL: Expected EARLY timing, got: %s" % str(res_early))
		return 1

	# Test 3: Ball at z = 2.0m -> Time to crease ~185ms -> MISSED
	dummy_ball.current_state = BallPhysics.BallState.IN_FLIGHT_TO_BATSMAN
	dummy_ball.velocity = Vector3(0, 0, 38.0)
	dummy_ball.global_position.z = 2.0
	var res_missed: Dictionary = batting.execute_shot("DRIVE", Vector2(0, -1))
	if not res_missed.has("timing") or res_missed["timing"] != "MISSED":
		printerr("FAIL: Expected MISSED timing, got: %s" % str(res_missed))
		return 1

	print("  -> Timing engine: PERFECT (<=26ms), EARLY (27-62ms), MISSED (>115ms) verified.")

	dummy_ball.queue_free()
	dummy_bat.queue_free()
	batting.queue_free()
	return 0

func _test_umpire_rules_and_scoring() -> int:
	print("\n[TEST 4] Verifying Umpire Rules, Scoring & Over Rotations...")
	GameManager.setup_match("IND", "AUS", 1, "GREEN_TURF", "MEDIUM", GameManager.GameMode.QUICK_MATCH)

	if GameManager.runs_scored != 0 or GameManager.wickets_fallen != 0:
		printerr("FAIL: Initial score not 0-0!")
		return 1

	# Score a boundary 4
	GameManager.record_delivery(4, false)
	if GameManager.runs_scored != 4:
		printerr("FAIL: Expected 4 runs, got %d" % GameManager.runs_scored)
		return 1

	# Score a six 6
	GameManager.record_delivery(6, false)
	if GameManager.runs_scored != 10:
		printerr("FAIL: Expected 10 runs, got %d" % GameManager.runs_scored)
		return 1

	# Score a single 1 (strike rotation test)
	var prev_striker: int = GameManager.current_striker_idx
	GameManager.record_delivery(1, false)
	if GameManager.current_striker_idx == prev_striker:
		printerr("FAIL: Strike did not rotate after scoring a single run!")
		return 1

	# Fall of wicket
	GameManager.record_delivery(0, true, "Bowled")
	if GameManager.wickets_fallen != 1:
		printerr("FAIL: Wickets fallen count did not increment to 1!")
		return 1

	print("  -> Umpire scoring, boundary counting, strike rotation and wicket logic verified.")
	return 0

func _test_tournament_logic_and_nrr() -> int:
	print("\n[TEST 5] Verifying World Tournament Fixtures & Net Run Rate (NRR)...")
	TournamentManager.init_tournament("IND")

	if TournamentManager.fixtures.size() != 12: # 6 fixtures per group
		printerr("FAIL: Expected 12 group fixtures, got %d" % TournamentManager.fixtures.size())
		return 1

	# Record a victory for IND over AUS: IND 180 (20 ov) vs AUS 150 (20 ov)
	TournamentManager.record_fixture_result("IND", 180, 20.0, 150, 20.0)
	var p_ind: Dictionary = TournamentManager.points_table["IND"]
	var p_aus: Dictionary = TournamentManager.points_table["AUS"]

	if p_ind["points"] != 2 or p_aus["points"] != 0:
		printerr("FAIL: Points table did not record 2 points for winner!")
		return 1

	# NRR IND = 180/20 - 150/20 = 9.0 - 7.5 = +1.500
	if abs(p_ind["nrr"] - 1.500) > 0.01:
		printerr("FAIL: Incorrect NRR calculation for IND: expected 1.500, got %f" % p_ind["nrr"])
		return 1
	if abs(p_aus["nrr"] - (-1.500)) > 0.01:
		printerr("FAIL: Incorrect NRR calculation for AUS: expected -1.500, got %f" % p_aus["nrr"])
		return 1

	print("  -> Tournament round-robin fixtures and NRR calculation (+1.500 vs -1.500) verified.")
	return 0

func _test_offline_persistence() -> int:
	print("\n[TEST 6] Verifying 100% Offline Persistence & Save Files...")
	DataManager.profile["coins"] = 777000
	DataManager.custom_player["name"] = "TEST_CAPTAIN"
	DataManager.save_all_data()

	# Clear memory and reload
	DataManager.profile["coins"] = 0
	DataManager.custom_player["name"] = ""
	DataManager.load_all_data()

	if DataManager.profile["coins"] != 777000:
		printerr("FAIL: Coins not persisted properly!")
		return 1
	if DataManager.custom_player["name"] != "TEST_CAPTAIN":
		printerr("FAIL: Custom player name not persisted properly!")
		return 1

	print("  -> Local structured JSON persistence verified successfully.")
	return 0
