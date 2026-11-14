extends CharacterBody3D
## ============================================================================
## FighterBase.gd (Core 2.5D Fighter Movement, Jump, Block & Archetype Loader)
## ============================================================================
## WHAT THIS SCRIPT DOES:
##   Controls the 3D character body on the flat Z = 0 fighting plane. Loads its
##   assigned ArchetypeData (.tres) file on spawn, applies colors and movement
##   stats, and handles walking, double-jumping, blocking, and Slots 1-6.
##
## CONNECTS TO:
##   - Reads data from: ArchetypeData.gd & FighterStats.gd
##   - Reads controls from: Godot's InputMap (loaded by InputLoader.gd)
##   - Reads session info from: SessionManager.gd
##   - Broadcasts events to: GameEvents.gd
## ============================================================================

# --- INSPECTOR TUNING KNOBS --------------------------------------------------

# Player slot ID (0 = Player 1, 1 = Player 2, etc.).
@export var player_id: int = 0

# Optional direct ArchetypeData .tres reference; if null, loads from SessionManager.
@export var archetype_preset: ArchetypeData

# Display name of the active archetype.
@export var archetype_name: String = "Fighter"

# Maximum health points per stock.
@export var max_hp: float = 100.0

# Character weight value.
@export var weight: float = 100.0

# Ground walk speed in meters per second.
@export var walk_speed: float = 9.0

# Air drift speed in meters per second.
@export var air_speed: float = 7.5

# Upward jump launch speed.
@export var jump_velocity: float = 13.5

# Downward gravity acceleration.
@export var gravity_strength: float = 32.0

# Maximum jumps before landing (2 = double jump).
@export var max_jumps: int = 2

# Speed multiplier while holding Block on the ground.
@export var block_move_multiplier: float = 0.0

# --- LIVE STATE VARIABLES ----------------------------------------------------

# Current health points remaining.
var current_hp: float = 100.0

# Jumps remaining before touching the ground again.
var jumps_remaining: int = 2

# True while holding the Block button.
var is_blocking: bool = false

# Horizontal facing direction (-1.0 = Left, +1.0 = Right).
var facing_direction: float = 1.0

# Label of the last move slot pressed (shown in DebugOverlay).
var last_move_triggered: String = "None"

# Base capsule mesh color loaded from ArchetypeData.
var base_mesh_color: Color = Color(0.85, 0.25, 0.25, 1.0)

# Per-instance material applied to BodyMesh.
var personal_material: StandardMaterial3D

# Move names for Slots 1 through 6.
var slot_move_names: Dictionary = {
	1: "Quick Attack",
	2: "Heavy Attack",
	3: "Projectile",
	4: "Recovery",
	5: "Special",
	6: "Ultimate"
}

# Cooldown durations (in seconds) for Slots 1 through 6.
var slot_cooldowns: Dictionary = {
	1: 0.4,
	2: 0.9,
	3: 1.2,
	4: 1.5,
	5: 4.0,
	6: 12.0
}

# --- NODE REFERENCES ---------------------------------------------------------

# Reference to the 3D capsule MeshInstance3D.
@onready var body_mesh: MeshInstance3D = get_node_or_null("BodyMesh")

# --- LIFECYCLE FUNCTIONS -----------------------------------------------------

# Initializes material, loads the active archetype preset, and locks Z = 0.
# Parameters: None
# Returns: Nothing (void)
func _ready() -> void:
	_setup_personal_mesh_material()

	if archetype_preset != null:
		apply_archetype_data(archetype_preset)
	else:
		var chosen_id: String = SessionManager.get_player_archetype(player_id)
		load_archetype_by_name(chosen_id)

	global_position.z = 0.0
	GameEvents.fighter_spawned.emit(player_id, archetype_name, self)

# Runs every physics tick (60 Hz) to process movement, jumps, block, and move inputs.
# Parameters:
#   delta : Fixed timestep in seconds
# Returns: Nothing (void)
func _physics_process(delta: float) -> void:
	_apply_gravity_and_floor_check(delta)
	_handle_block_input()
	_handle_jump_input()
	_handle_horizontal_movement()
	_handle_move_slot_inputs()

	move_and_slide()

	# Clamp position and velocity strictly onto the 2D X/Y plane (Z = 0).
	global_position.z = 0.0
	velocity.z = 0.0

# --- ARCHETYPE PRESET LOADING FUNCTIONS --------------------------------------

# Loads an ArchetypeData .tres file by lowercase name from res://fighters/presets/archetypes/.
# Parameters:
#   target_archetype_id : Lowercase preset name ("fighter", "wizard", "rogue", "ranger")
# Returns: Nothing (void)
func load_archetype_by_name(target_archetype_id: String) -> void:
	var clean_id: String = target_archetype_id.strip_edges().to_lower()
	var file_path: String = "res://fighters/presets/archetypes/" + clean_id + ".tres"

	if not ResourceLoader.exists(file_path):
		push_warning("[FighterBase] Archetype preset not found at: " + file_path)
		return

	var loaded_resource: Resource = load(file_path)
	if loaded_resource is ArchetypeData:
		archetype_preset = loaded_resource
		apply_archetype_data(archetype_preset)

# Copies stats, colors, and move slot names from an ArchetypeData resource onto this fighter.
# Parameters:
#   data : The ArchetypeData resource to apply
# Returns: Nothing (void)
func apply_archetype_data(data: ArchetypeData) -> void:
	if data == null:
		return

	archetype_name = data.display_name
	base_mesh_color = data.mesh_color
	_update_mesh_color()

	if data.stats != null:
		max_hp = data.stats.max_hp
		current_hp = max_hp
		weight = data.stats.weight
		walk_speed = data.stats.walk_speed
		air_speed = data.stats.air_speed
		jump_velocity = data.stats.jump_velocity
		gravity_strength = data.stats.gravity_strength
		max_jumps = data.stats.max_jumps
		block_move_multiplier = data.stats.block_move_multiplier

	for slot_num: int in range(1, 7):
		slot_move_names[slot_num] = data.get_move_name(slot_num)
		slot_cooldowns[slot_num] = data.get_move_cooldown(slot_num)

	jumps_remaining = max_jumps

# --- MOVEMENT & PHYSICS HELPER FUNCTIONS -------------------------------------

# Applies gravity in mid-air or resets jump count when standing on a floor.
# Parameters:
#   delta : Fixed timestep in seconds
# Returns: Nothing (void)
func _apply_gravity_and_floor_check(delta: float) -> void:
	if is_on_floor():
		jumps_remaining = max_jumps
	else:
		velocity.y -= gravity_strength * delta

# Checks the Block button and updates mesh tint and GameEvents when toggled.
# Parameters: None
# Returns: Nothing (void)
func _handle_block_input() -> void:
	var wants_to_block: bool = Input.is_action_pressed("block")
	if wants_to_block != is_blocking:
		is_blocking = wants_to_block
		_update_mesh_color()
		GameEvents.block_state_changed.emit(player_id, is_blocking)

# Checks the Jump button and applies upward jump velocity if jumps remain.
# Parameters: None
# Returns: Nothing (void)
func _handle_jump_input() -> void:
	if is_blocking:
		return

	if Input.is_action_just_pressed("jump") and jumps_remaining > 0:
		jumps_remaining -= 1
		velocity.y = jump_velocity

# Reads Left/Right input and applies horizontal velocity.
# Parameters: None
# Returns: Nothing (void)
func _handle_horizontal_movement() -> void:
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var current_speed: float = walk_speed if is_on_floor() else air_speed

	if is_blocking and is_on_floor():
		current_speed *= block_move_multiplier

	velocity.x = input_axis * current_speed

	if absf(input_axis) > 0.1:
		facing_direction = signf(input_axis)

# --- ABILITY SLOT INPUT FUNCTIONS --------------------------------------------

# Checks for presses on Move Slots 1 through 6.
# Parameters: None
# Returns: Nothing (void)
func _handle_move_slot_inputs() -> void:
	if is_blocking:
		return

	if Input.is_action_just_pressed("slot_1_quick"):
		_trigger_move_slot(1)
	elif Input.is_action_just_pressed("slot_2_heavy"):
		_trigger_move_slot(2)
	elif Input.is_action_just_pressed("slot_3_projectile"):
		_trigger_move_slot(3)
	elif Input.is_action_just_pressed("slot_4_recovery"):
		_trigger_move_slot(4)
	elif Input.is_action_just_pressed("slot_5_special"):
		_trigger_move_slot(5)
	elif Input.is_action_just_pressed("slot_6_ultimate"):
		_trigger_move_slot(6)

# Broadcasts the pressed move slot over GameEvents and logs the slot call.
# Parameters:
#   slot_number : Move slot index (1 through 6)
# Returns: Nothing (void)
func _trigger_move_slot(slot_number: int) -> void:
	var move_label: String = str(slot_move_names.get(slot_number, "Unknown Move"))
	var cooldown_time: float = float(slot_cooldowns.get(slot_number, 1.0))

	last_move_triggered = "Slot " + str(slot_number) + ": " + move_label

	GameEvents.move_slot_pressed.emit(player_id, slot_number, move_label, cooldown_time)
	print("[FighterBase] Player ", player_id, " (", archetype_name, ") used -> Slot ", slot_number, ": ", move_label)

# --- VISUAL MATERIAL & RESPAWN HELPERS ---------------------------------------

# Creates a unique StandardMaterial3D override for this fighter's capsule mesh.
# Parameters: None
# Returns: Nothing (void)
func _setup_personal_mesh_material() -> void:
	if body_mesh == null:
		return
	personal_material = StandardMaterial3D.new()
	personal_material.roughness = 0.6
	personal_material.albedo_color = base_mesh_color
	body_mesh.material_override = personal_material

# Tints the capsule darker while holding Block.
# Parameters: None
# Returns: Nothing (void)
func _update_mesh_color() -> void:
	if personal_material == null:
		return
	if is_blocking:
		personal_material.albedo_color = base_mesh_color.darkened(0.45)
	else:
		personal_material.albedo_color = base_mesh_color

# Teleports the fighter to a spawn coordinate and resets velocity, HP, and jumps.
# Parameters:
#   spawn_position : Target 3D spawn position
# Returns: Nothing (void)
func respawn_at(spawn_position: Vector3) -> void:
	global_position = Vector3(spawn_position.x, spawn_position.y, 0.0)
	velocity = Vector3.ZERO
	current_hp = max_hp
	jumps_remaining = max_jumps
	is_blocking = false
	_update_mesh_color()
