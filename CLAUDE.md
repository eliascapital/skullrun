# SKULLRUN — notes for Claude

A Godot 4.3 platformer about a cursed skull escaping the Reaper. 25 levels, two bosses,
playable in the browser (also on phones). Levels are text files in `levels/` (format in
`levels/README.md`). The website (`website/`) is published to GitHub Pages by
`.github/workflows/website.yml` on every push to `main`.

The owner merges pull requests themselves; changes land on `main` through PRs. The players
are kids, so in-game text, hint signs and the website use short, friendly words.

## Keep the website in sync

The owner wants the website to grow with the game, with no empty placeholder slots.

- **New level:** give the level file an `about:` line. The website's level list and level
  count are generated from the level files at build time (`website/gen_levels.py`),
  so nothing else is needed. A new theme also needs its colour in `THEME_COLORS` there,
  and a new boss character needs adding to its boss detection (it looks for `K` and `L`).
- **New power/ability:** add a card to the `#powers` section of `website/index.html`
  (icon, name, one-line description, the level it unlocks in), and add it to the
  controls section and the in-game How to Play panel (`scripts/ui/title_screen.gd`) if it has a key.
- **New mechanic or hazard:** add a pill to "Strange places" in `#powers`.
- **New enemy or boss:** add a card to `#enemies` with a picture rendered from the
  game's own drawing code, cropped and saved as `website/img/e_<name>.webp`.
  Give drawing code a `static func draw_<name>(ci: CanvasItem, ...)` so it can be reused
  for that picture (see `reaper.gd`, `lich.gd`). The enemy grid is 4 columns (2 on phones):
  keep the rows full, or the last row has a hole. Cards with class `wide` (the Reaper and
  both bosses) fill 2 columns, so count them as 2 (it's 12 now: 6 small + 3 wide).
- **New world/theme:** consider adding a screenshot to the gallery (`website/img/<name>.webp`,
  1280×720 in-game capture with the HUD). The gallery is 3 wide: add shots in threes.
- Also update the level table in `README.md`, and hint signs that name keys should
  mention the touch controls too ("SPACE (or the jump button)").

## How the game is put together

Everything is drawn in code with `_draw()` (no sprite art), and sounds are generated in
code (`scripts/sfx.gd`, `Sfx.play("name", pitch)`). Autoloads: `Config` (colours, themes,
title text), `Game` (level list, save file, scene changes, input map, phone zoom), `Sfx`.

- `scripts/level.gd` builds a level from its text file: `level_data.gd` parses it (blocks
  are placed left to right, bottom-aligned, min height 20), `tile_chunk.gd` draws tiles in
  16-column slices, solid tiles are merged into as few collision rectangles as possible,
  then every map character becomes an object in `_build_objects()`. It also wires up warp
  pairs, the Reaper, the boss, the HUD and the touch controls.
- `scripts/player.gd` is the skull: movement, powers, death/respawn, warping, drawing.
- `scripts/objects/` one file per thing (enemies, hazards, platforms, bosses, projectiles).
- `scripts/ui/` HUD, title screen (and How to Play panel), level select, story intro,
  touch controls, `ui.gd` (button/label/panel helpers in the game's style).
- Save file: `user://skullrun_save.cfg` — `[progress]` (unlocked, best times/gems, seen_intro)
  and `[settings] touch_layout`. `Game.save_progress()` writes both.

### Player numbers (1 tile = 32 px)
Jump ≈ 4 tiles (plan for 3), + double jump ≈ 7 (plan for 6), dash+double clears 9–10 tiles.
Physics runs at 60 ticks with **physics interpolation on**: after teleporting anything
(respawn, warp, boss teleport) call `reset_physics_interpolation()`, and
`camera.reset_smoothing()` for the player.

Wall jumps: you can't kick off the same side twice without landing. Kicking back and forth
up a shaft refills double jump and dash; a kick off a *lone* wall uses up the double jump
instead (or is a half-strength hop if it's gone), so one wall never gets you higher than a
double jump (~7.5 tiles). Walls with any ice beside the body can't be grabbed.
Walls 10+ tiles tall are used in levels as "can't climb this".

### Map characters added in levels 16–20
- `a`–`h` warp portals (exactly two of a letter). The player shrinks into the portal,
  reappears at its twin with the same velocity, and the camera glides over (offset tween).
  The arriving portal ignores the player for a moment so they don't bounce back.
- `F` flame jet: fires up from floors / down from ceilings, 9 tiles (taller than a double
  jump) or until the first solid tile (`level._flame_length`); every jet in a
  level shares one 3-second rhythm (glows at 1.6 s, fires 2.0–3.0 s).
- `Y` / `Z` the Reaper chase (`reaper.gd`): past column Y he chases through walls at 150 px/s
  (player runs 250), catching up fast if more than ~14 tiles behind (less on zoomed phones,
  so he stays visible); stop for ~2.5 s and he catches you. At column Z he teleports next to
  the skull, freezes it, says "I will let <boss> deal with you", and is gone for good.
  Only put run-forward obstacles between Y and Z (no waiting puzzles, no backtracking).
- `L` Mortis the Lich (`lich.gd`): arena = space between the walls left/right of `L` on its
  row. Floats, casts soul bolts / soul rain, teleports from round 2, then sinks "drained"
  (always to a spot with nothing overhead) to be stomped. 3 hits. `K` is the Bone King.
  Each boss has `BOSS_NAME`; the level keeps `boss_name`; the exit stays hidden until the
  boss is beaten; on player respawn the boss resets.

### Map characters added in levels 21–25
- `Q` witch (`witch.gd`, drawing in `draw_witch`): hovers on a broom, throws a potion
  (`potion.gd`, smiley face in `draw_potion`) every 2.6 s when the skull is within 12×8 tiles,
  aimed to land where the skull is now, so it misses a skull that keeps moving. It explodes on
  ground, walls or the skull (blast radius 46 px). She won't throw at a skull within 3 tiles
  (the potion would pop out inside it as it stomps her). Stomp or slam to defeat her; she
  comes back when the skull respawns (`reset`), so level 25 uses witches over magma pits as
  trampolines (bounce + double jump up cliffs too tall to double jump). Her hitbox
  spans about 1.5 tiles under her centre, so place her with two empty rows above the ground.
  Never put witches where players must stand still (jet waits, moving platforms).
- `m` hidden magma (`magma_block.gd`): solid like `#` and drawn as a plain block by the tile
  slices; each block fades in a glow when the skull is within 6 tiles (full at 3) and kills on
  touch. Single jumps over patches wider than 3 get tight, so keep jumped patches ≤ 3 wide.

### Touch screens and phones
- `touch_controls.gd`: joystick + jump + dash + pause, pressing the normal input actions
  (`Input.action_press`). Shown only on touch screens; hidden when a key/gamepad is used.
  A touch goes to whichever of joystick/jump is nearer (so swapped layouts work).
  Pause menu → MOVE TOUCH BUTTONS lets players drag them; positions are saved in
  `Game.touch_layout` as offsets from each control's screen corner (`CORNERS`).
- Menus are tapped through Godot's touch → mouse emulation. HUD buttons that sit in the
  play area must be excluded from the joystick (`touch.is_blocked = hud.covers_point`).
- HUD buttons in levels must use `focus_mode = FOCUS_NONE`, or SPACE (jump) presses them.
- Phones held sideways are short, so `Game.phone_zoom()` zooms the level camera in
  (≈1.33× at 390 CSS px tall, 1.0 on iPads/computers). Menus are not scaled — the How to
  Play panel already nearly fills a 540 px tall screen.
- Upright screens (taller than wide) switch the window to the "keep" aspect, so they show
  the normal 960×540 view with bars instead of a huge tall slice (`Game._fit_to_screen`).
- Website-only: `website/play/fullscreen.js` (loaded via the Web export's `head_include`
  in `export_presets.cfg`) adds a full-screen button on touch devices, top-left under the
  level name (iPhones can't go full screen; it shows "Add to Home Screen" instead), and on
  phones held upright covers the game with "Turn your phone sideways". Web pages can't
  force the turn themselves.

## Website build
`website/build.sh [godot]` exports the game to `build/play/`, renames the `.pck` by content
hash (`cache_bust.py`, so browsers don't keep an old game), copies `website/`, and fills
in the level list (`gen_levels.py`). The workflow downloads Godot 4.3 + web templates.

## Testing (there is no test suite — run the game)
Godot isn't installed in the container. Download it into the scratchpad:
`https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip`.
Copy the project to the scratchpad (so `.godot/` and test files stay out of the repo), run
`godot --headless --path . --import` once (font errors on the first import are normal), and
add a test autoload script (`Tester="*res://tester.gd"` in the copy's `project.godot`) that
starts levels and drives the player.
- Screenshots: `xvfb-run -a -s "-screen 0 1400x900x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy`
  and `get_viewport().get_texture().get_image().save_png(...)`.
- Fast, deterministic bot runs: `godot --headless --fixed-fps 60 --path . --audio-driver Dummy`
  (no real-time waiting).
- Redirect output to a file; if the process is killed by `timeout`, piped output is lost.
- Fake input: `Input.action_press/_release`; hold a press for **two** physics frames or
  `is_action_just_pressed` never sees it. Touches: `Input.parse_input_event(InputEventScreenTouch…)`.
- `levels/README.md` jump limits are trustworthy for level design; a rough reachability
  check (P → E and gems, with warps, slams, shafts and moving platforms) catches broken gaps.

### GDScript / Godot 4.3 gotchas met so far
- `draw_circle()` has no width/outline argument in 4.3 (use `draw_arc` for rings).
- A self-intersecting polygon in `draw_colored_polygon` prints "triangulation failed" every frame.
- Calling a coroutine needs `await`; a lambda can't see a function's local `const`.
- `Camera2D.get_screen_center_position()` doesn't update until the camera's next update,
  even after `force_update_scroll()` — compute the target yourself when you need it now.

## Git
Develop on the session's `claude/...` branch and open PRs into `main`. If a PR from the
branch was already merged, restart the branch from `origin/main`. Force-pushes are blocked,
so bring `main` in with a normal merge instead of rebasing.
