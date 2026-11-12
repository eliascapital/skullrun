# Making SKULLRUN levels

Every level is a plain text file in this folder. The game finds them on its own:
any file named `level_XX.txt` becomes a level, in alphabetical order. So to add
level 16, copy `level_15.txt` to `level_16.txt` and start editing (`level_10` and `level_20` are boss levels, so don't copy those). Use two digits
(`level_06`, `level_42`), or three if you ever go past 99 (`level_100` would sort
before `level_11`, so rename them all to `level_001` and so on).

## File layout

```
name: Moonlit Graveyard          <- shown on the level menu and HUD
theme: graveyard                 <- crypt, graveyard, bonecaves, forge, tower,
                                    frost, wells, ossuary, throne, abyss, keep,
                                    bog or cauldron
about: Double jump, skeletons     <- short description for the website's level list
abilities: jump double           <- any of: jump double dash wall slam (leave it out for all of them)
banner: NEW POWER: DOUBLE JUMP!  <- optional message shown at the start
sign1: Text for sign 1\nUse \n for a new line
sign2: ...
---                              <- everything below this line is the map
; a line starting with ; is a comment
........................................
.P...1..........o.o.o...................
########################################
########################################

........................................   <- a blank line starts a new block,
....................................E...      which is placed to the RIGHT of
########################################      the previous one
```

Blocks let you build a long level in readable pieces. They can be any width,
and different heights are fine too: shorter blocks get empty sky added on top so
that their bottoms line up.

## Map key

| Char | What it is |
|------|------------|
| `.`  | empty air (spaces work too) |
| `#`  | solid ground |
| `-`  | wooden ledge: you can jump up through it and stand on top |
| `X`  | crumbling block: falls apart shortly after you stand on it, then grows back |
| `I`  | ice: solid like ground, but on it you can't jump, dash or turn — you slide until you're off it. You can't wall jump off icy walls either |
| `^`  | spikes (deadly) |
| `v`  | hanging spikes, pointing down from a ceiling (deadly) |
| `H`  | cracked block: solid, but a ground slam smashes through it (and keeps going through a stack of them) |
| `:`  | reverse-gravity zone: fill an area with `:` and the skull falls UP inside it. One zone covers the bounding box of each connected patch of `:`, so gems or enemies inside are fine. Always let a zone touch a ceiling (`#` right above its top row), otherwise the skull bobs at the zone's top edge. Wooden ledges `-` don't hold you upside down, and checkpoints shouldn't go inside a zone |
| `~`  | lava / acid (deadly; colour comes from the theme) |
| `o`  | soul gem (collectible) |
| `P`  | player start (one per level) |
| `E`  | exit portal (one per level) |
| `C`  | checkpoint lantern |
| `G`  | ghost: floats 3 tiles left and right; can't be stomped |
| `B`  | bat: flies about 2.5 tiles up and down |
| `S`  | skeleton: walks back and forth; stomp it from above |
| `T`  | skull spitter: a totem that spits fireballs along its row when you're within 14 tiles. Jump the fireballs; stomp it or slam near it to smash it. Fireballs stop at walls, so a 1-tile post shields a checkpoint |
| `R`  | wraith: wakes up when you come within ~7 tiles and drifts after you, straight through walls. Slower than you, can't be stomped, goes home if you get 12 tiles away or respawn. Keep it 12+ tiles from checkpoints |
| `J`  | jump pad: launches you about 8 tiles up |
| `W`  | soul vent: a column of purple wind that lifts you up to 10 tiles (until it hits a ceiling). Riding it refills your double jump and dash. Put one at the very bottom of a pit to catch falling players |
| `K`  | the Bone King boss (one per level). The exit `E` stays hidden until he's defeated. Give him a flat arena with a wall at each end — he gets dizzy when he charges into a wall |
| `L`  | Mortis the Lich boss (one boss per level). Put him on the floor of an arena with a wall at each end (the arena is the space between those walls). He floats around casting spells, then sinks to the floor, drained, for you to stomp. The exit `E` stays hidden until he's defeated |
| `a`–`h` | warp portals. Put exactly two of the same letter in a level: walking (or jumping) into one pops you out of the other, still moving the way you were going. Each letter has its own colour. A portal can float in the air too |
| `F`  | flame jet: a grate that blasts fire every 3 seconds (it glows just before). On a floor it fires up, under a ceiling it fires down. The fire is 9 tiles tall (too tall to double jump over) or stops at the first solid tile. A row like `FF` is one wide jet. Every jet in a level fires at the same time, so leave a safe spot to wait between jets |
| `Y`, `Z` | the Reaper's chase: once you pass the `Y` column the Reaper appears behind you and chases you (a bit slower than you run, straight through walls). At the `Z` column he teleports next to you, says his piece about the level's boss, and leaves. Only run-forward obstacles in between, since you can't stop for long |
| `Q`  | witch: hovers on her broom and throws smiley-face potions that explode where they land (aimed at where you are, so they miss if you keep moving). Stomp her, or slam near her: stomping bounces you up and gives back your double jump, so a witch over a pit makes a trampoline. Stomped witches come back when you respawn. Leave two empty rows between her and the ground so the skull can walk underneath (and jump onto her), and keep her 13+ tiles from checkpoints and away from spots where players must wait |
| `m`  | hidden magma: looks exactly like `#` until the skull comes within about 6 tiles, then glows (fully at 3 tiles). Touching it kills straight away. It's solid, so skeletons can walk on it. Keep patches 3 wide or less where players have to jump them |
| `M`  | moving platform (left/right). A row like `MMM` is one 3-wide platform; it moves 4 tiles right and back |
| `V`  | moving platform (up/down). Moves 4 tiles up from where you draw it, and back |
| `1`–`9` | hint sign that shows the matching `signN:` text |

Put things that stand on the ground (`P`, `E`, `C`, `S`, `J`, signs) in the row
directly above a `#`. Lava `~` usually goes in the top ground row, with `#` underneath it.

## How far can the skull jump? (1 tile = 1 character)

| Move | Height | Gap it can clear |
|------|--------|------------------|
| Jump | about 4 tiles (plan for 3) | 4 tiles |
| Jump + double jump | about 7 tiles (plan for 6) | 6–7 tiles |
| Jump + double jump + dash | about 7 tiles | 9–10 tiles |
| Jump pad | about 8 tiles | n/a |
| Wall jump | climb any height between two stone walls 3–6 tiles apart | n/a |
| Ground slam | drills down through any number of cracked `H` blocks | n/a |

A single wall can't be climbed by itself: you can't kick off the same side twice in a
row without landing, and a kick off a lone wall uses up your double jump (or is only a
small hop if that's already gone), so one wall never gets you higher than a double jump.
Kicking back and forth between two walls gives your double jump and dash back, so a
wall-jump climb needs two walls facing each other. Walls with any ice on them can't be grabbed. A nice way to build one: a wall hanging from the top (with a gap of
at least 3 tiles under it to walk through) and a full-height wall a few tiles to its right.

Stick to the "plan for" numbers so jumps never need to be pixel-perfect.

## Tips for a good 2–4 minute level

* Around 320–440 characters wide (8–11 blocks of 40) is a good length.
* Put a checkpoint `C` every 1–2 blocks so dying doesn't feel unfair.
* Teach one new idea per level, with a sign, before mixing it with others.
* Gems in tricky spots reward players who want to explore.
* Fall-proof retries (ground under a hard jump instead of a pit) keep things friendly.
* Keep checkpoints out of enemy paths. Skeletons walk until they hit a wall or a ledge,
  so a 1-tile post (`#` on the ground) is an easy way to fence them off.
* On ice, always leave one normal `#` tile in front of a wall, or the player gets
  stuck against the wall unable to jump.

To add a brand-new theme, copy one of the blocks in `scripts/config.gd` → `THEMES`.
