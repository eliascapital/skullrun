# SKULLRUN

A spooky 2D platformer made with **Godot 4.3**. You play a runaway skull that
escapes a haunted crypt. You run, jump, double jump, dash, wall jump and ground slam through 25 levels,
collect soul gems, defeat the Bone King, and fall upward through the Abyss.

## Play it

1. Download Godot 4.3 or newer (the standard version, not .NET) from https://godotengine.org.
2. Open Godot, click **Import**, and pick this folder's `project.godot`.
3. Press **F5** (or the ▶ button) to play.

## Website

The game has a website where anyone can play it in their browser:
**https://eliascapital.github.io/skullrun/** (landing page) and
**https://eliascapital.github.io/skullrun/play/** (the game itself).

It rebuilds automatically every time something is pushed to `main`, using the
GitHub Actions workflow in `.github/workflows/website.yml`. The landing page lives in
[`website/`](website/) (plain HTML and CSS). `website/build.sh` builds everything
into `build/` if you want to try it on your own computer.

One-time setup: on GitHub open **Settings → Pages**, and under
**Build and deployment → Source** choose **GitHub Actions**.

## Controls

| Action | Keyboard | Gamepad | Touch screen |
|--------|----------|---------|--------------|
| Move | A / D or ← / → | Left stick / D-pad | Joystick (left thumb) |
| Jump (hold for higher) | Space, W, ↑ or Z | A | Jump button (right thumb) |
| Double jump | Jump again in mid-air (from level 2) | A | Jump button |
| Dash | Shift, X or K (from level 3) | X / RB | Dash button |
| Wall jump | Jump at a wall, then jump again (from level 7) | A | Jump button |
| Ground slam | S or ↓ while in the air (from level 12) | D-pad down | Joystick down in the air |
| Pause | Esc or P | Start | Pause button (top right) |
| Restart level | R | Back | Pause, then Restart Level |

The touch controls (`scripts/ui/touch_controls.gd`) only appear on touch screens,
and hide again when you use a keyboard or gamepad. To put them somewhere more
comfortable, pause and choose **MOVE TOUCH BUTTONS**, drag them around and tap DONE;
the layout is saved. On the website, phones and tablets also get a full screen button
(`website/play/fullscreen.js`), phones held upright are asked to turn sideways, and on
phones held sideways the level is zoomed in.

The **EXIT** button in the top-left corner of every level goes back to the main
menu (it asks first).

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
| 11 | The Upside Abyss | **Reverse-gravity zones**: fall up and walk on the ceiling |
| 12 | Shattered Depths | **Ground slam**: smash through cracked blocks and flatten enemies |
| 13 | Spitter Hollows | **Skull Spitters**: totems that spit fireballs along the ground |
| 14 | Topsy-Turvy Tombs | Gravity + slams + spitters, including slamming *up* through ceilings |
| 15 | Heart of the Abyss | Everything together, even upside-down ice |
| 16 | The Warp Gates | **Warp portals**: step into one, come out of its twin |
| 17 | The Soul Furnace | **Flame jets**: grates that blast fire in a steady rhythm |
| 18 | Halls of Echoes | Portals in the sky, wraiths, crumbling blocks and fire |
| 19 | Gates of the Keep | Everything at once: slams, wall jumps, portal chains, spitters |
| 20 | The Reaper's Tower | **The Reaper chases you!** Then the **boss**: Mortis the Lich |
| 21 | The Witch's Bog | **Witches**: they fly on brooms and throw smiley potions that explode. Keep moving, or stomp them |
| 22 | Ember Hollow | **Hidden magma**: blocks that look like stone until you get close, then glow. Touching one is deadly |
| 23 | Brewing Marsh | Witches and magma together, plus crumbling bridges and a ground slam |
| 24 | The Bubbling Cauldron | Magma, flame jets (too tall to jump over), portals and a magma lake |
| 25 | The Witches' Wood | Everything at once, and the Reaper chases you again |

The first time you press PLAY, a short story plays (a man walking to work, the
Reaper's army taking over the world, and a skull waking up in a sealed tomb).
Skip it with Space or Esc, or watch it again with the **STORY** button.

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
  level 16, create `levels/level_16.txt` and it shows up in the game automatically.
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
levels/                level_01.txt … level_25.txt
assets/fonts/          Creepster (title) and Rubik (text), both free OFL fonts
```

All graphics and sounds are drawn or generated in code, so the game has no image or audio files.

## Exporting

The project already has a **Web** export preset (`export_presets.cfg`) that includes
the level files. If you add another preset (for example Windows), open its
**Resources** tab and enter `levels/*.txt` in "Filters to export non-resource files",
otherwise the levels are left out of the exported game.

## More ideas for later levels

* **The Reaper chase**: the Grim Reaper slowly sweeps in from the left, so you can't dawdle.
* **Keys and bone doors**: grab a key to open a gate somewhere else in the level.
* **Collapsing floors** that crumble one after another behind you as you run.
* **More bosses** every 10 levels (the Bone King's code in `scripts/objects/bone_king.gd` is a good starting point).
* **Skins**: unlock new skull colours (gold, crystal, flaming) by collecting every gem.
* **Swamps** that slow you down, and **switches** that flip platforms on and off.
* **Time-trial medals** (bronze, silver, gold) for each level's best time.
* **Music**: a spooky chiptune loop per theme.
