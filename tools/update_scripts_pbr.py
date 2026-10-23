import re

# 1. Update player_character.gd
with open("scripts/entities/player_character.gd", "r", encoding="utf-8") as f:
    pc_content = f.read()

old_init_mat = """func _init_materials() -> void:
\tskin_mat = StandardMaterial3D.new()
\tskin_mat.albedo_color = Color(0.78, 0.58, 0.44) # Athletic sun-kissed skin
\tskin_mat.roughness = 0.65

\tjersey_mat = StandardMaterial3D.new()
\tjersey_mat.albedo_color = Color(0.05, 0.25, 0.65)
\tjersey_mat.roughness = 0.45

\tpants_mat = StandardMaterial3D.new()
\tpants_mat.albedo_color = Color(0.05, 0.25, 0.65)
\tpants_mat.roughness = 0.5

\tbat_mat = StandardMaterial3D.new()
\tbat_mat.albedo_color = Color(0.92, 0.82, 0.66) # English willow grain
\tbat_mat.roughness = 0.4

\tpads_mat = StandardMaterial3D.new()
\tpads_mat.albedo_color = Color(0.95, 0.95, 0.96) # Molded white PU leather
\tpads_mat.roughness = 0.35

\thelmet_mat = StandardMaterial3D.new()
\thelmet_mat.albedo_color = Color(0.04, 0.18, 0.45)
\thelmet_mat.roughness = 0.25

\tchrome_mat = StandardMaterial3D.new()
\tchrome_mat.albedo_color = Color(0.85, 0.85, 0.88)
\tchrome_mat.metallic = 0.95
\tchrome_mat.roughness = 0.1"""

new_init_mat = """func _init_materials() -> void:
\tskin_mat = StandardMaterial3D.new()
\tskin_mat.albedo_color = Color(1.0, 1.0, 1.0)
\tif ResourceLoader.exists("res://assets/textures/pbr/face_2k_albedo.png"):
\t\tskin_mat.albedo_texture = load("res://assets/textures/pbr/face_2k_albedo.png")
\t\tskin_mat.normal_enabled = true
\t\tskin_mat.normal_texture = load("res://assets/textures/pbr/face_2k_normal.png")
\t\tskin_mat.roughness_texture = load("res://assets/textures/pbr/face_2k_roughness.png")
\telse:
\t\tskin_mat.albedo_color = Color(0.78, 0.58, 0.44)
\t\tskin_mat.roughness = 0.65

\tjersey_mat = StandardMaterial3D.new()
\tjersey_mat.albedo_color = Color(1.0, 1.0, 1.0)
\tif ResourceLoader.exists("res://assets/textures/pbr/jersey_2k_albedo.png"):
\t\tjersey_mat.albedo_texture = load("res://assets/textures/pbr/jersey_2k_albedo.png")
\t\tjersey_mat.normal_enabled = true
\t\tjersey_mat.normal_texture = load("res://assets/textures/pbr/jersey_2k_normal.png")
\t\tjersey_mat.roughness_texture = load("res://assets/textures/pbr/jersey_2k_roughness.png")
\t\tjersey_mat.ao_enabled = true
\t\tjersey_mat.ao_texture = load("res://assets/textures/pbr/jersey_2k_ao.png")
\telse:
\t\tjersey_mat.albedo_color = Color(0.05, 0.25, 0.65)
\t\tjersey_mat.roughness = 0.45

\tpants_mat = StandardMaterial3D.new()
\tpants_mat.albedo_color = Color(0.05, 0.25, 0.65)
\tif ResourceLoader.exists("res://assets/textures/pbr/jersey_2k_normal.png"):
\t\tpants_mat.normal_enabled = true
\t\tpants_mat.normal_texture = load("res://assets/textures/pbr/jersey_2k_normal.png")
\t\tpants_mat.roughness = 0.55

\tbat_mat = StandardMaterial3D.new()
\tbat_mat.albedo_color = Color(1.0, 1.0, 1.0)
\tif ResourceLoader.exists("res://assets/textures/pbr/bat_2k_albedo.png"):
\t\tbat_mat.albedo_texture = load("res://assets/textures/pbr/bat_2k_albedo.png")
\t\tbat_mat.normal_enabled = true
\t\tbat_mat.normal_texture = load("res://assets/textures/pbr/bat_2k_normal.png")
\t\tbat_mat.roughness_texture = load("res://assets/textures/pbr/bat_2k_roughness.png")
\t\tbat_mat.metallic_texture = load("res://assets/textures/pbr/bat_2k_metallic.png")
\t\tbat_mat.ao_enabled = true
\t\tbat_mat.ao_texture = load("res://assets/textures/pbr/bat_2k_ao.png")
\telse:
\t\tbat_mat.albedo_color = Color(0.92, 0.82, 0.66)
\t\tbat_mat.roughness = 0.4

\tpads_mat = StandardMaterial3D.new()
\tpads_mat.albedo_color = Color(1.0, 1.0, 1.0)
\tif ResourceLoader.exists("res://assets/textures/pbr/pads_2k_albedo.png"):
\t\tpads_mat.albedo_texture = load("res://assets/textures/pbr/pads_2k_albedo.png")
\t\tpads_mat.normal_enabled = true
\t\tpads_mat.normal_texture = load("res://assets/textures/pbr/pads_2k_normal.png")
\t\tpads_mat.roughness_texture = load("res://assets/textures/pbr/pads_2k_roughness.png")
\t\tpads_mat.ao_enabled = true
\t\tpads_mat.ao_texture = load("res://assets/textures/pbr/pads_2k_ao.png")
\telse:
\t\tpads_mat.albedo_color = Color(0.95, 0.95, 0.96)
\t\tpads_mat.roughness = 0.35

\thelmet_mat = StandardMaterial3D.new()
\thelmet_mat.albedo_color = Color(1.0, 1.0, 1.0)
\tif ResourceLoader.exists("res://assets/textures/pbr/helmet_2k_albedo.png"):
\t\thelmet_mat.albedo_texture = load("res://assets/textures/pbr/helmet_2k_albedo.png")
\t\thelmet_mat.normal_enabled = true
\t\thelmet_mat.normal_texture = load("res://assets/textures/pbr/helmet_2k_normal.png")
\t\thelmet_mat.roughness_texture = load("res://assets/textures/pbr/helmet_2k_roughness.png")
\t\thelmet_mat.metallic_texture = load("res://assets/textures/pbr/helmet_2k_metallic.png")
\telse:
\t\thelmet_mat.albedo_color = Color(0.04, 0.18, 0.45)
\t\thelmet_mat.roughness = 0.25

\tchrome_mat = StandardMaterial3D.new()
\tchrome_mat.albedo_color = Color(0.88, 0.88, 0.92)
\tchrome_mat.metallic = 0.98
\tchrome_mat.roughness = 0.08"""

# Normalize CRLF / LF
pc_content_norm = pc_content.replace("\r\n", "\n")
old_init_mat_norm = old_init_mat.replace("\r\n", "\n")
if old_init_mat_norm in pc_content_norm:
    pc_content_norm = pc_content_norm.replace(old_init_mat_norm, new_init_mat)
    with open("scripts/entities/player_character.gd", "w", encoding="utf-8") as f:
        f.write(pc_content_norm)
    print("Updated player_character.gd successfully")
else:
    print("Warning: old_init_mat not found in player_character.gd")

# 2. Update ball_physics.gd to add visual 2K ball mesh
with open("scripts/physics/ball_physics.gd", "r", encoding="utf-8") as f:
    bp_content = f.read().replace("\r\n", "\n")

target_bp = """func _ready() -> void:
\tload_pitch_properties(GameManager.selected_pitch)"""

replacement_bp = """var ball_mesh: MeshInstance3D
var ball_mat: StandardMaterial3D

func _ready() -> void:
\tload_pitch_properties(GameManager.selected_pitch)
\t_build_ball_mesh()

func _build_ball_mesh() -> void:
\tball_mesh = MeshInstance3D.new()
\tvar sph := SphereMesh.new()
\tsph.radius = ball_radius
\tsph.height = ball_radius * 2.0

\tball_mat = StandardMaterial3D.new()
\tball_mat.albedo_color = Color(1.0, 1.0, 1.0)
\tif ResourceLoader.exists("res://assets/textures/pbr/ball_2k_albedo.png"):
\t\tball_mat.albedo_texture = load("res://assets/textures/pbr/ball_2k_albedo.png")
\t\tball_mat.normal_enabled = true
\t\tball_mat.normal_texture = load("res://assets/textures/pbr/ball_2k_normal.png")
\t\tball_mat.roughness_texture = load("res://assets/textures/pbr/ball_2k_roughness.png")
\t\tball_mat.ao_enabled = true
\t\tball_mat.ao_texture = load("res://assets/textures/pbr/ball_2k_ao.png")
\telse:
\t\tball_mat.albedo_color = Color(0.76, 0.08, 0.12)
\t\tball_mat.roughness = 0.3

\tsph.material = ball_mat
\tball_mesh.mesh = sph
\tadd_child(ball_mesh)"""

if target_bp in bp_content:
    bp_content = bp_content.replace(target_bp, replacement_bp)
    with open("scripts/physics/ball_physics.gd", "w", encoding="utf-8") as f:
        f.write(bp_content)
    print("Updated ball_physics.gd successfully")
else:
    print("Warning: target_bp not found in ball_physics.gd")
