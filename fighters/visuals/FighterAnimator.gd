extends Node3D
class_name FighterAnimator
## ============================================================================
## FighterAnimator.gd (Mixamo Model Loader & Animation State Controller)
## ============================================================================
## WHAT THIS SCRIPT DOES:
##   1. Dynamically spawns Y Bot (Fighter/Rogue) or X Bot (Wizard/Ranger).
##   2. Extracts animations from the Mixamo FBX files ONCE into a shared static
##	  AnimationLibrary so runtime character swapping is instantaneous.
##   3. Controls Idle, Bouncing Fight Idle (after running, with 5s timeout),
##	  Running locomotion, Jumping Up, Falling Idle, Block, Combat Slots
##	  (1, 2, 3, 5, 6 KO), and L1 Emotes with a 45-degree turn toward the camera.
## ============================================================================

# --- CONSTANTS & FILE PATHS --------------------------------------------------

# Base folder containing the curated Mixamo FBX models and animations.
const MIXAMO_DIR: String = "res://mixamo source/curated starter pack/"

# Model file paths mapped by archetype group.
const Y_BOT_PATH: String = MIXAMO_DIR + "Y Bot.fbx"
const X_BOT_PATH: String = MIXAMO_DIR + "X Bot.fbx"

# Seconds of no input in Bouncing Fight Idle before returning to initial Idle.
const FIGHT_IDLE_TIMEOUT: float = 5.0

# Start time offset (in seconds) for emote_0 (Taunt) to skip its initial fight-idle windup.
const TAUNT_START_OFFSET: float = 0.65

# Precalculated radian angles for facing Left, Right, and 45-degree camera emotes.
const YAW_RIGHT: float = deg_to_rad(90.0)
const YAW_LEFT: float = deg_to_rad(-90.0)
const YAW_EMOTE_RIGHT: float = deg_to_rad(45.0)
const YAW_EMOTE_LEFT: float = deg_to_rad(-45.0)

# Mapping of internal animation keys to their Mixamo FBX filenames.
const ANIM_FILES: Dictionary = {
	"idle": "X Bot@Idle.fbx",
	"fight_idle": "X Bot@Bouncing Fight Idle.fbx",
	"run": "X Bot@Running.fbx",
	"jump_up": "X Bot@Jumping Up.fbx",
	"fall_idle": "X Bot@Falling Idle.fbx",
	"block": "X Bot@Block.fbx",
	"slot_1": "X Bot@Lead Jab.fbx",
	"slot_2": "X Bot@Elbow Punch.fbx",
	"slot_3": "X Bot@Hook Punch.fbx",
	"slot_5": "X Bot@Kicking.fbx",
	"slot_6_ko": "X Bot@Knocked Out.fbx",
	"emote_0": "X Bot@Taunt.fbx",
	"emote_1": "X Bot@Praying.fbx",
	"emote_2": "X Bot@Texting While Standing.fbx",
	"emote_3": "X Bot@Dancing Twerk.fbx"
}

# List of animation keys that should loop continuously while active.
const LOOPING_ANIMS: Array[String] = [
	"idle",
	"fight_idle",
	"run",
	"fall_idle",
	"block"
]

# Readable labels for the 4-emote L1 cycle.
const EMOTE_LABELS: Array[String] = [
	"Taunt",
	"Praying",
	"Texting",
	"Dancing Twerk"
]

# Static cache so all 15 Mixamo FBX animations are only parsed from disk once per session.
static var _cached_shared_library: AnimationLibrary = null

# --- LIVE STATE VARIABLES ----------------------------------------------------

# Currently instantiated 3D bot Node3D (Y Bot or X Bot).
var active_bot_node: Node3D = null

# AnimationPlayer driving the active bot skeleton.
var anim_player: AnimationPlayer = null

# Name of the animation clip currently playing.
var current_anim: String = ""

# True while an L1 emote is actively playing (used for the 45-degree camera turn).
var is_emoting: bool = false

# True after running horizontally; enables Bouncing Fight Idle until 5s timeout.
var has_moved_yet: bool = false

# Counts seconds of zero input while standing in Bouncing Fight Idle.
var idle_timer: float = 0.0

# True while a one-shot attack or emote animation is actively playing.
var is_playing_oneshot: bool = false

# True while knocked out by Slot 6 Ultimate.
var is_knocked_out: bool = false

# Current index (0 to 3) in the repeatable L1 emote cycle.
var emote_cycle_index: int = 0

# Default local offset for the bot mesh so its feet match the capsule floor.
var bot_local_transform: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0.0, -0.9, 0.0))

# --- SETUP & MODEL LOADING FUNCTIONS -----------------------------------------

# Captures any existing Y Bot placement in the scene and loads the archetype model.
# Parameters:
#   parent_fighter : The FighterBase CharacterBody3D node
#   archetype_id   : Lowercase archetype ID ("fighter", "rogue", "wizard", "ranger")
# Returns: Nothing (void)
func setup_for_archetype(parent_fighter: Node3D, archetype_id: String) -> void:
	# Check if a placeholder Y Bot or X Bot was placed in FighterBase.tscn in the editor.
	var editor_bot: Node3D = parent_fighter.get_node_or_null("Y Bot") as Node3D
	if editor_bot == null:
		editor_bot = parent_fighter.get_node_or_null("X Bot") as Node3D

	if editor_bot != null:
		bot_local_transform = editor_bot.transform
		editor_bot.queue_free()

	# Remove previously spawned runtime bot before spawning the new one.
	if active_bot_node != null:
		active_bot_node.queue_free()
		active_bot_node = null

	# Fighter and Rogue use Y Bot; Wizard and Ranger use X Bot.
	var clean_id: String = archetype_id.strip_edges().to_lower()
	var target_model_path: String = Y_BOT_PATH
	if clean_id == "wizard" or clean_id == "ranger":
		target_model_path = X_BOT_PATH

	if not ResourceLoader.exists(target_model_path):
		push_warning("[FighterAnimator] Model not found at: " + target_model_path)
		return

	var model_scene: PackedScene = load(target_model_path) as PackedScene
	if model_scene == null:
		return

	active_bot_node = model_scene.instantiate() as Node3D
	active_bot_node.name = "BotVisual"
	active_bot_node.transform = bot_local_transform
	add_child(active_bot_node)

	_attach_shared_animation_library()
	reset_to_initial_idle()

# Attaches the cached Mixamo AnimationLibrary to the bot's AnimationPlayer (building it once if needed).
# Parameters: None
# Returns: Nothing (void)
func _attach_shared_animation_library() -> void:
	if active_bot_node == null:
		return

	var found_players: Array[Node] = active_bot_node.find_children("*", "AnimationPlayer", true, false)
	if found_players.size() > 0:
		anim_player = found_players[0] as AnimationPlayer
	else:
		anim_player = AnimationPlayer.new()
		active_bot_node.add_child(anim_player)

	# Build the shared library only once on the very first fighter spawn.
	if _cached_shared_library == null:
		var anim_root: Node = anim_player.get_node(anim_player.root_node)
		var found_skeletons: Array[Node] = active_bot_node.find_children("*", "Skeleton3D", true, false)
		var target_skel_path: String = ""
		if anim_root != null and found_skeletons.size() > 0:
			target_skel_path = String(anim_root.get_path_to(found_skeletons[0]))
		_cached_shared_library = _build_shared_library_once(target_skel_path)

	# Replace default library with our shared static library.
	if anim_player.has_animation_library(""):
		anim_player.remove_animation_library("")
	anim_player.add_animation_library("", _cached_shared_library)

	if not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)

# Extracts all 15 Mixamo FBX animations from disk once and returns the shared AnimationLibrary.
# Parameters:
#   target_skel_path : Relative node path from AnimationPlayer root to Skeleton3D
# Returns: Populated AnimationLibrary resource
func _build_shared_library_once(target_skel_path: String) -> AnimationLibrary:
	var shared_lib: AnimationLibrary = AnimationLibrary.new()

	for anim_key: String in ANIM_FILES.keys():
		var fbx_path: String = MIXAMO_DIR + String(ANIM_FILES[anim_key])
		if not ResourceLoader.exists(fbx_path):
			push_warning("[FighterAnimator] Missing animation FBX: " + fbx_path)
			continue

		var packed_fbx: PackedScene = load(fbx_path) as PackedScene
		if packed_fbx == null:
			continue

		var temp_instance: Node = packed_fbx.instantiate()
		var src_players: Array[Node] = temp_instance.find_children("*", "AnimationPlayer", true, false)

		if src_players.size() > 0:
			var src_player: AnimationPlayer = src_players[0] as AnimationPlayer
			var extracted_anim: Animation = _extract_best_animation(src_player, target_skel_path)
			if extracted_anim != null:
				if anim_key in LOOPING_ANIMS:
					extracted_anim.loop_mode = Animation.LOOP_LINEAR
				else:
					extracted_anim.loop_mode = Animation.LOOP_NONE
				shared_lib.add_animation(anim_key, extracted_anim)

		temp_instance.free()

	return shared_lib

# Finds the primary animation inside an imported FBX AnimationPlayer and retargets its skeleton path.
# Parameters:
#   src_player	   : The temporary FBX scene's AnimationPlayer
#   target_skel_path : Relative node path to the character's Skeleton3D
# Returns: A duplicated and cleaned Animation resource
func _extract_best_animation(src_player: AnimationPlayer, target_skel_path: String) -> Animation:
	var best_anim: Animation = null
	var best_length: float = -1.0

	for anim_name: StringName in src_player.get_animation_list():
		if String(anim_name).to_upper() == "RESET":
			continue
		var candidate: Animation = src_player.get_animation(anim_name)
		if candidate != null and candidate.length > best_length:
			best_anim = candidate
			best_length = candidate.length

	if best_anim == null:
		return null

	var copy_anim: Animation = best_anim.duplicate(true) as Animation

	# Align skeleton path and strip horizontal X/Z root drift on Hips so capsule stays aligned.
	for i: int in range(copy_anim.get_track_count()):
		var track_path: NodePath = copy_anim.track_get_path(i)
		var subnames: String = track_path.get_concatenated_subnames()

		if target_skel_path != "" and subnames != "":
			copy_anim.track_set_path(i, NodePath(target_skel_path + ":" + subnames))

		if subnames.ends_with("Hips") and copy_anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
			var key_count: int = copy_anim.track_get_key_count(i)
			for k: int in range(key_count):
				var pos: Vector3 = copy_anim.track_get_key_value(i, k)
				pos.x = 0.0
				pos.z = 0.0
				copy_anim.track_set_key_value(i, k, pos)

	return copy_anim

# --- PER-FRAME LOCOMOTION & STATE UPDATES ------------------------------------

# Updates facing rotation and selects the right locomotion or idle animation every frame.
# Parameters:
#   delta			: Frame timestep in seconds
#   is_grounded	  : True when CharacterBody3D is on the floor
#   velocity		 : Current 3D velocity vector of the fighter
#   is_blocking	  : True while holding L2 Block
#   facing_direction : -1.0 for Left, +1.0 for Right
#   has_any_input	: True if any movement, jump, block, or action input was pressed
# Returns: Nothing (void)
func update_locomotion(
	delta: float,
	is_grounded: bool,
	velocity: Vector3,
	is_blocking: bool,
	facing_direction: float,
	has_any_input: bool
) -> void:
	if active_bot_node == null or anim_player == null:
		return

	# Turn 45 degrees toward the camera (+Z) during emotes; otherwise face Left (-90) or Right (+90).
	var target_yaw: float = 0.0
	if is_emoting:
		target_yaw = YAW_EMOTE_RIGHT if facing_direction >= 0.0 else YAW_EMOTE_LEFT
	else:
		target_yaw = YAW_RIGHT if facing_direction >= 0.0 else YAW_LEFT

	active_bot_node.rotation.y = lerp_angle(active_bot_node.rotation.y, target_yaw, minf(1.0, delta * 18.0))

	# Stay on the ground if knocked out by Slot 6 until respawned.
	if is_knocked_out:
		return

	# Keep the 5-second fight idle countdown at 0 whenever inputs, movement, or air states occur.
	var is_moving_horizontally: bool = absf(velocity.x) > 0.1
	if has_any_input or is_moving_horizontally or not is_grounded:
		idle_timer = 0.0

	# Hold Block animation whenever L2 is held (interrupts emotes/idles).
	if is_blocking:
		is_playing_oneshot = false
		is_emoting = false
		_play_clip("block", 0.1)
		return

	# Let active combat attacks finish; allow running or jumping to cancel an active emote.
	if is_playing_oneshot:
		if is_emoting and (is_moving_horizontally or not is_grounded):
			is_playing_oneshot = false
			is_emoting = false
		else:
			return

	# Airborne states: Jumping Up while rising, Falling Idle after peak jump or off a ledge.
	if not is_grounded:
		if velocity.y > 0.1:
			_play_clip("jump_up", 0.1)
		else:
			_play_clip("fall_idle", 0.15)
		return

	# Grounded moving state: Play Running animation and unlock Bouncing Fight Idle afterward.
	if is_moving_horizontally:
		has_moved_yet = true
		idle_timer = 0.0
		_play_clip("run", 0.12)
		return

	# Grounded idle state: Bouncing Fight Idle after running, reverting to Idle after 5s.
	if has_moved_yet:
		idle_timer += delta
		if idle_timer >= FIGHT_IDLE_TIMEOUT:
			has_moved_yet = false
			idle_timer = 0.0
			_play_clip("idle", 0.25)
		else:
			_play_clip("fight_idle", 0.2)
	else:
		_play_clip("idle", 0.2)

# --- ACTION & EMOTE TRIGGER FUNCTIONS ----------------------------------------

# Plays the Jumping Up animation immediately when jump starts without forcing fight idle.
# Parameters: None
# Returns: Nothing (void)
func trigger_jump_start() -> void:
	if is_knocked_out:
		return
	idle_timer = 0.0
	is_playing_oneshot = false
	is_emoting = false
	_play_clip("jump_up", 0.08)

# Triggers combat animations for Slots 1, 2, 3, 5, and 6 (KO) without forcing fight idle.
# Parameters:
#   slot_number : Ability slot number (1 through 6)
# Returns: Nothing (void)
func trigger_combat_slot(slot_number: int) -> void:
	if is_knocked_out:
		return

	idle_timer = 0.0
	is_emoting = false

	match slot_number:
		1:
			is_playing_oneshot = true
			_play_clip("slot_1", 0.06, true)
		2:
			is_playing_oneshot = true
			_play_clip("slot_2", 0.06, true)
		3:
			is_playing_oneshot = true
			_play_clip("slot_3", 0.06, true)
		5:
			is_playing_oneshot = true
			_play_clip("slot_5", 0.06, true)
		6:
			is_knocked_out = true
			is_playing_oneshot = false
			_play_clip("slot_6_ko", 0.1, true)

# Cycles sequentially through Taunt -> Pray -> Text -> Dancing Twerk on L1 press.
# Skips the initial fight-idle windup on emote_0 (Taunt) using TAUNT_START_OFFSET.
# Parameters: None
# Returns: The name of the emote triggered
func trigger_next_emote() -> String:
	if is_knocked_out:
		return "KO"

	idle_timer = 0.0
	is_playing_oneshot = true
	is_emoting = true

	var emote_key: String = "emote_" + str(emote_cycle_index)
	var label: String = EMOTE_LABELS[emote_cycle_index]
	var start_offset: float = TAUNT_START_OFFSET if emote_cycle_index == 0 else 0.0

	emote_cycle_index = (emote_cycle_index + 1) % 4
	_play_clip(emote_key, 0.12, true, start_offset)
	return label

# Resets the fighter back to initial Idle (and clears KO state on respawn or wakeup).
# Parameters: None
# Returns: Nothing (void)
func reset_to_initial_idle() -> void:
	is_knocked_out = false
	is_playing_oneshot = false
	is_emoting = false
	has_moved_yet = false
	idle_timer = 0.0
	_play_clip("idle", 0.1, true)

# --- INTERNAL ANIMATION PLAYBACK HELPERS -------------------------------------

# Plays an animation clip by key with smooth blending and optional start time seek.
# Parameters:
#   anim_key	  : Target clip name in the AnimationLibrary
#   blend_time	: Crossfade duration in seconds
#   force_restart : If true, restarts the clip even if already active
#   start_offset  : Time in seconds to seek into the clip immediately on start
# Returns: Nothing (void)
func _play_clip(
	anim_key: String,
	blend_time: float = 0.15,
	force_restart: bool = false,
	start_offset: float = 0.0
) -> void:
	if anim_player == null or not anim_player.has_animation(anim_key):
		return

	if current_anim == anim_key and not force_restart and anim_player.is_playing():
		return

	current_anim = anim_key
	anim_player.play(anim_key, blend_time)
	if start_offset > 0.0:
		anim_player.seek(start_offset, true)

# Clears the one-shot lock when an attack finishes, or returns to initial Idle after an emote.
# Parameters:
#   anim_name : Name of the animation that finished
# Returns: Nothing (void)
func _on_animation_finished(anim_name: StringName) -> void:
	if String(anim_name).begins_with("emote_"):
		is_playing_oneshot = false
		is_emoting = false
		has_moved_yet = false
		idle_timer = 0.0
		_play_clip("idle", 0.2)
	elif is_playing_oneshot:
		is_playing_oneshot = false