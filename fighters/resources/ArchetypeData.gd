extends Resource
class_name ArchetypeData
## ============================================================================
## ArchetypeData.gd (Complete Character Class Blueprint)
## ============================================================================
## WHAT THIS SCRIPT DOES:
##   Bundles a character class's display name, 3D capsule color, FighterStats
##   resource, and placeholder names/cooldowns for Move Slots 1 through 6.
##
## CONNECTS TO:
##   - Uses: FighterStats.gd
##   - Saved as: fighter.tres, wizard.tres, rogue.tres, ranger.tres
##   - Read by: FighterBase.gd
## ============================================================================

# --- IDENTITY & VISUAL APPEARANCE --------------------------------------------

@export_group("Identity & Visuals")

# Lowercase internal ID matching the .tres filename.
@export var archetype_id: String = "fighter"

# Display name shown in the HUD and Debug Overlay.
@export var display_name: String = "Fighter"

# Plain-English description of the archetype.
@export_multiline var description: String = "Placeholder description."

# Color applied to the 3D capsule mesh in the arena.
@export var mesh_color: Color = Color(0.85, 0.25, 0.25, 1.0)

# --- PHYSICAL STATS SHEET ----------------------------------------------------

@export_group("Physical Stats")

# Sub-resource holding HP, movement speed, jump, and block numbers.
@export var stats: FighterStats

# --- 6 ABILITY SLOT PLACEHOLDERS ---------------------------------------------

@export_group("Slot 1: Quick Attack")
@export var slot_1_quick_name: String = "Quick Attack"
@export var slot_1_cooldown: float = 0.4

@export_group("Slot 2: Heavy Attack")
@export var slot_2_heavy_name: String = "Heavy Attack"
@export var slot_2_cooldown: float = 0.9

@export_group("Slot 3: Projectile")
@export var slot_3_projectile_name: String = "Projectile"
@export var slot_3_cooldown: float = 1.2

@export_group("Slot 4: Recovery")
@export var slot_4_recovery_name: String = "Recovery"
@export var slot_4_cooldown: float = 1.5

@export_group("Slot 5: Special")
@export var slot_5_special_name: String = "Special"
@export var slot_5_cooldown: float = 4.0

@export_group("Slot 6: Ultimate")
@export var slot_6_ultimate_name: String = "Ultimate"
@export var slot_6_cooldown: float = 12.0

# --- PUBLIC HELPER FUNCTIONS -------------------------------------------------

# Returns the move name for slot 1 through 6.
# Parameters:
#   slot_number : Move slot index (1 to 6)
# Returns:
#   Move name String.
func get_move_name(slot_number: int) -> String:
	match slot_number:
		1: return slot_1_quick_name
		2: return slot_2_heavy_name
		3: return slot_3_projectile_name
		4: return slot_4_recovery_name
		5: return slot_5_special_name
		6: return slot_6_ultimate_name
		_: return "Unknown Move"

# Returns the cooldown duration (in seconds) for slot 1 through 6.
# Parameters:
#   slot_number : Move slot index (1 to 6)
# Returns:
#   Cooldown time as a float.
func get_move_cooldown(slot_number: int) -> float:
	match slot_number:
		1: return slot_1_cooldown
		2: return slot_2_cooldown
		3: return slot_3_cooldown
		4: return slot_4_cooldown
		5: return slot_5_cooldown
		6: return slot_6_cooldown
		_: return 1.0
