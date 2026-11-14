extends Resource
class_name FighterStats
## ============================================================================
## FighterStats.gd (Character Movement, Health & Defense Tuning Knobs)
## ============================================================================
## WHAT THIS SCRIPT DOES:
##   Custom Resource holding numeric tuning knobs for HP, weight, walk/air
##   speed, jump height, gravity, and block multipliers.
##
## CONNECTS TO:
##   - Bundled inside: ArchetypeData.gd (.tres presets)
##   - Read by: FighterBase.gd
## ============================================================================

# --- VITALITY & WEIGHT KNOBS -------------------------------------------------

@export_group("Vitality & Weight")

# Maximum starting health points per stock.
@export var max_hp: float = 100.0

# Character weight value (100.0 = standard baseline).
@export var weight: float = 100.0

# --- GROUND & AIR MOVEMENT KNOBS ---------------------------------------------

@export_group("Movement Speed")

# Ground horizontal walk speed in meters per second.
@export var walk_speed: float = 9.0

# Mid-air horizontal drift speed in meters per second.
@export var air_speed: float = 7.5

# --- JUMP & GRAVITY KNOBS ----------------------------------------------------

@export_group("Jumping & Gravity")

# Upward launch speed when jumping.
@export var jump_velocity: float = 13.5

# Downward gravity acceleration in meters per second squared.
@export var gravity_strength: float = 32.0

# Total jumps allowed before touching the ground (2 = double jump).
@export var max_jumps: int = 2

# --- DEFENSE & BLOCKING KNOBS ------------------------------------------------

@export_group("Defense & Block")

# Speed multiplier while blocking on the ground (0.0 = stationary).
@export var block_move_multiplier: float = 0.0

# Fraction of incoming damage taken while blocking.
@export var block_damage_multiplier: float = 0.25

# Fraction of incoming knockback taken while blocking.
@export var block_knockback_multiplier: float = 0.30
