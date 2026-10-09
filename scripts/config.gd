extends Node
## =====================================================================
##  SKULLRUN — EDITABLE SETTINGS
##  Change the title-screen text and the colours here. Everything else
##  in the game reads from this file, so you only need to edit it once.
## =====================================================================

# ---------------------------------------------------------------------
#  Title screen text
# ---------------------------------------------------------------------
const GAME_TITLE := "SKULLRUN"

const TAGLINE := "ESCAPE THE CRYPT. OUTRUN THE REAPER."

# You can write several lines. Use \n for a new line.
const DESCRIPTION := "You are a cursed skull that just woke up deep inside a forgotten crypt.\nRun, jump and dash through haunted lands, collect glowing soul gems,\nand find the way out before the Reaper notices you're gone."

const VERSION_TEXT := "v0.1  •  made with Godot"

# ---------------------------------------------------------------------
#  Colour scheme (used by menus and the HUD)
# ---------------------------------------------------------------------
const COLOR_BG := Color("0b0a10")        # page background
const COLOR_BG_LIGHT := Color("1b1526")  # gradient / panels
const COLOR_PANEL := Color(0.07, 0.06, 0.10, 0.92)
const COLOR_BONE := Color("ece4d0")      # main text, the skull
const COLOR_ACCENT := Color("e63946")    # blood red highlights
const COLOR_ACCENT_DARK := Color("8d1b26")
const COLOR_PURPLE := Color("9d4edd")
const COLOR_MUTED := Color("8f879e")     # secondary text
const COLOR_GEM := Color("5ef2c2")       # soul gems
const COLOR_GOLD := Color("ffd166")

# ---------------------------------------------------------------------
#  Level folder. Any file named level_XX.txt in here becomes a level,
#  in alphabetical order (so use level_01, level_02 … level_80).
# ---------------------------------------------------------------------
const LEVELS_DIR := "res://levels"

# ---------------------------------------------------------------------
#  Level themes. Set `theme: name` at the top of a level file.
#  Add your own theme by copying one of these blocks.
# ---------------------------------------------------------------------
const THEMES := {
	"crypt": {
		"sky_top": Color("120d1c"), "sky_bottom": Color("2a2038"),
		"far": Color("1c1529"), "near": Color("251c35"),
		"tile": Color("3b3350"), "tile_dark": Color("2a2440"), "tile_light": Color("4a4163"),
		"tile_top": Color("6d5f8f"), "platform": Color("7a6450"),
		"hazard": Color("ece4d0"), "liquid": Color("7cff6b"),
		"moon": false, "scenery": "arches",
	},
	"graveyard": {
		"sky_top": Color("0a1020"), "sky_bottom": Color("23314a"),
		"far": Color("17213a"), "near": Color("1d2a3f"),
		"tile": Color("3a3a48"), "tile_dark": Color("2a2a36"), "tile_light": Color("4a4a5a"),
		"tile_top": Color("3f7a4a"), "platform": Color("6e5640"),
		"hazard": Color("d9d4c5"), "liquid": Color("7cff6b"),
		"moon": true, "scenery": "graves",
	},
	"bonecaves": {
		"sky_top": Color("120c08"), "sky_bottom": Color("2c1f16"),
		"far": Color("1e150f"), "near": Color("2a1e15"),
		"tile": Color("5a4636"), "tile_dark": Color("3f3126"), "tile_light": Color("6e5844"),
		"tile_top": Color("d8c9a8"), "platform": Color("c9b48a"),
		"hazard": Color("ece4d0"), "liquid": Color("5ef2c2"),
		"moon": false, "scenery": "stalactites",
	},
	"forge": {
		"sky_top": Color("1a0606"), "sky_bottom": Color("4a1408"),
		"far": Color("2a0a08"), "near": Color("3a0e0a"),
		"tile": Color("3a2626"), "tile_dark": Color("261818"), "tile_light": Color("4c3232"),
		"tile_top": Color("ff7b2e"), "platform": Color("6a4a3a"),
		"hazard": Color("ffd2a0"), "liquid": Color("ff5a1f"),
		"moon": false, "scenery": "chimneys",
	},
	"tower": {
		"sky_top": Color("0d0718"), "sky_bottom": Color("3a1430"),
		"far": Color("1a0e2a"), "near": Color("26123a"),
		"tile": Color("2e2440"), "tile_dark": Color("1f182e"), "tile_light": Color("3d3155"),
		"tile_top": Color("e63946"), "platform": Color("5a3d5c"),
		"hazard": Color("ece4d0"), "liquid": Color("c13cff"),
		"moon": true, "scenery": "spires",
	},
	"frost": {
		"sky_top": Color("0a1428"), "sky_bottom": Color("2b4a6a"),
		"far": Color("1a2c46"), "near": Color("223a58"),
		"tile": Color("3c4a63"), "tile_dark": Color("2a3448"), "tile_light": Color("52627e"),
		"tile_top": Color("e8f6ff"), "platform": Color("7a8aa0"),
		"hazard": Color("cfefff"), "liquid": Color("5ec8ff"),
		"moon": true, "scenery": "icepeaks",
	},
	"wells": {
		"sky_top": Color("071410"), "sky_bottom": Color("17302a"),
		"far": Color("0f221d"), "near": Color("152c25"),
		"tile": Color("2f4040"), "tile_dark": Color("1f2c2c"), "tile_light": Color("405656"),
		"tile_top": Color("6bd49a"), "platform": Color("6b5a44"),
		"hazard": Color("e6efe0"), "liquid": Color("7cff6b"),
		"moon": false, "scenery": "arches",
	},
	"ossuary": {
		"sky_top": Color("140e14"), "sky_bottom": Color("33242e"),
		"far": Color("201720"), "near": Color("2a1e28"),
		"tile": Color("6a5a4c"), "tile_dark": Color("4a3e34"), "tile_light": Color("806c5a"),
		"tile_top": Color("efe4cc"), "platform": Color("b8a27e"),
		"hazard": Color("efe4cc"), "liquid": Color("c13cff"),
		"moon": false, "scenery": "skulls",
	},
	"throne": {
		"sky_top": Color("100508"), "sky_bottom": Color("3a0c16"),
		"far": Color("220a10"), "near": Color("2e0d16"),
		"tile": Color("3a2a30"), "tile_dark": Color("281c22"), "tile_light": Color("4e3840"),
		"tile_top": Color("ffd166"), "platform": Color("7a4a3a"),
		"hazard": Color("ffe6b0"), "liquid": Color("ff3b3b"),
		"moon": true, "scenery": "pillars",
	},
}

const DEFAULT_THEME := "crypt"


func get_theme_colors(theme_name: String) -> Dictionary:
	return THEMES.get(theme_name, THEMES[DEFAULT_THEME])
