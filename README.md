# CricStrike 3D 🏏

**CricStrike 3D** is a production-quality, 100% offline 3D mobile cricket game built on Godot Engine 4.3 (Mobile GL Compatibility / Vulkan renderer) for Android (Android 14+ / API 34+), engineered with the visual fidelity, gameplay depth, broadcast cinematics, and game modes found in console and top-tier mobile cricket titles (*Real Cricket 24* and *World Cricket Championship 3*).

---

## 🌟 Key Features

### 1. 100% Offline & Mobile Optimized
- **Zero Server Dependencies & Zero Paywalls**: Complete local persistence via structured JSON in `user://` storage.
- **Battery-Optimized 60 FPS**: Engineered with Godot 4.3 Mobile GL Compatibility renderer for silky-smooth performance across entry-level, mid-range, and flagship devices.
- **Ergonomic Touch Controls**:
  - Full touch emulation (`pointing/emulate_touch_from_mouse` and `pointing/emulate_mouse_from_touch`).
  - 360° virtual thumb joystick for 8-sector shot placement.
  - Large tactile hitboxes (64dp minimum) for **🔥 LOFT**, **⚡ DRIVE**, and **🛡 DEFEND**.

### 2. Realistic 3D Player Models & Gear
- **Athletic Anatomical Proportions**: Adult male athletes (1.84m height, 0.44m shoulder width, tapered waist, articulated joints).
- **Console-Grade Equipment**:
  - English willow bat with 3D contoured spine, 38mm edges, 64mm spine swell, rubber chevron grip, and brand decals.
  - Polyurethane batting leg guards with 3 horizontal knee rolls, 7 vertical cane ribs, and velcro straps.
  - Aerodynamic cricket helmets with chrome stainless steel face grilles.
  - Team jerseys featuring carbon-hex weaves, collar trims, team badges, and 3D player name/number lettering.
- **Role-Based Outfits**: Fully differentiated visual gear for Batsmen, Bowlers, Wicketkeepers, Fielders, and Umpires.

### 3. Kinematic Safeguards & Cricket Animation Suite
- **100% Upright Kinematics**:
  - Hardcoded `rotation.x = 0.0` and `rotation.z = 0.0` during all physics updates.
  - Planar look-at logic targeting `Vector3(target.x, global_position.y, target.z)` to eliminate pitch-tilt/belly-flop glitches.
- **Comprehensive Animations**:
  - **Batting**: Stance bat-tap, Front Foot Drive, Lofted Drive, Pull Shot, Cut Shot, Helicopter Shot, Defend Forward, Leave, Bat Raise Celebration.
  - **Bowling**: Run-up, Delivery Stride (360° windmill arm rotation, wrist flick release at apex, follow-through), Wicket Celebration.
  - **Fielding & Keeping**: Keeper Crouch, Fielder Ready, Sprint, Slide Pickup, Rocket Throw, Umpire Signals (Out, Four, Six).

### 4. Precision Batting & Timing Engine
- **Millisecond Precision Windows**:
  - `PERFECT` ($\le \pm 26\text{ms}$): 130–155 km/h exit speed with sweetspot crack audio.
  - `GOOD / EARLY / LATE` ($27–62\text{ms}$): 80–90% exit speed, gap placement.
  - `TOO EARLY / TOO LATE` ($63–115\text{ms}$): Sliced loft, edge risk.
  - `MISSED / BEATEN` ($> 115\text{ms}$): Beaten by pace/spin.

### 5. Master Bowling & Pitch Aerodynamics
- **Bowling Styles**: Express Fast (145–155 km/h), Fast-Medium (130–142 km/h), Swing (In/Out/Reverse, Slower Yorker), Spin (Off-break, Arm ball, Doosra, Leg-break, Googly, Top-spin, Flipper).
- **3-Step Precision Controls**:
  1. 3D Pitch Target Marker (Yorker, Full, Good Length, Short).
  2. Oscillating Swing/Turn Meter.
  3. Oscillating Pace & Release Meter (Sweetspot vs No-Ball penalty).
- **4 Pitch Surfaces**: Green Turf, Dusty Pitch, Flat Deck, and Wet Pitch with authentic coefficient of restitution and spin grip.
- **Continuous Auto-Bowling Loop**: Automated AI delivery sequence with 1-second ready cues and 2.2-second post-delivery reset.

### 6. Dynamic Fielding & Wicketkeeping
- **Preset Field Layouts**: `BALANCED`, `ATTACKING`, `DEFENSIVE`.
- **Pursuit AI**: Real-time trajectory prediction, ground pickups within 0.85m, aerial catches within 1.3m, and rocket throws to stumps.

### 7. Broadcast Cinematics, Replay System & DRS
- **3-Second Multi-Angle TV Replay**: Automatic replay on boundaries and wickets across 3 camera angles (Pitch Delivery, Crease Impact, Reverse Sky) with "⏩ SKIP REPLAY".
- **6 Broadcast Camera Modes**: Behind Batsman, Bowler POV, Broadcast Side, Ball Tracking, Batsman Helmet POV, Umpire POV.
- **DRS & Hawkeye**:
  - UltraEdge / Snickometer audio waveform visualizer.
  - Hawkeye 3D Ball Tracking predicting pitch impact, ball deviation, and wickets hitting.

### 8. Procedural Commentary & Stadium Audio
- **50+ Commentary Lines**: Real-time situational commentary ticker with audio equalizer.
- **Procedural Physical SFX**: Bat willow crack, ball bounce thud, wooden stump rattle, turf sliding, and reactive crowd roars/applause synthesized natively without external copyrighted audio files.

### 9. 5 Complete Offline Game Modes
1. **Quick Match**: Pick any 2 teams, overs (2, 5, 10, 20, 50), pitch type, and AI difficulty (Easy, Medium, Hard, Legend).
2. **Super Over**: High-stakes 1-over chase or defense scenario.
3. **World Tournament**: 8 or 16-team tournament with group stages, live points table, Net Run Rate (NRR), semi-finals, and trophy presentation.
4. **Mega Auction**: Offline franchise auction managing purse budget and bidding against intelligent AI teams.
5. **Locker Room & Customization Studio**: 360° turntable pedestal for customizing player name, number, skin tone, facial hair, build, bat willow, stickers, and jersey palette.

### 10. Clean Mobile Broadcast HUD
- Full-width broadcast score bar (team badges, score, overs, CRR, RRR, active batsman/bowler stats, over ball markers).
- Top center commentary ribbon.
- Top right `🎥 CAM` and `⏸ PAUSE` touch controls.
- Over transition bowler cards & 360° Wagon Wheel pop-ups.

---

## 🏗 Building & CI/CD Pipeline

The project includes a fully automated GitHub Actions CI workflow (`.github/workflows/android_build.yml`):
- Runs headless Godot unit test suite verifying physics, batting timing, umpire rules, and tournament brackets.
- Compiles Android Debug APK (`cricket.apk`).
- Optimizes with `zipalign` and signs with `apksigner` (v1, v2, v3 signature schemes).
- Publishes direct APK download on GitHub Releases.

---

## 📄 License
Offline personal use project. Built with Godot Engine 4.3.
