extends Node
## ============================================================================
## SessionManager.gd (Match Session, Player Slots & Archetype Selection)
## ============================================================================
## WHAT THIS SCRIPT DOES:
##   Stores active player slots, team numbers, remaining stocks (lives), and
##   chosen character archetypes. Defaults Player 1 to "fighter" on boot.
##
## CONNECTS TO:
##   - Read by: FighterBase.gd, StageBase.gd, DebugOverlay.gd
##   - Broadcasts to: GameEvents.gd
## ============================================================================

# --- MATCH RULES & SETTINGS --------------------------------------------------

# Starting lives (stocks) per player.
var starting_stocks: int = 3

# Whether teammates can damage each other.
var friendly_fire_enabled: bool = false

# True when running an online networked match.
var is_online_session: bool = false

# --- ACTIVE PLAYER SLOTS -----------------------------------------------------

# List of Dictionaries holding player_id, team_id, archetype, and remaining_stocks.
var active_players: Array[Dictionary] = []

# Valid starter archetype preset IDs for sandbox cycling (F2).
const STARTER_ARCHETYPES: Array[String] = ["fighter", "wizard", "rogue", "ranger"]

# --- LIFECYCLE FUNCTIONS -----------------------------------------------------

# Sets up a default Player 1 sandbox session when the game boots.
# Parameters: None
# Returns: Nothing (void)
func _ready() -> void:
	setup_default_sandbox_session()

# --- PUBLIC SESSION FUNCTIONS ------------------------------------------------

# Resets active players and registers Player 1 (slot 0) as "fighter".
# Parameters: None
# Returns: Nothing (void)
func setup_default_sandbox_session() -> void:
	active_players.clear()
	register_player(0, 0, "fighter")

# Adds a player entry into active_players with full starting stocks.
# Parameters:
#   player_id : Player slot number (0 = Player 1, etc.)
#   team_id   : Team number
#   archetype : Lowercase preset name ("fighter", "wizard", "rogue", "ranger")
# Returns: Nothing (void)
func register_player(player_id: int, team_id: int, archetype: String) -> void:
	var player_entry: Dictionary = {
		"player_id": player_id,
		"team_id": team_id,
		"archetype": archetype.to_lower(),
		"remaining_stocks": starting_stocks
	}
	active_players.append(player_entry)

# Returns the assigned archetype ID for a given player slot.
# Parameters:
#   player_id : Player slot number to look up
# Returns:
#   Lowercase archetype string (defaults to "fighter").
func get_player_archetype(player_id: int) -> String:
	for player_info: Dictionary in active_players:
		if player_info["player_id"] == player_id:
			return str(player_info["archetype"])
	return "fighter"

# Updates a player's active archetype ID.
# Parameters:
#   player_id     : Player slot number to update
#   new_archetype : New lowercase archetype ID
# Returns: Nothing (void)
func set_player_archetype(player_id: int, new_archetype: String) -> void:
	for player_info: Dictionary in active_players:
		if player_info["player_id"] == player_id:
			player_info["archetype"] = new_archetype.to_lower()
			return

# Subtracts 1 stock from the given player and emits GameEvents.stock_lost.
# Parameters:
#   player_id : Player slot number who lost a stock
# Returns:
#   Remaining stock count as an int.
func deduct_player_stock(player_id: int) -> int:
	for player_info: Dictionary in active_players:
		if player_info["player_id"] == player_id:
			var current_lives: int = int(player_info["remaining_stocks"])
			current_lives = maxi(0, current_lives - 1)
			player_info["remaining_stocks"] = current_lives
			GameEvents.stock_lost.emit(player_id, current_lives)
			return current_lives
	return 0
