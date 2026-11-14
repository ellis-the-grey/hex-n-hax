\# Controller \& Input Mapping (`config/controls/`)



\## How Controls Work

Instead of hardcoding buttons, Hex-Hax reads JSON files from `res://config/controls/` at startup and maps them directly into Godot's native `InputMap`. Because Godot standardizes modern gamepads through SDL mappings, a single universal controller layout works out of the box across Xbox, DualShock 4, DualSense 5, Steam Input, and generic controllers.



\## Preset \& Custom Files

\* `controls\_default\_controller.json` — Standard baseline layout for all gamepads (Xbox, PS4/PS5, Steam, generic).

\* `controls\_custom\_controller.json` — Steven's editable gamepad overrides (takes priority over default when modified).

\* `controls\_default\_mnk.json` — Standard baseline layout for Mouse \& Keyboard.

\* `controls\_custom\_mnk.json` — Steven's editable Mouse \& Keyboard overrides (takes priority over default when modified).



\## Native Godot Naming Standard

All JSON values use Godot 4's built-in hardware constants directly (no translation layer):

\* \*\*Gamepad Buttons:\*\* `"JOY\_BUTTON\_A"`, `"JOY\_BUTTON\_B"`, `"JOY\_BUTTON\_X"`, `"JOY\_BUTTON\_Y"`, `"JOY\_BUTTON\_LEFT\_SHOULDER"`, `"JOY\_BUTTON\_RIGHT\_SHOULDER"`, `"JOY\_BUTTON\_DPAD\_UP"`

\* \*\*Gamepad Axes / Triggers:\*\* `"JOY\_AXIS\_LEFT\_X"`, `"JOY\_AXIS\_LEFT\_Y"`, `"JOY\_AXIS\_TRIGGER\_LEFT"`, `"JOY\_AXIS\_TRIGGER\_RIGHT"`

\* \*\*Keyboard \& Mouse:\*\* `"KEY\_W"`, `"KEY\_A"`, `"KEY\_S"`, `"KEY\_D"`, `"KEY\_SPACE"`, `"KEY\_J"`, `"KEY\_K"`, `"KEY\_L"`, `"MOUSE\_BUTTON\_LEFT"`, `"MOUSE\_BUTTON\_RIGHT"`



To customize controls, edit `controls\_custom\_controller.json` or `controls\_custom\_mnk.json` in any text editor and relaunch the game—the default files remain intact as safe backups.

