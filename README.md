# SKULLRUN

A spooky 2D platformer made with **Godot 4.3**. You play a runaway skull that
escapes a haunted crypt. You run, jump, double jump, dash and wall jump through 10 levels,
collect soul gems, and face the Bone King at the end.

## Play it

1. Download Godot 4.3 or newer (the standard version, not .NET) from https://godotengine.org.
2. Open Godot, click **Import**, and pick this folder's `project.godot`.
3. Press **F5** (or the ▶ button) to play.

## Controls

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | A / D or ← / → | Left stick / D-pad |
| Jump (hold for higher) | Space, W, ↑ or Z | A |
| Double jump | Jump again in mid-air (from level 2) | A |
| Dash | Shift, X or K (from level 3) | X / RB |
| Wall jump | Jump at a wall, then jump again (from level 7) | A |
| Pause | Esc or P | Start |
| Restart level | R | Back |

## The levels

| # | Name | New idea |
|---|------|----------|
| 1 | The Crypt | Running, jumping, pits, spikes, wooden ledges, ghosts |
| 2 | Moonlit Graveyard | **Double jump**, skeletons to stomp, jump pads |
| 3 | Bone Caves | **Dash**, crumbling blocks, bats, moving platforms |
| 4 | The Ember Forge | Lava, rising platforms, springs over lava |
| 5 | Reaper's Gate | A mix of everything at medium difficulty |
| 6 | Frozen Catacombs | **Ice**: on it you can't jump, dash or turn |
| 7 | The Hollow Wells | **Wall jump**: climb shafts and wells |
| 8 | Glacier Tombs | Ice + wall jumps (icy walls are too slippery to grab) |
| 9 | The Ossuary | **Soul vents**: purple updrafts that lift you and refill your powers. **Wraiths**: little reapers that chase you through walls |
| 10 | Throne of Bones | **Boss**: the Bone King. Stomp his head 3 times! |

Each level should take about 2–4 minutes the first time through, and each has
checkpoints, hint signs and optional soul gems. Your progress and best times are saved.
The level timer starts when you first move, and right after a respawn you blink
for a moment while enemies can't hurt you.

### The Bone King (level 10)

He sleeps on his throne until you drop into the arena, then cycles through attacks:
walking at you, throwing arcs of bones, and charging. When a charge ends against a
wall he's dizzy for a couple of seconds, which is the best time to jump on his head. Each hit
makes him faster, and from the second phase he also leaps and slams the ground,
sending shockwaves along the floor (jump them). If you die, he resets to full health.

## Editing the game

* **Title-screen text**: change `GAME_TITLE`, `TAGLINE` and `DESCRIPTION` at the top
  of [`scripts/config.gd`](scripts/config.gd).
* **Colours**: also in `scripts/config.gd`, both the menu colours and the per-level themes.
* **Levels**: the levels are plain text files in [`levels/`](levels/). Read
  [`levels/README.md`](levels/README.md) to learn how to make new ones. To add
  level 11, create `levels/level_11.txt` and it shows up in the game automatically.
* **Controls**: `_setup_input()` in `scripts/game.gd`.
* **How the skull moves** (speed, jump height, dash): the constants at the top of `scripts/player.gd`.

## Project layout

```
project.godot          Godot project settings
scenes/                title screen, level select, level
scripts/config.gd      ← text and colours you'll want to edit
scripts/game.gd        progress, saving, scene changes, controls
scripts/level.gd       builds a level from its text file
scripts/player.gd      the skull
scripts/objects/       gems, checkpoints, enemies, platforms, hazards…
scripts/ui/            menus and the in-game HUD
levels/                level_01.txt … level_10.txt
assets/fonts/          Creepster (title) and Rubik (text), both free OFL fonts
```

All graphics and sounds are drawn or generated in code, so the game has no image or audio files.

## Exporting (e.g. for the web)

When you export with **Project → Export**, open the **Resources** tab of your
preset. In "Filters to export non-resource files", enter `levels/*.txt`. Without
it, the level files are left out of the exported game.

## More ideas for later levels

* **The Reaper chase**: the Grim Reaper slowly sweeps in from the left, so you can't dawdle.
* **Keys and bone doors**: grab a key to open a gate somewhere else in the level.
* **Flip-gravity zones** where the skull runs on the ceiling.
* **Collapsing floors** that crumble one after another behind you as you run.
* **More bosses** every 10 levels (the Bone King's code in `scripts/objects/bone_king.gd` is a good starting point).
* **Skins**: unlock new skull colours (gold, crystal, flaming) by collecting every gem.
* **Swamps** that slow you down, and **switches** that flip platforms on and off.
* **Time-trial medals** (bronze, silver, gold) for each level's best time.
* **Music**: a spooky chiptune loop per theme.
