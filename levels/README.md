# Making SKULLRUN levels

Every level is a plain text file in this folder. The game finds them on its own:
any file named `level_XX.txt` becomes a level, in alphabetical order. So to add
level 6, copy `level_05.txt` to `level_06.txt` and start editing. Use two digits
(`level_06`, `level_42`), or three if you ever go past 99 (`level_100` would sort
before `level_11`, so rename them all to `level_001` and so on).

## File layout

```
name: Moonlit Graveyard          <- shown on the level menu and HUD
theme: graveyard                 <- crypt, graveyard, bonecaves, forge or tower
abilities: jump double           <- any of: jump double dash
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
| `^`  | spikes (deadly) |
| `~`  | lava / acid (deadly; colour comes from the theme) |
| `o`  | soul gem (collectible) |
| `P`  | player start (one per level) |
| `E`  | exit portal (one per level) |
| `C`  | checkpoint lantern |
| `G`  | ghost: floats 3 tiles left and right; can't be stomped |
| `B`  | bat: flies about 2.5 tiles up and down |
| `S`  | skeleton: walks back and forth; stomp it from above |
| `J`  | jump pad: launches you about 8 tiles up |
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

Stick to the "plan for" numbers so jumps never need to be pixel-perfect.

## Tips for a good 2–4 minute level

* Around 320–440 characters wide (8–11 blocks of 40) is a good length.
* Put a checkpoint `C` every 1–2 blocks so dying doesn't feel unfair.
* Teach one new idea per level, with a sign, before mixing it with others.
* Gems in tricky spots reward players who want to explore.
* Fall-proof retries (ground under a hard jump instead of a pit) keep things friendly.

To add a brand-new theme, copy one of the blocks in `scripts/config.gd` → `THEMES`.
