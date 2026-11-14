extends Node3D
## ============================================================================
## StageBase.gd (Arena Boundaries, Spawn Points & Ring-Out Respawn Logic)
## ============================================================================
## WHAT THIS SCRIPT DOES:
##   Manages spawn markers and checks Blast Zone limits (top, bottom, left,
##   right), deducting a stock and respawning fighters who go out of bounds.
##
## CONNECTS TO:
##   - Listens to: GameEvents.gd ("fighter_spawned")
##   - Calls into: SessionManager.gd & FighterBase.gd
## ============================================================================

# --- INSPECTOR TUNING KNOBS (BLAST ZONE BOUNDARIES) --------------------------

# Bottom Blast Zone Y coordinate.
@export var blast_zone_bottom: float = -12.0

# Top Blast Zone Y coordinate.
@export var blast_zone_top: float = 24.0

# Left Blast Zone X coordinate.
@export var blast_zone_left: float = -26.0

# Right Blast Zone X coordinate.
@export var blast_zone_right: float = 26.0

# Safe fallback spawn position if no Marker3D nodes exist.
@export var fallback_spawn_position: Vector3 = Vector3(0.0, 3.0, 0.0)

# --- INTERNAL TRACKING VARIABLES ---------------------------------------------

# Active fighter nodes currently in the stage.
var active_fighters: Array[Node3D] = []

# Marker3D nodes collected from the SpawnPoints container.
var spawn_markers: Array[Marker3D] = []

# --- LIFECYCLE FUNCTIONS -----------------------------------------------------

# Gathers spawn markers, registers fighters, and announces match start.
# Parameters: None
# Returns: Nothing (void)
func _ready() -> void:
	_collect_spawn_markers()
	GameEvents.fighter_spawned.connect(_on_fighter_spawned)
	_register_existing_fighters_in_scene()
	GameEvents.match_state_changed.emit("Fighting")

# Monitors active fighters every physics tick for Blast Zone ring-outs.
# Parameters:
#   _delta : Fixed timestep in seconds (unused)
# Returns: Nothing (void)
func _physics_process(_delta: float) -> void:
	for i: int in range(active_fighters.size() - 1, -1, -1):
		var fighter: Node3D = active_fighters[i]

		if not is_instance_valid(fighter):
			active_fighters.remove_at(i)
			continue

		if _is_outside_blast_zones(fighter.global_position):
			_handle_fighter_ring_out(fighter)

# --- SPAWN POINT & BLAST ZONE FUNCTIONS --------------------------------------

# Returns the Z = 0 spawn position for a given player_id.
# Parameters:
#   player_id : Player slot number
# Returns:
#   Vector3 spawn location.
func get_spawn_position(player_id: int) -> Vector3:
	if not spawn_markers.is_empty():
		var marker_index: int = posmod(player_id, spawn_markers.size())
		var chosen_pos: Vector3 = spawn_markers[marker_index].global_position
		return Vector3(chosen_pos.x, chosen_pos.y, 0.0)

	return fallback_spawn_position

# Checks whether a 3D coordinate is outside any of the 4 Blast Zones.
# Parameters:
#   pos : Fighter's global_position
# Returns:
#   True if out of bounds, false otherwise.
func _is_outside_blast_zones(pos: Vector3) -> bool:
	if pos.y < blast_zone_bottom:
		return true
	if pos.y > blast_zone_top:
		return true
	if pos.x < blast_zone_left:
		return true
	if pos.x > blast_zone_right:
		return true
	return false

# Deducts a stock in SessionManager and teleports the fighter back to their spawn marker.
# Parameters:
#   fighter : Fighter node that crossed out of bounds
# Returns: Nothing (void)
func _handle_fighter_ring_out(fighter: Node3D) -> void:
	var pid: int = int(fighter.get("player_id")) if "player_id" in fighter else 0
	var stocks_left: int = SessionManager.deduct_player_stock(pid)
	print("[StageBase] Player ", pid, " ringed out! Remaining stocks: ", stocks_left)

	var respawn_pos: Vector3 = get_spawn_position(pid)
	if fighter.has_method("respawn_at"):
		fighter.respawn_at(respawn_pos)
	else:
		fighter.global_position = respawn_pos

# --- INTERNAL SETUP HELPERS --------------------------------------------------

# Collects all Marker3D children inside the SpawnPoints node.
# Parameters: None
# Returns: Nothing (void)
func _collect_spawn_markers() -> void:
	spawn_markers.clear()
	var spawn_container: Node = get_node_or_null("SpawnPoints")
	if spawn_container == null:
		return

	for child: Node in spawn_container.get_children():
		if child is Marker3D:
			spawn_markers.append(child)

# Registers any CharacterBody3D already present in the scene tree.
# Parameters: None
# Returns: Nothing (void)
func _register_existing_fighters_in_scene() -> void:
	for child: Node in get_children():
		if child is CharacterBody3D and not active_fighters.has(child):
			active_fighters.append(child)

# Adds newly spawned fighters to active_fighters.
# Parameters:
#   _player_id      : Player slot number
#   _archetype_name : Archetype display name
#   fighter_node    : 3D fighter node
# Returns: Nothing (void)
func _on_fighter_spawned(_player_id: int, _archetype_name: String, fighter_node: Node3D) -> void:
	if fighter_node != null and not active_fighters.has(fighter_node):
		active_fighters.append(fighter_node)
