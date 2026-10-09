# SKULLRUN

A spooky 2D platformer made with **Godot 4.3**. You play a runaway skull that
escapes a haunted crypt. You run, jump, double jump and dash through 5 levels
while collecting soul gems.

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
| Pause | Esc or P | Start |
| Restart level | R | Back |

## The levels

| # | Name | New idea |
|---|------|----------|
| 1 | The Crypt | Running, jumping, pits, spikes, wooden ledges, ghosts |
| 2 | Moonlit Graveyard | **Double jump**, skeletons to stomp, jump pads |
| 3 | Bone Caves | **Dash**, crumbling blocks, bats, moving platforms |
| 4 | The Ember Forge | Lava, rising platforms, springs over lava |
| 5 | Reaper's Gate | A mix of everything, kept at a medium difficulty so later levels have room to get harder |

Each level should take about 2–4 minutes the first time through, and each has
checkpoints, hint signs and optional soul gems. Your progress and best times are saved.

## Editing the game

* **Title-screen text**: change `GAME_TITLE`, `TAGLINE` and `DESCRIPTION` at the top
  of [`scripts/config.gd`](scripts/config.gd).
* **Colours**: also in `scripts/config.gd`, both the menu colours and the per-level themes.
* **Levels**: the levels are plain text files in [`levels/`](levels/). Read
  [`levels/README.md`](levels/README.md) to learn how to make new ones. To add
  level 6, create `levels/level_06.txt` and it shows up in the game automatically.
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
levels/                level_01.txt … level_05.txt
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
* **Wall jump** as a new power around level 10, for vertical tower levels.
* **Flip-gravity zones** where the skull runs on the ceiling.
* **Collapsing floors** that crumble one after another behind you as you run.
* **Boss levels** every 10 levels, like a giant skeleton king you stomp three times.
* **Skins**: unlock new skull colours (gold, crystal, flaming) by collecting every gem.
* **Ice crypts** with slippery floors, and **swamps** that slow you down.
* **Time-trial medals** (bronze, silver, gold) for each level's best time.
* **Music**: a spooky chiptune loop per theme.
