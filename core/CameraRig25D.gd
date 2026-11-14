extends Node3D
## ============================================================================
## CameraRig25D.gd (Dynamic 2.5D Arena Camera Controller)
## ============================================================================
## WHAT THIS SCRIPT DOES:
##   Smoothly tracks all active fighters on the X/Y fighting plane and zooms
##   in/out along the Z axis based on fighter spread.
##
## CONNECTS TO:
##   - Listens to: GameEvents.gd ("fighter_spawned")
##   - Used inside: stages/TestArena.tscn
## ============================================================================

# --- INSPECTOR TUNING KNOBS --------------------------------------------------

# Horizontal and vertical follow smoothing speed.
@export var follow_smooth_speed: float = 6.0

# Z-axis zoom smoothing speed.
@export var zoom_smooth_speed: float = 4.0

# Upward camera framing offset in meters.
@export var vertical_offset: float = 2.0

# Minimum Z distance when fighters are close together.
@export var min_camera_distance: float = 14.0

# Maximum Z distance when fighters are far apart.
@export var max_camera_distance: float = 28.0

# Extra Z distance added per meter of fighter separation.
@export var spread_zoom_factor: float = 0.65

# --- TRACKED FIGHTER LIST ----------------------------------------------------

# List of active fighter nodes in the arena.
var tracked_fighters: Array[Node3D] = []

# Child Camera3D node rendering the viewport.
@onready var camera_node: Camera3D = get_node_or_null("Camera3D")

# --- LIFECYCLE FUNCTIONS -----------------------------------------------------

# Connects to GameEvents and ensures Camera3D is active.
# Parameters: None
# Returns: Nothing (void)
func _ready() -> void:
	GameEvents.fighter_spawned.connect(_on_fighter_spawned)

	if camera_node == null:
		camera_node = Camera3D.new()
		camera_node.name = "Camera3D"
		add_child(camera_node)

	camera_node.current = true

# Updates camera X/Y center and Z zoom distance every visual frame.
# Parameters:
#   delta : Frame delta time in seconds
# Returns: Nothing (void)
func _process(delta: float) -> void:
	_clean_invalid_fighters()

	if tracked_fighters.is_empty():
		return

	var framing_data: Dictionary = _calculate_framing_targets()
	var target_center: Vector2 = framing_data["center"]
	var target_distance: float = framing_data["distance"]

	global_position.x = lerpf(global_position.x, target_center.x, follow_smooth_speed * delta)
	global_position.y = lerpf(global_position.y, target_center.y + vertical_offset, follow_smooth_speed * delta)
	global_position.z = lerpf(global_position.z, target_distance, zoom_smooth_speed * delta)

# --- SIGNAL CALLBACKS --------------------------------------------------------

# Adds newly spawned fighters to tracked_fighters.
# Parameters:
#   _player_id      : Player slot number
#   _archetype_name : Archetype name
#   fighter_node    : 3D fighter node to track
# Returns: Nothing (void)
func _on_fighter_spawned(_player_id: int, _archetype_name: String, fighter_node: Node3D) -> void:
	if fighter_node != null and not tracked_fighters.has(fighter_node):
		tracked_fighters.append(fighter_node)

# --- INTERNAL HELPER FUNCTIONS -----------------------------------------------

# Removes freed fighter references from tracked_fighters.
# Parameters: None
# Returns: Nothing (void)
func _clean_invalid_fighters() -> void:
	for i: int in range(tracked_fighters.size() - 1, -1, -1):
		if not is_instance_valid(tracked_fighters[i]):
			tracked_fighters.remove_at(i)

# Calculates the X/Y bounding midpoint and target Z zoom distance for all fighters.
# Parameters: None
# Returns:
#   Dictionary with "center" (Vector2) and "distance" (float).
func _calculate_framing_targets() -> Dictionary:
	var first_pos: Vector3 = tracked_fighters[0].global_position
	var min_x: float = first_pos.x
	var max_x: float = first_pos.x
	var min_y: float = first_pos.y
	var max_y: float = first_pos.y

	for fighter: Node3D in tracked_fighters:
		var pos: Vector3 = fighter.global_position
		min_x = minf(min_x, pos.x)
		max_x = maxf(max_x, pos.x)
		min_y = minf(min_y, pos.y)
		max_y = maxf(max_y, pos.y)

	var center_x: float = (min_x + max_x) * 0.5
	var center_y: float = (min_y + max_y) * 0.5

	var horizontal_span: float = max_x - min_x
	var vertical_span: float = max_y - min_y
	var largest_span: float = maxf(horizontal_span, vertical_span * 1.4)

	var desired_z: float = min_camera_distance + (largest_span * spread_zoom_factor)
	desired_z = clampf(desired_z, min_camera_distance, max_camera_distance)

	return {
		"center": Vector2(center_x, center_y),
		"distance": desired_z
	}
