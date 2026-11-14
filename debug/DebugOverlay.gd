extends CanvasLayer
## ============================================================================
## DebugOverlay.gd (Live On-Screen Sandbox Readout & Archetype Switcher)
## ============================================================================
## WHAT THIS SCRIPT DOES:
##   Displays live fighter telemetry in the top-left corner (F1 to toggle UI,
##   F2 to cycle Player 1 through the 4 starter archetypes live).
##
## CONNECTS TO:
##   - Listens to: GameEvents.gd
##   - Reads/Writes: SessionManager.gd & FighterBase.gd
## ============================================================================

# --- TRACKED STATE VARIABLES -------------------------------------------------

# Reference to Player 1's 3D fighter node.
var tracked_fighter: CharacterBody3D = null

# Active index inside SessionManager.STARTER_ARCHETYPES (0..3).
var current_archetype_index: int = 0

# Displayed stock count for Player 1.
var displayed_stocks: int = 3

# Last move slot or status text shown on screen.
var last_slot_message: String = "None"

# --- UI NODE REFERENCES ------------------------------------------------------

# Top-left background panel toggled by F1.
@onready var panel_container: Control = get_node_or_null("DebugPanel")

# Text label displaying live telemetry lines.
@onready var debug_label: Label = get_node_or_null("DebugPanel/MarginContainer/DebugLabel")

# --- LIFECYCLE FUNCTIONS -----------------------------------------------------

# Connects to GameEvents signals on boot.
# Parameters: None
# Returns: Nothing (void)
func _ready() -> void:
	displayed_stocks = SessionManager.starting_stocks

	GameEvents.fighter_spawned.connect(_on_fighter_spawned)
	GameEvents.move_slot_pressed.connect(_on_move_slot_pressed)
	GameEvents.stock_lost.connect(_on_stock_lost)

# Updates the on-screen readout every frame while visible.
# Parameters:
#   _delta : Frame delta time in seconds (unused)
# Returns: Nothing (void)
func _process(_delta: float) -> void:
	if panel_container != null and not panel_container.visible:
		return

	if not is_instance_valid(tracked_fighter):
		_find_fighter_in_scene()

	_update_readout_text()

# --- HOTKEY HANDLING FUNCTIONS -----------------------------------------------

# Listens for F1 (toggle overlay) and F2 (cycle starter archetype).
# Parameters:
#   event : Incoming Godot InputEvent
# Returns: Nothing (void)
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			if panel_container != null:
				panel_container.visible = not panel_container.visible
		elif event.keycode == KEY_F2:
			_cycle_active_archetype()

# Cycles Player 1 to the next starter archetype and hot-reloads its .tres preset.
# Parameters: None
# Returns: Nothing (void)
func _cycle_active_archetype() -> void:
	var list_size: int = SessionManager.STARTER_ARCHETYPES.size()
	current_archetype_index = (current_archetype_index + 1) % list_size

	var next_id: String = SessionManager.STARTER_ARCHETYPES[current_archetype_index]
	SessionManager.set_player_archetype(0, next_id)

	if is_instance_valid(tracked_fighter) and tracked_fighter.has_method("load_archetype_by_name"):
		tracked_fighter.load_archetype_by_name(next_id)
		last_slot_message = "Swapped to " + next_id.capitalize()

# --- TEXT READOUT BUILDER ----------------------------------------------------

# Formats the live position, velocity, floor, block, and move readout text.
# Parameters: None
# Returns: Nothing (void)
func _update_readout_text() -> void:
	if debug_label == null:
		return

	if not is_instance_valid(tracked_fighter):
		debug_label.text = "HEX-N-HAX SANDBOX DEBUG [F1: Hide | F2: Cycle Class]\nWaiting for Fighter..."
		return

	var pos: Vector3 = tracked_fighter.global_position
	var vel: Vector3 = tracked_fighter.velocity
	var arch_title: String = str(tracked_fighter.get("archetype_name"))
	var hp_cur: float = float(tracked_fighter.get("current_hp"))
	var hp_max: float = float(tracked_fighter.get("max_hp"))
	var jumps_left: int = int(tracked_fighter.get("jumps_remaining"))
	var jumps_max: int = int(tracked_fighter.get("max_jumps"))
	var blocking: bool = bool(tracked_fighter.get("is_blocking"))
	var grounded_text: String = "YES (Grounded)" if tracked_fighter.is_on_floor() else "NO (Airborne)"
	var block_text: String = "HOLDING BLOCK" if blocking else "Open"

	var lines: PackedStringArray = [
		"=== HEX-N-HAX SANDBOX [F1: Toggle UI | F2: Swap Class] ===",
		"Archetype : %s   |   Stocks: %d   |   HP: %.0f / %.0f" % [arch_title, displayed_stocks, hp_cur, hp_max],
		"Position  : X: %6.2f   Y: %6.2f   Z: %5.2f (2.5D Locked)" % [pos.x, pos.y, pos.z],
		"Velocity  : VX: %5.2f   VY: %5.2f" % [vel.x, vel.y],
		"Floor     : %s   |   Jumps Left: %d / %d" % [grounded_text, jumps_left, jumps_max],
		"Defense   : %s" % block_text,
		"Last Move : %s" % last_slot_message
	]

	debug_label.text = "\n".join(lines)

# --- SIGNAL CALLBACKS & SCENE LOOKUP -----------------------------------------

# Stores Player 1's fighter reference when spawned.
# Parameters:
#   player_id       : Player slot number
#   _archetype_name : Archetype name
#   fighter_node    : Spawned 3D fighter node
# Returns: Nothing (void)
func _on_fighter_spawned(player_id: int, _archetype_name: String, fighter_node: Node3D) -> void:
	if player_id == 0 and fighter_node is CharacterBody3D:
		tracked_fighter = fighter_node

# Updates the last move slot text when Player 1 presses Slots 1-6.
# Parameters:
#   player_id  : Player slot number
#   slot_index : Slot number (1 to 6)
#   move_name  : Move display name
#   cooldown   : Cooldown in seconds
# Returns: Nothing (void)
func _on_move_slot_pressed(player_id: int, slot_index: int, move_name: String, cooldown: float) -> void:
	if player_id == 0:
		last_slot_message = "Slot %d -> %s (%.1fs CD)" % [slot_index, move_name, cooldown]

# Updates displayed stocks when Player 1 rings out.
# Parameters:
#   player_id        : Player slot number
#   remaining_stocks : Remaining lives
# Returns: Nothing (void)
func _on_stock_lost(player_id: int, remaining_stocks: int) -> void:
	if player_id == 0:
		displayed_stocks = remaining_stocks
		last_slot_message = "RING OUT! Respawned at marker."

# Scans the active scene for a CharacterBody3D if tracked_fighter is unset.
# Parameters: None
# Returns: Nothing (void)
func _find_fighter_in_scene() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	for child: Node in current_scene.get_children():
		if child is CharacterBody3D:
			tracked_fighter = child
			return
