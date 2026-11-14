extends Node
## ============================================================================
## GameEvents.gd (Global Signal Bus)
## ============================================================================
## WHAT THIS SCRIPT DOES:
##   Central radio station for the game. Fighters broadcast signals here so
##   the Camera, Stage, and Debug UI can react without being tightly coupled.
##
## CONNECTS TO:
##   - Broadcast by: FighterBase.gd, StageBase.gd, SessionManager.gd
##   - Listened to by: DebugOverlay.gd, CameraRig25D.gd
## ============================================================================

# --- FIGHTER & INPUT SIGNALS -------------------------------------------------

# Broadcast whenever a fighter spawns into the arena.
# Parameters:
#   player_id      : Player slot number (0 = Player 1, 1 = Player 2)
#   archetype_name : Display name of the character class
#   fighter_node   : The 3D CharacterBody3D node in the scene
signal fighter_spawned(player_id: int, archetype_name: String, fighter_node: Node3D)

# Broadcast whenever a player presses one of the 6 ability/move buttons.
# Parameters:
#   player_id  : Player slot number who pressed the button
#   slot_index : Move slot number (1 through 6)
#   move_name  : Plain-English name of the move
#   cooldown   : Placeholder cooldown duration in seconds
signal move_slot_pressed(player_id: int, slot_index: int, move_name: String, cooldown: float)

# Broadcast whenever a player holds or releases the Block button.
# Parameters:
#   player_id   : Player slot number whose block state changed
#   is_blocking : True when holding block, false when released
signal block_state_changed(player_id: int, is_blocking: bool)

# --- STAGE & MATCH FLOW SIGNALS ----------------------------------------------

# Broadcast whenever a fighter crosses a Blast Zone and loses a life (stock).
# Parameters:
#   player_id        : Player slot number who ringed out
#   remaining_stocks : Lives left for that player
signal stock_lost(player_id: int, remaining_stocks: int)

# Broadcast whenever the match phase changes (e.g., "Fighting").
# Parameters:
#   new_state_name : Text name of the new match state
signal match_state_changed(new_state_name: String)
