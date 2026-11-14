# hex-n-hax

A 2.5D dark-fantasy melee and magic arena fighter built in **Godot 4** (GDScript). Designed around a decoupled, data-driven architecture so combat tuning, weapon properties, and character abilities can be created and balanced directly in the Godot Inspector without touching core physics or UI code.

## Core Architecture

- **Signal-Driven & Decoupled:** Core combat physics (`FighterBase`) communicate with the HUD and match state strictly through the global `GameEvents` signal bus.
- **Inspector-First Tuning:** All fighter stats, weapon hitboxes, and ability frame data live in standalone `.tres` custom `Resource` files for rapid iteration and matchup balancing.
- **Built-in Telemetry:** Live hitbox/hurtbox overlays, damage logging, and frame-step debugging via `FrameTelemetry` and `BalanceDebugDeck`.

## Roster Archetypes

8 classic fantasy archetypes blending heavy melee, fast combo melee, and short-range sword-length magic:
- **Melee:** Warrior, Berserker, Rogue, Monk
- **Hybrid / Magic:** Ranger, Mage, Cleric, Bard

## Project Structure

```text
res://
├── autoload/
│   ├── GameEvents.gd          # Global signal bus (hit_landed, ability_used, stock_lost, match_ended)
│   └── InputBuffer.gd         # Controller/keyboard buffering & combo input window
├── core/
│   ├── MatchManager.gd        # Standalone state machine (Intro -> Fight -> SuddenDeath -> Results)
│   ├── CameraRig25D.gd        # Dynamic 2.5D framing & zoom based on fighter distance
│   └── FrameTelemetry.gd      # Live hitbox frame-data overlay, damage logs, & balance stats
├── fighters/
│   ├── FighterBase.gd         # Shared physics, knockback math, & state machine (reads .tres data)
│   ├── AbilityRunner.gd       # Executes modular ability & weapon behaviors on button press
│   ├── HurtboxComponent.gd    # Modular damage & knockback receiver
│   ├── HitboxComponent.gd     # Active frame windows, base damage, knockback angle/scaling
│   ├── resources/             # Custom Resource scripts defining Inspector knobs
│   │   ├── FighterStats.gd    # Speed, weight, jumps, gravity, hitstun multipliers
│   │   ├── WeaponData.gd      # Reach, swing speed, sweetspot damage, knockback scaling
│   │   └── AbilityData.gd     # Cooldown, resource cost, startup/active/recovery frames, VFX
│   ├── presets/               # Live Inspector tuning sandbox (.tres files)
│   │   ├── archetypes/        # warrior.tres, berserker.tres, rogue.tres, monk.tres, ranger.tres, mage.tres, cleric.tres, bard.tres
│   │   ├── weapons/           # greatsword.tres, daggers.tres, warhammer.tres, arcane_blade.tres, etc.
│   │   └── abilities/         # dash_strike.tres, frost_nova.tres, guard_break.tres, etc.
│   └── scenes/                # Visual meshes, animations, & sword-length magic VFX
├── stages/
│   ├── StageBase.gd           # Blast zones, spawn points, & ledge geometry
│   └── Arena_01.tscn
└── ui/
    ├── BattleHUD.gd           # Damage %, stock icons, match timer (listens to GameEvents)
    └── BalanceDebugDeck.gd    # Live in-game tuning sliders, hitbox toggle, & frame-step tools
