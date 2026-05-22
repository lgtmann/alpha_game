# alpha_game — Claude Code context

DotR/Inscryption/Mewgenics-inspired 2D tile-based card game in **Godot 4.6.2** (GDScript).

## Quick orientation

| Layer | What it does |
|---|---|
| **Overworld** | Pokemon/Stardew-style top-down walk (WASD). NPCs trigger battles. |
| **Combat** | Hex-grid turn-based. Play cards, move & attack units, defeat enemy leader to win. |
| **Meta / Run** | Roguelike run — RunState persists inventory, deck, tech, hero upgrades across encounters. |

## Godot path (this machine)

```
C:\Users\tomte\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe
```

Use `_console.exe` — the plain `.exe` is GUI-only and won't print diagnostics.

## Self-test loop (run after EVERY code change)

```
# 1. Class-scan (required when adding a new class_name)
<godot_console> --path <project> --editor --headless --quit 2>&1

# 2. Parse check
<godot_console> --path <project> --headless --quit 2>&1

# 3. Smoke test
<godot_console> --path <project> --headless --quit-after 120 2>&1
```

Clean output = only the engine banner. Any `SCRIPT ERROR:` / `Parse Error:` / `ERROR:` line is a real failure — fix before reporting done.  
**Never delete** `.godot/global_script_class_cache.cfg`. If a new `class_name` isn't found, run step 1 (`--editor`) to rescan.

## Scene entry point

`project.godot → res://scenes/game_root.tscn`

```
GameRoot (Node, game_root.gd)
├── BattleLayer (CanvasLayer, layer=10)   ← immune to Camera2D transforms
│   └── Main (instance of main.tscn)
└── OverworldLayer (Node2D)
    └── Overworld (instance of overworld.tscn)
```

`game_root.gd` controls visibility toggling: only one layer is visible at a time.

## Key scripts

| File | Class | Role |
|---|---|---|
| `scripts/game_root.gd` | *(no class_name)* | Scene switcher: overworld ↔ battle |
| `scripts/main.gd` | *(no class_name)* | Battle orchestrator; exposes `setup_run()`, `begin_battle(enc)`, signal `returned_to_overworld` |
| `scripts/game_state.gd` | `GameState` | Turn loop, energy, deck, combat resolution, win condition |
| `scripts/board.gd` | `Board` | Hex grid, unit placement, highlights, drag, live cursor facing |
| `scripts/run_state.gd` | `RunState` | Meta-progression: deck, inventory, shards, tech, hero sides, loadout |
| `scripts/overworld.gd` | `Overworld` | Tile map (30×22), WASD movement, NPC interaction → `battle_requested` signal |
| `scripts/overworld_player.gd` | `OverworldPlayer` | Grid-tile player, Camera2D child (zoom 2×), tween movement |
| `scripts/overworld_npc.gd` | `OverworldNpc` | NPC circle; `mark_defeated()` grays it out |
| `scripts/reward_screen.gd` | `RewardScreen` | Post-battle overlay: tribute cards, tech, workshop, leader editor |
| `scripts/enemy_ai.gd` | `EnemyAI` | Greedy attack/approach AI; plays cards from enemy hand |

## Hex grid

- **Pointy-top**, odd-r offset coordinates (`Vector2i(col, row)`)
- Directions: 0=E 1=SE 2=SW 3=W 4=NW 5=NE (matching unit `facing` int 0-5)
- `board.hex_distance()`, `board.neighbors()`, `board.reachable_tiles()`, `board.reachable_tiles_with_accelerators()`
- `board._tick_cursor_facing()` runs every frame: selected unit's facing follows the mouse cursor live

## Unit sides (SideUpgrade)

Each unit has 6 sides (Array[SideUpgrade]), indexed 0–5 relative to its facing.  
Types: `NONE / SHIELD / CANNON / ACCELERATOR`  
- **CANNON** adds ATK bonus when attacking from that side  
- **SHIELD** subtracts from incoming damage on that side  
- **ACCELERATOR** extends movement range in that world direction  

Hero sides are editable in the Leader Editor (reward screen).

## Combat flow

1. Player clicks a unit → facing arrow tracks cursor, move highlights appear
2. Left-click a tile → move; right-click an enemy → attack
3. Attacker always strikes from side 0 (faces target). Defender's hit side = `(dir_toward_attacker − facing + 6) % 6`
4. Counter-attack fires if defender is within their attack range
5. Leader death → `game_ended(winner)` signal → reward screen

## Cards

`CardData` resource: `card_name`, `cost`, `effect: CardEffect`, `single_use`  
Effects: `SpawnUnitEffect`, `SetTerrainEffect`, `WeaponEffect`, `FireballEffect`, `WildfireEffect`, `BlessEffect`, `QuickStrikeEffect`, `ArrowEffect`, `BoltEffect`  

`CardEffect.apply(board, tile)` keeps `board` **untyped** to avoid a class-name circular dependency. Subclasses cast: `var u: Unit = board.add_unit(...)`.

## Run / meta loop

- `RunState` nodes: `player_deck`, `inventory`, `shards`, `tech_points`, `unlocked_techs`, `hero_sides`, `first_mate`, `priority_cargo`, `hand_size_bonus`, `energy_bonus`
- Shards: 3 shards of a unit's card → it's added to your deck permanently
- Tech tree: Economy branch (extra_draw → energy_surge → bigger_hand) and Combat branch (sharpened_blades → reinforced_armor → terrain_mastery)
- `first_mate` (unit card) and `priority_cargo` (spell/weapon card) are pre-placed in opening hand each battle

## Overworld map

30 × 22 tiles, `TILE_SIZE = 48`. Tile types: GRASS / PATH / TREE (impassable) / WATER (impassable).  
NPC positions (encounter order):  
- enc0 Dark Lord — (11, 17)  
- enc1 Forest Warden — (11, 14)  
- enc2 Sea Witch — (25, 8)  
- enc3 Stone Lord — (4, 6)  
- enc4 Champion — (11, 3)  
Player starts at (11, 19). Walking into an NPC tile triggers `battle_requested(enc_idx)`.

## Common gotchas

- **New `class_name`?** Must run `--editor --headless --quit` first or headless parse won't find it.
- **Camera2D bleeds into battle UI?** `BattleLayer` is a `CanvasLayer (layer=10, follow_viewport=false)` — this is intentional, don't change it to Control.
- **`CardEffect.apply` board param is untyped** — don't add a type annotation; it causes a circular class-name dependency.
- **`_begin_new_run()` is gone** — use `setup_run()` (no auto-start) + `begin_battle(enc)` separately.
- **AI movement** uses `board.reachable_tiles(tile, speed)` directly; player movement uses `board.reachable_tiles_with_accelerators(unit)`.
