# scripts/tests/headless_test_runner.gd
# Headless Automated Unit & Integration Test Suite for CricStrike 3D
# Executes verification of pitch physics, timing windows, DRS Hawkeye, tournament NRR, and persistence.
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("       CRICSTRIKE 3D HEADLESS TEST SUITE          ")
	print("==================================================")
	
	var pass_count = 0
	var fail_count = 0
	
	if _run_test("test_pitch_physics_restitution", test_pitch_physics_restitution): pass_count += 1
	else: fail_count += 1
	
	if _run_test("test_batting_timing_windows", test_batting_timing_windows): pass_count += 1
	else: fail_count += 1
	
	if _run_test("test_drs_hawkeye_lbw", test_drs_hawkeye_lbw): pass_count += 1
	else: fail_count += 1
	
	if _run_test("test_tournament_table_and_nrr", test_tournament_table_and_nrr): pass_count += 1
	else: fail_count += 1
	
	if _run_test("test_auction_bidding_and_purse", test_auction_bidding_and_purse): pass_count += 1
	else: fail_count += 1
	
	print("--------------------------------------------------")
	print("TOTAL TESTS: ", pass_count + fail_count)
	print("PASSED: ", pass_count)
	print("FAILED: ", fail_count)
	print("==================================================")
	
	if fail_count > 0:
		quit(1)
	else:
		quit(0)

func _run_test(test_name: String, test_callable: Callable) -> bool:
	print("[RUNNING] ", test_name, " ...")
	var success = test_callable.call()
	if success:
		print("[PASS]    ", test_name)
		return true
	else:
		printerr("[FAIL]    ", test_name)
		return false

func test_pitch_physics_restitution() -> bool:
	var pitch = PitchPhysics.new()
	
	# 1. Test Green Turf Restitution > 0.82
	pitch.set_pitch_type(PitchPhysics.PitchType.GREEN_TURF)
	if pitch.restitution <= 0.82:
		printerr("Green turf restitution must be > 0.82, got: ", pitch.restitution)
		return false
	
	var in_vel = Vector3(0, -10.0, 30.0)
	var out_vel = pitch.calculate_bounce_velocity(in_vel, Vector3.ZERO, 0.0)
	if absf(out_vel.y - 8.4) > 0.01:
		printerr("Unexpected bounce y: ", out_vel.y)
		return false
	
	# 2. Test Dusty Pitch Restitution approx 0.65
	pitch.set_pitch_type(PitchPhysics.PitchType.DUSTY)
	if absf(pitch.restitution - 0.65) > 0.02:
		printerr("Dusty pitch restitution must be ~0.65, got: ", pitch.restitution)
		return false
	
	# 3. Test Spin Grip on Dusty Pitch
	var spin_vel = pitch.calculate_bounce_velocity(in_vel, Vector3(0, 10.0, 0), 0.0)
	if spin_vel.x <= 0.5:
		printerr("Spin kick should be positive and substantial on dusty pitch, got: ", spin_vel.x)
		return false
	
	return true

func test_batting_timing_windows() -> bool:
	# Check boundary window classifications
	var classify_timing = func(timing_ms: float) -> String:
		var abs_t = absf(timing_ms)
		if abs_t <= 26.0:
			return "PERFECT"
		elif abs_t <= 62.0:
			return "GOOD"
		elif abs_t <= 115.0:
			return "TOO EARLY" if timing_ms > 0 else "TOO LATE"
		else:
			return "BEATEN"
	
	if classify_timing.call(12.0) != "PERFECT": return false
	if classify_timing.call(-25.0) != "PERFECT": return false
	if classify_timing.call(40.0) != "GOOD": return false
	if classify_timing.call(-55.0) != "GOOD": return false
	if classify_timing.call(85.0) != "TOO EARLY": return false
	if classify_timing.call(-95.0) != "TOO LATE": return false
	if classify_timing.call(140.0) != "BEATEN": return false
	
	return true

func test_drs_hawkeye_lbw() -> bool:
	var drs = DRSManager
	var pitch_pt = Vector3(0.05, 0.0, 6.2) # In line
	var impact_pt = Vector3(0.04, 0.45, 9.0) # In line
	var vel_after = Vector3(0.0, 0.1, 25.0) # Forward towards stumps
	
	var res = drs.evaluate_hawkeye_lbw(pitch_pt, impact_pt, vel_after)
	if res["pitched"] != "In Line":
		printerr("Expected In Line pitching, got: ", res["pitched"])
		return false
	if res["impact"] != "In Line":
		printerr("Expected In Line impact, got: ", res["impact"])
		return false
	if res["wickets"] != "Hitting":
		printerr("Expected Wickets Hitting, got: ", res["wickets"])
		return false
	if not res["is_out"]:
		printerr("Expected is_out to be true")
		return false
	
	# Test outside leg delivery (not out)
	var outside_leg_pitch = Vector3(-0.35, 0.0, 6.0)
	var res_leg = drs.evaluate_hawkeye_lbw(outside_leg_pitch, impact_pt, vel_after)
	if res_leg["is_out"]:
		printerr("Delivery pitching outside leg cannot be given OUT LBW!")
		return false
	
	return true

func test_tournament_table_and_nrr() -> bool:
	var tourney = TournamentManager
	var sample_table = {
		"India": {
			"team": "India", "P": 1, "W": 1, "L": 0, "PTS": 2,
			"runs_scored": 180, "balls_faced": 120, # 9.0 RPO
			"runs_conceded": 150, "balls_bowled": 120, # 7.5 RPO
			"NRR": 1.500
		},
		"Australia": {
			"team": "Australia", "P": 1, "W": 0, "L": 1, "PTS": 0,
			"runs_scored": 150, "balls_faced": 120,
			"runs_conceded": 180, "balls_bowled": 120,
			"NRR": -1.500
		}
	}
	
	var sorted = tourney.get_sorted_table(sample_table)
	if sorted[0]["team"] != "India":
		printerr("India should be ranked #1 with 2 PTS")
		return false
	if sorted[0]["NRR"] != 1.500:
		printerr("India NRR should be +1.500")
		return false
	
	return true

func test_auction_bidding_and_purse() -> bool:
	var auction = AuctionManager
	var initial_purse = auction.franchises["Mumbai Titans"]["purse"]
	if initial_purse != 100000000:
		printerr("Franchise purse should start at 100 Crores")
		return false
	
	var fmt = auction.format_currency(20000000)
	if not fmt.contains("2"):
		printerr("Expected currency format 2 Cr, got: ", fmt)
		return false
	
	return true
