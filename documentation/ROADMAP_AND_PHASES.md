\# Development Phases \& Scope



\## Phase 1: Vertical Slice Foundation (Current)

\* Set up modular folder structure, GitHub workflow, and plain-English documentation.

\* Build native JSON controller loader (`config/controls/`).

\* Implement `FighterBase.gd` (locked to `Z = 0`), basic block, and a single graybox stage (`TestArena.tscn`) with blast zones and ledges.

\* Wire up the 4 starter archetypes using identical baseline frame data for Slots 1–4, plus placeholder hooks for Slots 5 \& 6.



\## Phase 2: Steven's Balance \& Sandbox Playground

\* Launch in-game `DebugOverlay`, `HitboxVisualizer` (wireframe hitboxes/hurtboxes), and `BalanceDebugDeck` sliders.

\* Unlock Slots 5 (Special) and 6 (Ultimate) with modular projectile, buff, and area-of-effect templates.

\* Enable `TelemetryRecorder` to log damage, knockback distances, and match stats.



\## Phase 3: Combat Depth \& Rulesets

\* Experiment with hybrid HP vs. Smash percentage knockback formulas in `CombatRules.gd`.

\* Add Co-op team rules, friendly-fire toggles, and AI sparring bots.

\* Expand defensive mechanics (timed parries, directional air-dodges).



\## Phase 4: Online Multiplayer (`netcode/`)

\* Build and test host/join peer-to-peer lobbies in an isolated `netcode/` module so local sandbox work is never disrupted.

