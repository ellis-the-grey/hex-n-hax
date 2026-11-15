extends Node
## ============================================================================
## InputLoader.gd (JSON Control Scheme Loader)
## ============================================================================
## WHAT THIS SCRIPT DOES:
##   Reads default and custom control layouts from res://config/controls/*.json
##   at startup and registers them into Godot's native InputMap.
##   Also includes a temporary hardware bridge so Controller Create (Back)
##   triggers Keyboard F1 and Controller Options (Start) triggers Keyboard F2.
##
## CONNECTS TO:
##   - Reads from: res://config/controls/*.json
##   - Feeds into: Godot's global InputMap (used by FighterBase.gd)
## ============================================================================

# --- CONFIGURATION FILE PATHS ------------------------------------------------

# File path to the default gamepad controls.
const DEFAULT_CONTROLLER_PATH: String = "res://config/controls/controls_default_controller.json"

# File path to custom gamepad overrides.
const CUSTOM_CONTROLLER_PATH: String = "res://config/controls/controls_custom_controller.json"

# File path to the default Mouse & Keyboard controls.
const DEFAULT_MNK_PATH: String = "res://config/controls/controls_default_mnk.json"

# File path to custom Mouse & Keyboard overrides.
const CUSTOM_MNK_PATH: String = "res://config/controls/controls_custom_mnk.json"

# --- NATIVE GODOT HARDWARE LOOKUP TABLES -------------------------------------

# Maps JSON gamepad button names to Godot button constants.
const JOY_BUTTON_MAP: Dictionary = {
	"JOY_BUTTON_A": JOY_BUTTON_A,
	"JOY_BUTTON_B": JOY_BUTTON_B,
	"JOY_BUTTON_X": JOY_BUTTON_X,
	"JOY_BUTTON_Y": JOY_BUTTON_Y,
	"JOY_BUTTON_BACK": JOY_BUTTON_BACK,
	"JOY_BUTTON_GUIDE": JOY_BUTTON_GUIDE,
	"JOY_BUTTON_START": JOY_BUTTON_START,
	"JOY_BUTTON_LEFT_STICK": JOY_BUTTON_LEFT_STICK,
	"JOY_BUTTON_RIGHT_STICK": JOY_BUTTON_RIGHT_STICK,
	"JOY_BUTTON_LEFT_SHOULDER": JOY_BUTTON_LEFT_SHOULDER,
	"JOY_BUTTON_RIGHT_SHOULDER": JOY_BUTTON_RIGHT_SHOULDER,
	"JOY_BUTTON_DPAD_UP": JOY_BUTTON_DPAD_UP,
	"JOY_BUTTON_DPAD_DOWN": JOY_BUTTON_DPAD_DOWN,
	"JOY_BUTTON_DPAD_LEFT": JOY_BUTTON_DPAD_LEFT,
	"JOY_BUTTON_DPAD_RIGHT": JOY_BUTTON_DPAD_RIGHT
}

# Maps JSON analog stick and trigger names to Godot axis constants.
const JOY_AXIS_MAP: Dictionary = {
	"JOY_AXIS_LEFT_X": JOY_AXIS_LEFT_X,
	"JOY_AXIS_LEFT_Y": JOY_AXIS_LEFT_Y,
	"JOY_AXIS_RIGHT_X": JOY_AXIS_RIGHT_X,
	"JOY_AXIS_RIGHT_Y": JOY_AXIS_RIGHT_Y,
	"JOY_AXIS_TRIGGER_LEFT": JOY_AXIS_TRIGGER_LEFT,
	"JOY_AXIS_TRIGGER_RIGHT": JOY_AXIS_TRIGGER_RIGHT
}

# Maps JSON mouse button names to Godot mouse button constants.
const MOUSE_BUTTON_MAP: Dictionary = {
	"MOUSE_BUTTON_LEFT": MOUSE_BUTTON_LEFT,
	"MOUSE_BUTTON_RIGHT": MOUSE_BUTTON_RIGHT,
	"MOUSE_BUTTON_MIDDLE": MOUSE_BUTTON_MIDDLE,
	"MOUSE_BUTTON_XBUTTON1": MOUSE_BUTTON_XBUTTON1,
	"MOUSE_BUTTON_XBUTTON2": MOUSE_BUTTON_XBUTTON2
}

# --- LIFECYCLE FUNCTIONS -----------------------------------------------------

# Runs automatically on boot to load all control bindings.
# Parameters: None
# Returns: Nothing (void)
func _ready() -> void:
	reload_all_controls()

# Temporary event bridge: maps Controller Create -> F1 and Options -> F2.
# Parameters:
#   event : Incoming hardware input event
# Returns: Nothing (void)
func _input(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton):
		return

	var joy_btn: InputEventJoypadButton = event as InputEventJoypadButton
	if joy_btn.button_index == JOY_BUTTON_BACK:
		_inject_key_event(KEY_F1, joy_btn.pressed)
	elif joy_btn.button_index == JOY_BUTTON_START:
		_inject_key_event(KEY_F2, joy_btn.pressed)

# Synthesizes and dispatches a keyboard key event into Godot's input pipeline.
# Parameters:
#   target_key : Godot Key constant (KEY_F1 or KEY_F2)
#   is_pressed : True when button is pressed down, false when released
# Returns: Nothing (void)
func _inject_key_event(target_key: Key, is_pressed: bool) -> void:
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = target_key
	key_event.physical_keycode = target_key
	key_event.pressed = is_pressed
	Input.parse_input_event(key_event)

# --- PUBLIC FUNCTIONS --------------------------------------------------------

# Merges default and custom JSON files and applies them to Godot's InputMap.
# Parameters: None
# Returns: Nothing (void)
func reload_all_controls() -> void:
	# Load default controller settings and merge custom overrides on top.
	var controller_bindings: Dictionary = _load_json_dict(DEFAULT_CONTROLLER_PATH)
	var custom_controller: Dictionary = _load_json_dict(CUSTOM_CONTROLLER_PATH)
	controller_bindings.merge(custom_controller, true)

	# Load default Mouse & Keyboard settings and merge custom overrides on top.
	var mnk_bindings: Dictionary = _load_json_dict(DEFAULT_MNK_PATH)
	var custom_mnk: Dictionary = _load_json_dict(CUSTOM_MNK_PATH)
	mnk_bindings.merge(custom_mnk, true)

	# Apply gamepad bindings first (wiping old entries), then append keyboard/mouse bindings.
	_apply_bindings_to_input_map(controller_bindings, true)
	_apply_bindings_to_input_map(mnk_bindings, false)
	print("[InputLoader] Gamepad and Mouse/Keyboard controls loaded into InputMap.")

# --- INTERNAL HELPER FUNCTIONS -----------------------------------------------

# Reads a JSON file from disk and parses it into a Dictionary.
# Parameters:
#   file_path : Path to the .json file
# Returns:
#   Parsed Dictionary of action bindings, or {} if missing/empty.
func _load_json_dict(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_warning("[InputLoader] Control file not found: " + file_path)
		return {}

	var file_text: String = FileAccess.get_file_as_string(file_path)
	if file_text.strip_edges().is_empty():
		return {}

	var parsed_data: Variant = JSON.parse_string(file_text)
	if typeof(parsed_data) == TYPE_DICTIONARY:
		return parsed_data

	push_error("[InputLoader] JSON formatting error in file: " + file_path)
	return {}

# Registers every action and button binding from a Dictionary into Godot's InputMap.
# Parameters:
#   bindings_dict  : Dictionary of action_name -> button_string pairs
#   clear_existing : True to erase old events before adding new ones
# Returns: Nothing (void)
func _apply_bindings_to_input_map(bindings_dict: Dictionary, clear_existing: bool) -> void:
	for action_name: String in bindings_dict.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.2)
		elif clear_existing:
			InputMap.action_erase_events(action_name)

		var raw_binding: String = str(bindings_dict[action_name]).strip_edges()
		var input_event: InputEvent = _create_input_event_from_string(raw_binding)

		if input_event != null:
			InputMap.action_add_event(action_name, input_event)

# Converts a single JSON button/key text string into a Godot InputEvent object.
# Parameters:
#   binding_str : Raw string from JSON (e.g., "JOY_BUTTON_A", "KEY_SPACE")
# Returns:
#   Configured InputEvent object, or null if unrecognized.
func _create_input_event_from_string(binding_str: String) -> InputEvent:
	# Case 1: Analog stick or trigger axis (e.g., "JOY_AXIS_LEFT_X:-1.0")
	if binding_str.begins_with("JOY_AXIS_"):
		var parts: PackedStringArray = binding_str.split(":")
		var axis_name: String = parts[0]
		var axis_value: float = float(parts[1]) if parts.size() > 1 else 1.0

		if JOY_AXIS_MAP.has(axis_name):
			var axis_event := InputEventJoypadMotion.new()
			axis_event.axis = JOY_AXIS_MAP[axis_name]
			axis_event.axis_value = axis_value
			return axis_event

	# Case 2: Gamepad button (e.g., "JOY_BUTTON_A")
	elif binding_str.begins_with("JOY_BUTTON_"):
		if JOY_BUTTON_MAP.has(binding_str):
			var btn_event := InputEventJoypadButton.new()
			btn_event.button_index = JOY_BUTTON_MAP[binding_str]
			return btn_event

	# Case 3: Mouse button (e.g., "MOUSE_BUTTON_LEFT")
	elif binding_str.begins_with("MOUSE_BUTTON_"):
		if MOUSE_BUTTON_MAP.has(binding_str):
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = MOUSE_BUTTON_MAP[binding_str]
			return mouse_event

	# Case 4: Keyboard key (e.g., "KEY_SPACE")
	elif binding_str.begins_with("KEY_"):
		var clean_key_name: String = binding_str.trim_prefix("KEY_")
		var key_code: Key = OS.find_keycode_from_string(clean_key_name)
		if key_code != KEY_NONE:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = key_code
			return key_event

	push_warning("[InputLoader] Unrecognized button/key name in JSON: " + binding_str)
	return null
