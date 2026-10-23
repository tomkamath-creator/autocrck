# CricStrike 3D 🏏

# cricket-

[![Build and Sign Android APK](https://github.com/tomkamath-creator/cricket-/actions/workflows/build_apk.yml/badge.svg)](https://github.com/tomkamath-creator/cricket-/actions/workflows/build_apk.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Target: Android 14+ / API 34+](https://img.shields.io/badge/Target-Android%2014%2B%20%7C%20API%2034%2B-brightgreen.svg)](https://developer.android.com/)
[![Engine: Godot 4.3 Mobile GL](https://img.shields.io/badge/Engine-Godot%204.3%20GL%20Compatibility-blue.svg)](https://godotengine.org/)

**CricStrike 3D** is a console-grade, 100% offline 3D mobile cricket game engineered as an exact, comprehensive 1:1 clone of the visual fidelity, gameplay depth, animation quality, broadcast cinematics, and game modes found in **Real Cricket 3D (RC24)** and **World Cricket Championship 3 (WCC3)**.

Designed strictly for offline personal use on physical Android mobile devices (Android 8 through Android 15+ / API 34+), with complete local JSON persistence, zero paywalls, zero ads, zero server dependencies, and battery-optimized 60 FPS performance.

---

## 🌟 Key Highlights & AAA Features

### 1. 3D Realistic Athletic Character Models (No Cartoon / Chibi)
- **Anatomy & Proportions**: Realistic adult male athlete proportions (1.85m height, 0.44m broad muscular shoulders, tapered athletic waist, articulated joints).
- **English Willow Bat**: Grain blade with 3D contoured spine, 38mm edges, 64mm spine swell, rubber chevron grip handle, protective toe guard, and sponsor brand decals.
- **Batting Pads**: Molded white/colored PU leather with 3 distinct horizontal knee rolls, 7 vertical cane ribs, outer wing protectors, and velcro straps.
- **Aerodynamic Helmet**: Modern fabric-sheen helmet shell, peak visor, ear flaps, and high-tensile stainless steel / titanium chrome specular face grille.
- **Batting Gloves & Shoes**: Segmented multi-flex finger rolls with reinforced thumb guards and spiked turf cricket shoes.
- **Team Kits**: High-resolution international team jerseys (Navy Blue, Gold/Canary, Dark Green, Maroon, Test Whites) with team crest and 3D player name/number decals (e.g. `R. SHARMA 45`, `V. KOHLI 18`).

### 2. 100% Upright Kinematics & Full Animation Suite
- **Kinematic Safeguards**: Hardcoded `rotation.x = 0.0` and `rotation.z = 0.0` in all physics updates. Look-at strictly targets flat coordinates `Vector3(target.x, global_position.y, target.z)`, completely eliminating belly-flop and pitch-tilt glitches.
- **Batting Animations**:
  - `stance`: Balanced sideways stance at popping crease with rhythmic bat tapping.
  - `front_foot_drive`: High elbow forward stride down the line (cover drive, straight drive, on drive).
  - `lofted_drive`: Explosive upward swing through the line finishing over long-on / long-off.
  - `pull_shot`: Back foot pivot with horizontal blade pulling through mid-wicket / square leg.
  - `cut_shot`: Back foot stride slicing down through backward point and third man.
  - `helicopter_shot`: Low wrist flick whipping over deep mid-wicket with full 360° bat twirl follow-through.
  - `defend_forward`: Soft hands defensive block deadening ball into turf.
  - `leave`: Torso recoil and high bat lift watching delivery pass to keeper.
  - `celebration_bat_raise`: Batsman raises bat vertically to pavilion on 50 or 100 runs.
- **Bowling & Fielding Animations**:
  - `runup`, `delivery_stride` (360° overarm windmill rotation & apex wrist flick), `celebration_wicket`.
  - `keeper_crouch`, `fielder_ready`, `fielder_sprint`, `fielder_slide_pickup`, `fielder_throw`.
  - `umpire_out`, `umpire_four`, `umpire_six`.

### 3. Batting Mechanics & Millisecond-Precision Timing Engine
- **Ergonomic Multi-Touch Controls**:
  - **Bottom-Left**: 360° Virtual Thumb Joystick across 8 sectors (*Cover, Point, Third Man, Fine Leg, Square Leg, Mid-Wicket, Long-On, Long-Off*).
  - **Bottom-Right**: Tactile buttons:
    - **🔥 LOFT**: Airborne power stroke designed to clear fielders for 4s and 6s.
    - **⚡ DRIVE**: Grounded placement stroke hugging turf to pierce gaps.
    - **🛡 DEFEND**: Block button for preserving wickets against lethal deliveries.
- **Timing Windows**:
  - **PERFECT** ($\le \pm 26\text{ms}$): Maximum exit speed ($130 - 155\text{km/h}$), sweetspot crack sound, ball flies through target gap.
  - **GOOD / EARLY / LATE** ($27 - 62\text{ms}$): $80 - 90\%$ exit speed.
  - **TOO EARLY / TOO LATE** ($63 - 115\text{ms}$): Sliced loft into air or thick outside/inside edge.
  - **MISSED / BEATEN** ($> 115\text{ms}$): Delivery beats bat cleanly or shatters stumps.

### 4. Master Bowling System & Pitch Aerodynamics
- **Bowling Styles**: Express Fast (145-155 km/h), Fast-Medium, Swing Specialist (Inswing, Outswing, Reverse Swing, Slower Yorker), Off-Spin (Doosra, Arm ball), Leg-Spin (Leg-break, Googly).
- **3-Step Precision Controls**: 3D Pitch Target Marker, Oscillating Swing/Turn Meter, and Pace/Release Power Meter.
- **Pitch Surface Physics**:
  - **Green Turf**: High bounce ($e = 0.84$), sharp seam movement.
  - **Dusty Pitch**: Moderate bounce ($e = 0.65$), high spin grip ($1.85\times$), sharp turn.
  - **Flat Deck**: True consistent bounce, high batting carry.
  - **Wet Pitch**: Low bounce ($e = 0.55$), skidding trajectory.
- **Continuous Auto-Bowling Loop**: In Batting Mode, AI automatically sets delivery line/length and runs up after a 1.0s cue; wicketkeeper catches deliveries passing stumps at $z > 13.8\text{m}$, concluding ball and teeing up the next delivery after 2.2s.

### 5. Broadcast Cinematics, 3-Second Replay & DRS
- **3-Second Multi-Angle Slow-Motion TV Replay**:
  - Automatically triggers on boundaries (4 or 6) and dismissals.
  - 3 dynamic TV angles: *Pitch Delivery Cam*, *Crease Impact Cam*, and *Reverse Sky Cam*.
  - Touch-responsive **"⏩ SKIP REPLAY"** button to resume live action instantly.
- **6 Broadcast Camera Angles**: `BEHIND_BATSMAN`, `BOWLER_POV`, `BROADCAST_SIDE`, `BALL_TRACKING`, `BATSMAN_HELMET_POV`, `UMPIRE_POV`.
- **DRS (Decision Review System)**:
  - **UltraEdge™ / Snickometer**: Real-time oscilloscope audio waveform showing flat baseline vs sharp acoustic spike on bat edge.
  - **Hawkeye™ 3D Ball Tracking**: Virtual trajectory predicting pitch line (*In Line / Outside Off / Outside Leg*), pad impact (*In Line / Outside Off*), and wickets (*Hitting / Missing / Umpire's Call*).

### 6. Procedural Audio & Dynamic Crowd Atmosphere
- 55+ situational commentary lines voiced by top commentary personalities (*Ravi Shastri, Harsha Bhogle, Ian Bishop, Michael Atherton*).
- Procedural physics SFX: Willow wood crack, ball bounce thud, wooden stump shatter, crowd stadium murmur, boundary cheers, milestone applause, and umpire whistle.

### 7. Complete Offline Game Modes
1. **Quick Match**: Pick any 2 international teams, overs (2, 5, 10, 20, 50), pitch type, difficulty, and jump into action.
2. **Super Over**: High-voltage single-over chase or defense scenario.
3. **World Tournament**: 8-team group stage (Group A & Group B), round-robin fixtures, live points table with Net Run Rate (NRR), semi-finals, and trophy presentation.
4. **Mega Auction**: Manage franchise purse (₹ 100 Crores), bid against realistic AI teams with bidding paddles, and build your championship roster.
5. **Locker Room & Customization Studio**: 360° player turntable pedestal to customize player name, jersey number, build physique, skin tone, bat willow, and gear decals with instant local persistence.

---

## 📱 Architecture & Technical Specifications

| Component | Specification |
| :--- | :--- |
| **Engine** | Godot Engine 4.3+ (GL Compatibility / Mobile Vulkan) |
| **Resolution** | 1280x720 base canvas, expandable landscape (16:9 / 20:9), auto-stretch |
| **Touch Emulation** | `pointing/emulate_touch_from_mouse=true`, multi-touch gesture support |
| **Persistence** | 100% Offline structured JSON in `user://` (`user://player_profile.json`, etc.) |
| **Physics Rate** | 60 ticks per second, 3D gravity 9.81 m/s² |
| **Target OS** | Android 14+ / API 34+ (Backward compatible to Android 8+ / API 26+) |

---

## 🛠 Project Directory Structure

```
cricstrike-3d/
├── .github/
│   └── workflows/
│       └── build_apk.yml            # Automated CI: Headless test runner, export, zipalign & apksigner
├── export_presets.cfg               # Android export configuration (package com.cricstrike.cricket3d)
├── project.godot                    # Engine config, GL Compatibility, 1280x720, Autoload singletons
├── icon.svg                         # App icon
├── README.md                        # Documentation
├── scenes/
│   ├── main_menu.tscn               # Main menu & mode selection
│   ├── match.tscn                   # 3D Stadium match scene with broadcast HUD & DRS
│   ├── tournament.tscn              # World tournament standings, fixtures & bracket
│   ├── auction.tscn                 # Mega auction room with paddle bidding
│   └── locker_room.tscn             # 360° turntable customization studio
└── scripts/
    ├── camera/
    │   └── broadcast_camera.gd      # 6 TV camera modes & 3-second slow-mo replay
    ├── core/
    │   ├── audio_manager.gd         # Procedural sound synthesis (bat crack, bounce, crowd)
    │   ├── commentary_manager.gd    # 55+ situational broadcast commentary lines
    │   ├── drs_manager.gd           # UltraEdge waveform & Hawkeye 3D tracking
    │   ├── game_manager.gd          # Match state machine, score, overs, strike rotation
    │   ├── persistence_manager.gd   # 100% offline structured JSON storage
    │   ├── tournament_manager.gd    # 8-team group stage, NRR, points table, knockouts
    │   ├── auction_manager.gd       # ₹100 Cr franchise bidding engine
    │   └── match_controller.gd      # 3D match scene orchestrator
    ├── physics/
    │   ├── cricket_ball.gd          # Ball flight aerodynamics, drag, Magnus swing, bounce
    │   └── pitch_physics.gd         # Restitution & friction for 4 pitch types
    ├── players/
    │   ├── cricket_player.gd        # Upright kinematic character controller
    │   ├── cricket_animator.gd      # Procedural skeletal animation suite (batting, bowling, fielding)
    │   ├── player_mesh_builder.gd   # Realistic athletic 3D meshes (willow bat, pads, chrome grille)
    │   ├── batsman_controller.gd    # Millisecond precision batting timing engine & 8 sectors
    │   ├── bowler_controller.gd     # Express fast, swing, spin & continuous auto-bowling loop
    │   └── fielder_controller.gd    # Pursuit AI, ground pickup, aerial catch & field presets
    ├── stadium/
    │   └── stadium_builder.gd       # Procedural 3D stadium, pitch strip, wickets, floodlights
    ├── tests/
    │   └── headless_test_runner.gd  # Automated test suite for physics, timing, DRS, NRR
    └── ui/
        ├── broadcast_hud.gd         # TV score ribbon, commentary banner, over graphics
        ├── virtual_joystick.gd      # 360° ergonomic virtual thumb joystick
        ├── touch_action_button.gd   # Tactile touch buttons (LOFT, DRIVE, DEFEND)
        ├── drs_overlay.gd           # UltraEdge oscilloscope & Hawkeye summary
        ├── main_menu_controller.gd  # Main menu UI logic
        ├── tournament_controller.gd # Tournament UI logic
        ├── auction_controller.gd    # Auction UI logic
        └── locker_room_controller.gd# 360° turntable studio logic
```

---

## 🧪 Running Automated Tests

Execute the headless test suite locally with Godot 4.3:

```bash
godot --headless -s scripts/tests/headless_test_runner.gd
```

The test runner validates:
1. `test_pitch_physics_restitution`: Green Turf ($e > 0.82$), Dusty ($e \approx 0.65$), Flat Deck, and Wet pitches.
2. `test_batting_timing_windows`: Millisecond window accuracy for PERFECT, GOOD, TOO EARLY/LATE, and BEATEN.
3. `test_drs_hawkeye_lbw`: Pitching in-line, impact in-line, wickets hitting vs outside leg / missing.
4. `test_tournament_table_and_nrr`: Net Run Rate calculations and points sorting.
5. `test_auction_bidding_and_purse`: Bidding increment, franchise purse deductions, and squad additions.

---

## 🤖 GitHub Actions CI/CD Pipeline

The included `.github/workflows/build_apk.yml` workflow:
1. Runs on every commit and pull request to `main`.
2. Sets up Android SDK 34 and Java 17.
3. Downloads Godot 4.3 Headless and export templates.
4. Executes the automated test suite.
5. Compiles Android Debug APK (`cricket.apk`).
6. Runs `zipalign` and signs with `apksigner` supporting **v1, v2, and v3 signature schemes**.
7. Automatically attaches the ready-to-install `cricket.apk` to GitHub Releases!

---

## 🚀 Git Setup & Quick Commands

To push this repository to GitHub:

```bash
git remote add origin https://github.com/tomkamath-creator/cricket-.git
git branch -M main
git add .
git commit -m "feat: complete AAA CricStrike 3D offline mobile cricket game"
git push -u origin main
```

---

## 📄 License
This project is released under the **MIT License**. Free for offline personal play and modification.
