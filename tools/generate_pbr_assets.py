import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = "assets/textures/pbr"
os.makedirs(OUT_DIR, exist_ok=True)
SIZE = 2048

def height_to_normal(height, strength=3.0):
    """Converts a 2D float heightmap [0, 1] into a tangent-space normal map."""
    gy, gx = np.gradient(height * strength)
    normal_x = -gx
    normal_y = -gy
    normal_z = np.ones_like(height)
    
    norm = np.sqrt(normal_x**2 + normal_y**2 + normal_z**2)
    normal_x /= norm
    normal_y /= norm
    normal_z /= norm
    
    r = ((normal_x * 0.5 + 0.5) * 255).astype(np.uint8)
    g = ((normal_y * 0.5 + 0.5) * 255).astype(np.uint8)
    b = ((normal_z * 0.5 + 0.5) * 255).astype(np.uint8)
    return np.stack([r, g, b], axis=-1)

print("--- Generating 2K Turf & Pitch PBR Maps ---")
# 1. Turf (Lawn grass blades & mowing stripes)
y_idx, x_idx = np.indices((SIZE, SIZE))
stripes = (np.sin(y_idx * (20 * np.pi / SIZE)) * 0.15 + 0.5)
noise_fine = np.random.uniform(0.85, 1.15, (SIZE, SIZE))
grass_base = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
# Rich stadium outfield green: Color(0.18, 0.48, 0.16)
grass_base[..., 0] = 46 * stripes * noise_fine
grass_base[..., 1] = 122 * stripes * noise_fine
grass_base[..., 2] = 40 * stripes * noise_fine
turf_albedo = np.clip(grass_base, 0, 255).astype(np.uint8)
Image.fromarray(turf_albedo).save(os.path.join(OUT_DIR, "turf_2k_albedo.png"))

turf_height = (np.random.normal(0.5, 0.18, (SIZE, SIZE)) + (stripes * 0.2))
turf_height = np.clip(turf_height, 0.0, 1.0)
turf_normal = height_to_normal(turf_height, strength=4.5)
Image.fromarray(turf_normal).save(os.path.join(OUT_DIR, "turf_2k_normal.png"))

turf_rough = (np.clip(turf_height * 0.4 + 0.6, 0, 1) * 255).astype(np.uint8)
Image.fromarray(turf_rough).save(os.path.join(OUT_DIR, "turf_2k_roughness.png"))

turf_ao = (np.clip(1.0 - (1.0 - turf_height) * 0.5, 0, 1) * 255).astype(np.uint8)
Image.fromarray(turf_ao).save(os.path.join(OUT_DIR, "turf_2k_ao.png"))

# 2. Pitch Surface (Compacted clay, rolling lines, wear & scuff zones)
pitch_base = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
# Rolled clay base Color(0.72, 0.60, 0.42)
pitch_grain = np.sin(x_idx * (120 * np.pi / SIZE)) * 0.04 + 1.0
wear_pattern = np.exp(-((x_idx - SIZE//2)**2) / (2 * (SIZE * 0.28)**2))
pitch_noise = np.random.uniform(0.92, 1.08, (SIZE, SIZE))
pitch_base[..., 0] = (184 * wear_pattern + 150 * (1 - wear_pattern)) * pitch_noise * pitch_grain
pitch_base[..., 1] = (153 * wear_pattern + 120 * (1 - wear_pattern)) * pitch_noise * pitch_grain
pitch_base[..., 2] = (107 * wear_pattern + 80 * (1 - wear_pattern)) * pitch_noise * pitch_grain
# Add white popping crease chalk band at the top
crease_mask = (y_idx >= SIZE - 120) & (y_idx <= SIZE - 40)
pitch_base[crease_mask, :] = [245, 245, 250]
pitch_albedo = np.clip(pitch_base, 0, 255).astype(np.uint8)
Image.fromarray(pitch_albedo).save(os.path.join(OUT_DIR, "pitch_2k_albedo.png"))

pitch_height = np.random.normal(0.5, 0.12, (SIZE, SIZE))
pitch_height[crease_mask] += 0.15
pitch_height = np.clip(pitch_height, 0, 1)
pitch_normal = height_to_normal(pitch_height, strength=3.0)
Image.fromarray(pitch_normal).save(os.path.join(OUT_DIR, "pitch_2k_normal.png"))

pitch_rough = (np.clip(0.55 + pitch_height * 0.35, 0, 1) * 255).astype(np.uint8)
Image.fromarray(pitch_rough).save(os.path.join(OUT_DIR, "pitch_2k_roughness.png"))

pitch_ao = (np.clip(pitch_height * 0.3 + 0.7, 0, 1) * 255).astype(np.uint8)
Image.fromarray(pitch_ao).save(os.path.join(OUT_DIR, "pitch_2k_ao.png"))

print("--- Generating 2K English Willow Cricket Bat PBR Maps ---")
# 3. Cricket Bat (Vertical willow grain, contoured spine swell, rubber chevron grip handle, brand decals)
bat_albedo_img = Image.new("RGB", (SIZE, SIZE), (235, 215, 185))
draw = ImageDraw.Draw(bat_albedo_img)

# Wood grain lines
bat_arr = np.array(bat_albedo_img, dtype=np.float32)
wood_lines = np.sin(x_idx * (300 * np.pi / SIZE)) * 12.0 + np.sin(x_idx * (40 * np.pi / SIZE)) * 8.0
bat_arr[..., 0] += wood_lines
bat_arr[..., 1] += wood_lines * 0.8
bat_arr[..., 2] += wood_lines * 0.6

# Top quarter is rubber chevron grip handle (Black with rubber texture)
handle_mask = y_idx < (SIZE // 4)
bat_arr[handle_mask, :] = [30, 32, 35]
# Handle chevron grooves
chevron = (np.sin((x_idx + y_idx) * (80 * np.pi / SIZE)) > 0)
bat_arr[handle_mask & chevron, :] = [45, 48, 52]

# Bottom 5% is protective toe guard rubber (Dark Navy/Black)
toe_mask = y_idx > (SIZE - 120)
bat_arr[toe_mask, :] = [25, 28, 38]

bat_albedo_img = Image.fromarray(np.clip(bat_arr, 0, 255).astype(np.uint8))
draw = ImageDraw.Draw(bat_albedo_img)
# 3D Brand Sponsor Decals: "CRICSTRIKE TITAN PRO"
draw.rectangle([SIZE//2 - 320, SIZE//3, SIZE//2 + 320, SIZE//3 + 450], fill=(220, 25, 35), outline=(255, 215, 0), width=12)
draw.rectangle([SIZE//2 - 280, SIZE//3 + 40, SIZE//2 + 280, SIZE//3 + 410], fill=(15, 25, 45))
# Brand Decal text shapes
draw.ellipse([SIZE//2 - 160, SIZE//3 + 80, SIZE//2 + 160, SIZE//3 + 240], fill=(255, 215, 0))
draw.rectangle([SIZE//2 - 220, SIZE//3 + 280, SIZE//2 + 220, SIZE//3 + 370], fill=(240, 240, 245))

bat_albedo_img.save(os.path.join(OUT_DIR, "bat_2k_albedo.png"))

# Bat Normal Map (Handle grip chevron relief, 3D embossed sticker borders)
bat_height = np.zeros((SIZE, SIZE), dtype=np.float32) + 0.5
bat_height[handle_mask] = 0.4 + (chevron[handle_mask].astype(np.float32) * 0.25)
bat_height[toe_mask] = 0.55
# Spine swell in the middle
spine_profile = np.exp(-((x_idx - SIZE//2)**2) / (2 * (SIZE * 0.18)**2)) * 0.35
bat_height[~handle_mask & ~toe_mask] += spine_profile[~handle_mask & ~toe_mask]
bat_normal = height_to_normal(bat_height, strength=5.0)
Image.fromarray(bat_normal).save(os.path.join(OUT_DIR, "bat_2k_normal.png"))

# Bat Roughness & Metallic
bat_rough = np.full((SIZE, SIZE), 120, dtype=np.uint8) # Lacquered wood
bat_rough[handle_mask] = 230 # Matte rubber grip
bat_rough[toe_mask] = 200 # Matte toe guard
Image.fromarray(bat_rough).save(os.path.join(OUT_DIR, "bat_2k_roughness.png"))

bat_metal = np.zeros((SIZE, SIZE), dtype=np.uint8)
# Hologram gold decal on sticker
bat_metal[SIZE//3 + 80 : SIZE//3 + 240, SIZE//2 - 160 : SIZE//2 + 160] = 220
Image.fromarray(bat_metal).save(os.path.join(OUT_DIR, "bat_2k_metallic.png"))

bat_ao = (np.clip(1.0 - (1.0 - bat_height) * 0.35, 0, 1) * 255).astype(np.uint8)
Image.fromarray(bat_ao).save(os.path.join(OUT_DIR, "bat_2k_ao.png"))

print("--- Generating 2K Regulation Cricket Ball PBR Maps ---")
# 4. Cricket Ball (Cherry red leather quarters, raised white double seam stitching, gold foil logo)
ball_base = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
# Deep cherry red Color(0.76, 0.08, 0.12)
leather_noise = np.random.normal(1.0, 0.05, (SIZE, SIZE))
ball_base[..., 0] = 194 * leather_noise
ball_base[..., 1] = 22 * leather_noise
ball_base[..., 2] = 32 * leather_noise

# Central Seam (White double-stitched thread with 78 stitches)
seam_mask = np.abs(x_idx - SIZE // 2) <= 24
stitch_freq = np.sin(y_idx * (156 * np.pi / SIZE)) > 0.1
ball_base[seam_mask & stitch_freq, :] = [250, 250, 245]
ball_base[seam_mask & ~stitch_freq, :] = [90, 10, 15]

# Quarter Seam indentations
quarter_mask = np.abs(y_idx - SIZE // 2) <= 12
ball_base[quarter_mask, :] = [90, 10, 15]

ball_img = Image.fromarray(np.clip(ball_base, 0, 255).astype(np.uint8))
draw = ImageDraw.Draw(ball_img)
# Gold brand crest
draw.ellipse([SIZE//4 - 80, SIZE//2 - 80, SIZE//4 + 80, SIZE//2 + 80], outline=(235, 195, 45), width=10)
draw.text((SIZE//4 - 55, SIZE//2 - 18), "CRIC", fill=(235, 195, 45))
ball_img.save(os.path.join(OUT_DIR, "ball_2k_albedo.png"))

ball_height = np.random.normal(0.5, 0.04, (SIZE, SIZE))
ball_height[seam_mask & stitch_freq] = 0.95 # Prominent raised seam
ball_height[seam_mask & ~stitch_freq] = 0.35 # Stitch groove
ball_height[quarter_mask] = 0.40 # Quarter depression
ball_normal = height_to_normal(ball_height, strength=6.0)
Image.fromarray(ball_normal).save(os.path.join(OUT_DIR, "ball_2k_normal.png"))

# Roughness: Shiny polished side (left) vs Scuffed side (right) for swing physics!
ball_rough = np.zeros((SIZE, SIZE), dtype=np.uint8)
ball_rough[:, :SIZE//2] = 45  # High-shine polished lacquer
ball_rough[:, SIZE//2:] = 165 # Abrasive rough scuffed leather
ball_rough[seam_mask] = 220   # Cotton thread seam
Image.fromarray(ball_rough).save(os.path.join(OUT_DIR, "ball_2k_roughness.png"))

ball_ao = (np.clip(ball_height * 0.4 + 0.6, 0, 1) * 255).astype(np.uint8)
Image.fromarray(ball_ao).save(os.path.join(OUT_DIR, "ball_2k_ao.png"))

print("--- Generating 2K Batting Pads & Gloves PBR Maps ---")
# 5. Batting Pads (7 Vertical cane ribs, 3 horizontal knee rolls, velcro straps)
pad_base = np.zeros((SIZE, SIZE, 3), dtype=np.float32) + 245 # Molded white PU
pad_height = np.zeros((SIZE, SIZE), dtype=np.float32) + 0.5

# 7 Vertical Cane Ribs
rib_width = SIZE // 9
for i in range(1, 8):
    cx = i * rib_width + (rib_width // 2)
    dist_x = np.abs(x_idx - cx)
    rib_shape = np.clip(1.0 - (dist_x / (rib_width * 0.45)), 0, 1)
    pad_height += rib_shape * 0.35
    # Cane rib shadow in albedo
    pad_base[..., 0] -= (1.0 - rib_shape) * 18
    pad_base[..., 1] -= (1.0 - rib_shape) * 18
    pad_base[..., 2] -= (1.0 - rib_shape) * 18

# 3 Horizontal Knee Rolls in middle
for k in range(3):
    cy = SIZE // 2 - 120 + k * 120
    dist_y = np.abs(y_idx - cy)
    roll_shape = np.clip(1.0 - (dist_y / 50.0), 0, 1)
    pad_height += roll_shape * 0.4
    pad_base[dist_y < 10, :] = [210, 210, 215]

# Velcro Straps at bottom
strap_mask = (y_idx > SIZE - 300) & (y_idx < SIZE - 200)
pad_base[strap_mask, :] = [35, 45, 65] # Navy nylon strap
pad_height[strap_mask] += 0.15

pad_albedo = np.clip(pad_base, 0, 255).astype(np.uint8)
Image.fromarray(pad_albedo).save(os.path.join(OUT_DIR, "pads_2k_albedo.png"))

pad_normal = height_to_normal(pad_height, strength=5.5)
Image.fromarray(pad_normal).save(os.path.join(OUT_DIR, "pads_2k_normal.png"))

pad_rough = np.full((SIZE, SIZE), 85, dtype=np.uint8) # Semi-gloss PU leather
pad_rough[strap_mask] = 210 # Textured nylon webbing
Image.fromarray(pad_rough).save(os.path.join(OUT_DIR, "pads_2k_roughness.png"))

pad_ao = (np.clip(pad_height * 0.5 + 0.5, 0, 1) * 255).astype(np.uint8)
Image.fromarray(pad_ao).save(os.path.join(OUT_DIR, "pads_2k_ao.png"))

print("--- Generating 2K Team Jersey & Athlete Fabric PBR Maps ---")
# 6. Team Jersey (Athletic carbon-hex fabric weave, collar trim, team crest, name & number)
jersey_base = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
# India Navy / Team Blue: Color(0.04, 0.25, 0.65)
hex_pattern = (np.sin(x_idx * (160 * np.pi / SIZE)) * np.cos(y_idx * (160 * np.pi / SIZE)) > 0)
jersey_base[..., 0] = np.where(hex_pattern, 14, 8)
jersey_base[..., 1] = np.where(hex_pattern, 68, 52)
jersey_base[..., 2] = np.where(hex_pattern, 172, 148)

jersey_img = Image.fromarray(jersey_base.astype(np.uint8))
draw = ImageDraw.Draw(jersey_img)
# Team Crest on Left Chest
draw.ellipse([SIZE//4 - 120, SIZE//3 - 120, SIZE//4 + 120, SIZE//3 + 120], fill=(245, 140, 25), outline=(255, 255, 255), width=8)
draw.ellipse([SIZE//4 - 90, SIZE//3 - 90, SIZE//4 + 90, SIZE//3 + 90], fill=(10, 45, 120))
# Gold star champions insignia
draw.polygon([(SIZE//4, SIZE//3 - 145), (SIZE//4 + 20, SIZE//3 - 110), (SIZE//4 - 20, SIZE//3 - 110)], fill=(255, 215, 0))

# 3D Player Name & Number on Back
draw.text((SIZE//2 - 280, SIZE//2 - 180), "V. KOHLI", fill=(255, 255, 255))
draw.text((SIZE//2 - 140, SIZE//2 - 40), "18", fill=(255, 215, 0))

# Carbon-weave accent stripes on sleeves/side
draw.rectangle([0, 0, 180, SIZE], fill=(245, 140, 25))
draw.rectangle([SIZE - 180, 0, SIZE, SIZE], fill=(245, 140, 25))

jersey_img.save(os.path.join(OUT_DIR, "jersey_2k_albedo.png"))

jersey_height = np.where(hex_pattern, 0.58, 0.45).astype(np.float32)
jersey_normal = height_to_normal(jersey_height, strength=4.0)
Image.fromarray(jersey_normal).save(os.path.join(OUT_DIR, "jersey_2k_normal.png"))

jersey_rough = np.full((SIZE, SIZE), 140, dtype=np.uint8) # Moisture wicking micro-weave
Image.fromarray(jersey_rough).save(os.path.join(OUT_DIR, "jersey_2k_roughness.png"))

jersey_ao = (np.clip(jersey_height * 0.4 + 0.6, 0, 1) * 255).astype(np.uint8)
Image.fromarray(jersey_ao).save(os.path.join(OUT_DIR, "jersey_2k_ao.png"))

print("--- Generating 2K Cricket Helmet & Face PBR Maps ---")
# 7. Cricket Helmet (Composite carbon-fiber sheen, visor, chrome grille parts)
helmet_base = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
carbon_check = ((x_idx // 8) % 2) == ((y_idx // 8) % 2)
helmet_base[..., 0] = np.where(carbon_check, 12, 6)
helmet_base[..., 1] = np.where(carbon_check, 32, 18)
helmet_base[..., 2] = np.where(carbon_check, 95, 65)

# Titanium chrome grille region (Bottom half)
grille_mask = y_idx > (SIZE // 2)
bars = (x_idx % 64 < 14) | (y_idx % 64 < 14)
helmet_base[grille_mask & bars, :] = [225, 228, 235] # Chrome metallic

helmet_albedo = np.clip(helmet_base, 0, 255).astype(np.uint8)
Image.fromarray(helmet_albedo).save(os.path.join(OUT_DIR, "helmet_2k_albedo.png"))

helmet_height = np.where(carbon_check, 0.52, 0.48).astype(np.float32)
helmet_height[grille_mask & bars] = 0.95
helmet_normal = height_to_normal(helmet_height, strength=4.5)
Image.fromarray(helmet_normal).save(os.path.join(OUT_DIR, "helmet_2k_normal.png"))

helmet_rough = np.full((SIZE, SIZE), 65, dtype=np.uint8) # Glossy composite shell
helmet_rough[grille_mask & bars] = 20 # Mirror chrome grille
Image.fromarray(helmet_rough).save(os.path.join(OUT_DIR, "helmet_2k_roughness.png"))

helmet_metal = np.zeros((SIZE, SIZE), dtype=np.uint8)
helmet_metal[grille_mask & bars] = 245 # Chrome titanium grille
Image.fromarray(helmet_metal).save(os.path.join(OUT_DIR, "helmet_2k_metallic.png"))

print("--- Generating 2K Athlete Facial PBR Maps ---")
# 8. High-Poly Player Face (Sub-surface skin, pores, athletic brow, stubble, lips)
face_base = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
skin_noise = np.random.normal(1.0, 0.03, (SIZE, SIZE))
# Natural skin tone Color(0.78, 0.58, 0.44)
face_base[..., 0] = 202 * skin_noise
face_base[..., 1] = 148 * skin_noise
face_base[..., 2] = 112 * skin_noise

# Facial Features (Jawline stubble, athletic stubble shadow)
jaw_stubble = (y_idx > SIZE // 2) & (y_idx < SIZE * 0.85) & (np.abs(x_idx - SIZE//2) < SIZE * 0.35)
stubble_dots = np.random.uniform(0, 1, (SIZE, SIZE)) < 0.28
face_base[jaw_stubble & stubble_dots, :] = [60, 45, 38]

face_albedo = np.clip(face_base, 0, 255).astype(np.uint8)
Image.fromarray(face_albedo).save(os.path.join(OUT_DIR, "face_2k_albedo.png"))

face_height = np.random.normal(0.5, 0.03, (SIZE, SIZE))
face_height[jaw_stubble & stubble_dots] += 0.08 # Micro-stubble bump
face_normal = height_to_normal(face_height, strength=2.5)
Image.fromarray(face_normal).save(os.path.join(OUT_DIR, "face_2k_normal.png"))

face_rough = np.full((SIZE, SIZE), 145, dtype=np.uint8) # Natural human skin roughness
Image.fromarray(face_rough).save(os.path.join(OUT_DIR, "face_2k_roughness.png"))

print("✅ All 2K PBR Texture Sets Successfully Generated!")
