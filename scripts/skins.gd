extends RefCounted
## Skull skins: the shop's list (title screen → SHOP) and the drawing code.
## Skins are bought with soul gems from the gem bag (`Game.gem_bag`): every
## gem you carry through a level's exit portal goes in the bag.
##
## A skin is a Dictionary: bone colour, eye colour, a hat ("" = none) and an
## extra effect ("" = none, "rainbow" or "ghost"). To add a skin to the shop,
## add a line to SKINS (keep 12 cards with the custom one: the shop grid is
## 6 wide). Skins with a "season" go on the shop's SEASONAL tab instead, under
## that season's heading (SEASONS). A new hat needs a name in HATS and a
## branch in `draw_hat` (and `draw_hat_back` for parts behind the head).

const SkullArt = preload("res://scripts/skull_art.gd")

const CUSTOM_ID := "custom"
const CUSTOM_PRICE := 500000

const SKINS := [
	{"id": "classic", "name": "Classic", "price": 0,
		"bone": Color("ece4d0"), "eye": Color("e63946"), "hat": "", "fx": ""},
	{"id": "party", "name": "Party", "price": 50,
		"bone": Color("ece4d0"), "eye": Color("ff5fa2"), "hat": "party", "fx": ""},
	{"id": "frosty", "name": "Frosty", "price": 150,
		"bone": Color("c4e8ff"), "eye": Color("2ec4ff"), "hat": "beanie", "fx": ""},
	{"id": "pumpkin", "name": "Pumpkin", "price": 250,
		"bone": Color("ff8c2a"), "eye": Color("ffe14d"), "hat": "stem", "fx": ""},
	{"id": "witchy", "name": "Witchy", "price": 350,
		"bone": Color("94d46c"), "eye": Color("c77dff"), "hat": "witch", "fx": ""},
	{"id": "devil", "name": "Little Devil", "price": 450,
		"bone": Color("ee5a4c"), "eye": Color("ffd166"), "hat": "horns", "fx": ""},
	{"id": "angel", "name": "Angel", "price": 600,
		"bone": Color("ffffff"), "eye": Color("6ec8ff"), "hat": "halo", "fx": ""},
	{"id": "ghost", "name": "Ghost", "price": 800,
		"bone": Color("dce9ff"), "eye": Color("5ef2c2"), "hat": "", "fx": "ghost"},
	{"id": "fancy", "name": "Fancy", "price": 1000,
		"bone": Color("ece4d0"), "eye": Color("5ef2c2"), "hat": "tophat", "fx": ""},
	{"id": "king", "name": "Golden King", "price": 1500,
		"bone": Color("ffd166"), "eye": Color("e63946"), "hat": "crown", "fx": ""},
	{"id": "rainbow", "name": "Rainbow", "price": 2500,
		"bone": Color("ffffff"), "eye": Color("ffffff"), "hat": "", "fx": "rainbow"},
	# the SEASONAL tab
	{"id": "turkey", "name": "Turkey", "price": 300, "season": "thanksgiving",
		"bone": Color("b08860"), "eye": Color("ffe14d"), "hat": "turkey", "fx": ""},
	{"id": "pilgrim", "name": "Pilgrim", "price": 400, "season": "thanksgiving",
		"bone": Color("ece4d0"), "eye": Color("ff8c2a"), "hat": "pilgrim", "fx": ""},
	{"id": "pie", "name": "Pumpkin Pie", "price": 500, "season": "thanksgiving",
		"bone": Color("ffd9a0"), "eye": Color("e63946"), "hat": "pie", "fx": ""},
	{"id": "santa", "name": "Santa", "price": 600, "season": "christmas",
		"bone": Color("ece4d0"), "eye": Color("2ec4ff"), "hat": "santa", "fx": ""},
	{"id": "reindeer", "name": "Reindeer", "price": 700, "season": "christmas",
		"bone": Color("c89a6a"), "eye": Color("ffe14d"), "hat": "antlers", "fx": ""},
	{"id": "snowman", "name": "Snowman", "price": 800, "season": "christmas",
		"bone": Color("ffffff"), "eye": Color("6ec8ff"), "hat": "snowman", "fx": ""},
]
## The SEASONAL tab's headings, in order: season id, title, colour.
const SEASONS := [
	["thanksgiving", "Thanksgiving", Color("ff8c2a")],
	["christmas", "Christmas", Color("7cff6b")],
]

# ---------------------------------------------------------------------
#  Make your own: the choices in the skull maker
# ---------------------------------------------------------------------
const BONE_COLORS := [
	Color("ece4d0"), Color("ffffff"), Color("ffd166"), Color("ff8c2a"),
	Color("ee5a4c"), Color("ff7ac8"), Color("c77dff"), Color("6ec8ff"),
	Color("5ef2c2"), Color("94d46c"), Color("b08860"), Color("9a93aa"),
]
const EYE_COLORS := [
	Color("e63946"), Color("ff8c2a"), Color("ffe14d"), Color("7cff6b"), Color("5ef2c2"),
	Color("2ec4ff"), Color("4d6bff"), Color("c77dff"), Color("ff5fa2"), Color("ffffff"),
]
const HATS := ["", "party", "crown", "tophat", "witch", "horns", "halo", "bow", "beanie", "cap", "stem",
	"turkey", "pilgrim", "pie", "santa", "antlers", "snowman"]
const HAT_NAMES := {
	"": "No hat", "party": "Party hat", "crown": "Crown", "tophat": "Top hat",
	"witch": "Witch hat", "horns": "Horns", "halo": "Halo", "bow": "Bow",
	"beanie": "Woolly hat", "cap": "Cap", "stem": "Pumpkin stem",
	"turkey": "Turkey", "pilgrim": "Pilgrim hat", "pie": "Pumpkin pie",
	"santa": "Santa hat", "antlers": "Antlers", "snowman": "Snowman",
}
const FX := ["", "rainbow", "ghost"]
const FX_NAMES := {"": "None", "rainbow": "Rainbow", "ghost": "Ghost"}

const DEFAULT_CUSTOM := {"bone": Color("ece4d0"), "eye": Color("e63946"), "hat": "", "fx": ""}


## The shop entry with this id, or an empty Dictionary.
static func find(id: String) -> Dictionary:
	for s in SKINS:
		if s["id"] == id:
			return s
	return {}


static func price(id: String) -> int:
	if id == CUSTOM_ID:
		return CUSTOM_PRICE
	return int(find(id).get("price", -1))


static func exists(id: String) -> bool:
	return id == CUSTOM_ID or not find(id).is_empty()


## A custom skin from the save file, with anything broken or missing set back
## to the default.
static func clean_custom(d) -> Dictionary:
	var out := DEFAULT_CUSTOM.duplicate()
	if typeof(d) != TYPE_DICTIONARY:
		return out
	if d.get("bone") is Color:
		out["bone"] = Color(d["bone"], 1.0)
	if d.get("eye") is Color:
		out["eye"] = Color(d["eye"], 1.0)
	if str(d.get("hat", "")) in HATS:
		out["hat"] = str(d.get("hat", ""))
	if str(d.get("fx", "")) in FX:
		out["fx"] = str(d.get("fx", ""))
	return out


# ---------------------------------------------------------------------
#  Drawing
# ---------------------------------------------------------------------
## The bone colour right now (the rainbow skin keeps changing).
static func bone_color(skin: Dictionary, time: float) -> Color:
	if skin.get("fx", "") == "rainbow":
		return Color.from_hsv(fmod(time * 0.25, 1.0), 0.42, 1.0)
	return skin.get("bone", Config.COLOR_BONE)


## The eye colour, gently pulsing like the classic skull's.
static func eye_color(skin: Dictionary, time: float) -> Color:
	var eye: Color = skin.get("eye", Config.COLOR_ACCENT)
	if skin.get("fx", "") == "rainbow":
		eye = Color.from_hsv(fmod(time * 0.25 + 0.5, 1.0), 0.7, 1.0)
	return eye.lerp(Color.WHITE, 0.25 + 0.15 * sin(time * 6.0))


## Draws a skull wearing `skin`, centred on `c` (`r` = head radius, `look` -1 … 1
## = where it's facing). `eye` replaces the eye colour (the player turns its
## eyes purple while the dash is used up); leave it transparent for the skin's own.
static func draw_skin(ci: CanvasItem, c: Vector2, r: float, skin: Dictionary, time: float,
		look: float = 0.0, eye: Color = Color(0, 0, 0, 0)) -> void:
	var bone := bone_color(skin, time)
	if eye.a == 0.0:
		eye = eye_color(skin, time)
	if skin.get("fx", "") == "ghost":
		_draw_ghost_wisps(ci, c, r, bone, time, look)
	draw_hat_back(ci, c, r, str(skin.get("hat", "")), time, look)
	SkullArt.draw_skull(ci, c, r, bone, eye, look)
	draw_hat(ci, c, r, str(skin.get("hat", "")), time, look)


## A soft glow and little wisps of spirit trailing behind the head.
static func _draw_ghost_wisps(ci: CanvasItem, c: Vector2, r: float, bone: Color, time: float, look: float) -> void:
	ci.draw_circle(c + Vector2(0, -r * 0.1), r * 1.6, Color(bone, 0.10))
	ci.draw_circle(c + Vector2(0, -r * 0.1), r * 1.3, Color(bone, 0.12))
	var back := -1.0 if look > 0.05 else 1.0
	for i in 4:
		var t := float(i + 1)
		var p := c + Vector2(back * r * (0.7 + t * 0.42), r * (0.1 + sin(time * 5.0 + t) * 0.18))
		ci.draw_circle(p, r * (0.5 - t * 0.09), Color(bone, 0.42 - t * 0.08))


## The parts of a hat that go behind the head (the turkey's tail feathers).
static func draw_hat_back(ci: CanvasItem, c: Vector2, r: float, hat: String, time: float, look: float = 0.0) -> void:
	if hat == "turkey":
		var cols := [Color("c0392b"), Color("ff8c2a"), Color("ffd166"), Color("ff8c2a"), Color("c0392b")]
		var base := c + Vector2(0, -r * 0.1)
		for i in 5:
			var a := -PI * 0.5 + (i - 2) * 0.42 + sin(time * 2.0) * 0.03
			var d := Vector2(cos(a), sin(a))
			var side := Vector2(-d.y, d.x)
			var tip := base + d * r * 1.75
			ci.draw_colored_polygon(PackedVector2Array([base + side * r * 0.22, tip + side * r * 0.26,
				tip + d * r * 0.18, tip - side * r * 0.26, base - side * r * 0.22]), cols[i])
			ci.draw_circle(tip - d * r * 0.1, r * 0.1, Color("3a2a1a"))


## Hats sit on the top of the head. Only rects, small polygons and a few
## circles, so they're cheap to draw every frame.
static func draw_hat(ci: CanvasItem, c: Vector2, r: float, hat: String, time: float, look: float = 0.0) -> void:
	if hat == "":
		return
	var x := c.x + look * r * 0.06
	var by := c.y - r * 0.8  # where a hat sits on the head
	match hat:
		"party":
			var cone := PackedVector2Array([Vector2(x - r * 0.5, by + r * 0.05),
				Vector2(x + r * 0.45, by + r * 0.05), Vector2(x + r * 0.15, by - r * 1.3)])
			ci.draw_colored_polygon(cone, Color("ff5fa2"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - r * 0.5, by + r * 0.05),
				Vector2(x - r * 0.08, by + r * 0.05), Vector2(x + r * 0.15, by - r * 1.3)]), Color("ff8cc0"))
			ci.draw_circle(Vector2(x - r * 0.12, by - r * 0.35), r * 0.09, Color("ffd166"))
			ci.draw_circle(Vector2(x + r * 0.15, by - r * 0.6), r * 0.09, Color("5ef2c2"))
			ci.draw_circle(Vector2(x + r * 0.15, by - r * 1.3), r * 0.17, Color("ffd166"))
		"crown":
			var gold := Color("ffc43d")
			var y := by - r * 0.05
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(x - r * 0.62, y + r * 0.1), Vector2(x - r * 0.62, y - r * 0.8),
				Vector2(x - r * 0.3, y - r * 0.38), Vector2(x, y - r * 0.92),
				Vector2(x + r * 0.3, y - r * 0.38), Vector2(x + r * 0.62, y - r * 0.8),
				Vector2(x + r * 0.62, y + r * 0.1)]), gold)
			ci.draw_rect(Rect2(x - r * 0.62, y - r * 0.12, r * 1.24, r * 0.22), gold.darkened(0.2))
			ci.draw_circle(Vector2(x, y - r * 0.01), r * 0.1, Color("e63946"))
			ci.draw_circle(Vector2(x - r * 0.36, y - r * 0.01), r * 0.08, Color("2ec4ff"))
			ci.draw_circle(Vector2(x + r * 0.36, y - r * 0.01), r * 0.08, Color("7cff6b"))
		"tophat":
			var black := Color("1d1a26")
			ci.draw_rect(Rect2(x - r * 0.85, by - r * 0.1, r * 1.7, r * 0.2), black)
			ci.draw_rect(Rect2(x - r * 0.5, by - r * 1.15, r * 1.0, r * 1.1), black)
			ci.draw_rect(Rect2(x - r * 0.5, by - r * 0.38, r * 1.0, r * 0.2), Color("e63946"))
			ci.draw_rect(Rect2(x - r * 0.42, by - r * 1.1, r * 0.14, r * 0.6), Color(1, 1, 1, 0.12))
		"witch":
			var hat_c := Color("3b2160")
			ci.draw_colored_polygon(_ellipse(Vector2(x, by), r * 1.05, r * 0.2, 12), hat_c.darkened(0.2))
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(x - r * 0.55, by), Vector2(x + r * 0.55, by), Vector2(x + r * 0.35, by - r * 0.9),
				Vector2(x + r * 0.95, by - r * 1.45), Vector2(x + r * 0.05, by - r * 1.0)]), hat_c)
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(x - r * 0.46, by - r * 0.15), Vector2(x + r * 0.52, by - r * 0.15),
				Vector2(x + r * 0.48, by - r * 0.3), Vector2(x - r * 0.37, by - r * 0.3)]), Color("7cff6b"))
		"horns":
			var horn := Color("5a0e18")
			for s in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([
					Vector2(x + s * r * 0.62, by + r * 0.25), Vector2(x + s * r * 0.28, by + r * 0.02),
					Vector2(x + s * r * 0.58, by - r * 0.4), Vector2(x + s * r * 0.95, by - r * 0.85),
					Vector2(x + s * r * 0.82, by - r * 0.28)]), horn)
		"halo":
			var hy := by - r * 0.6 + sin(time * 3.0) * r * 0.08
			var ring := _ellipse(Vector2(x, hy), r * 0.72, r * 0.2, 18)
			ring.append(ring[0])
			ci.draw_polyline(ring, Color("ffe08a", 0.3), maxf(2.0, r * 0.32))
			ci.draw_polyline(ring, Color("ffe08a"), maxf(1.5, r * 0.14))
		"bow":
			var b := Vector2(x + r * 0.5, by - r * 0.05)
			var pink := Color("ff5fa2")
			ci.draw_colored_polygon(PackedVector2Array([b, b + Vector2(-r * 0.5, -r * 0.34), b + Vector2(-r * 0.5, r * 0.3)]), pink)
			ci.draw_colored_polygon(PackedVector2Array([b, b + Vector2(r * 0.5, r * 0.3), b + Vector2(r * 0.5, -r * 0.34)]), pink)
			ci.draw_circle(b, r * 0.15, pink.darkened(0.25))
		"beanie":
			var blue := Color("3a7bd5")
			ci.draw_colored_polygon(_dome(Vector2(x, by + r * 0.1), r * 0.84, r * 0.78, 12), blue)
			ci.draw_rect(Rect2(x - r * 0.88, by - r * 0.05, r * 1.76, r * 0.3), Color("e8f4ff"))
			ci.draw_circle(Vector2(x, by - r * 0.72), r * 0.24, Color("e8f4ff"))
		"cap":
			var red := Color("e63946")
			var s := -1.0 if look < -0.05 else 1.0
			ci.draw_colored_polygon(_dome(Vector2(x, by + r * 0.15), r * 0.82, r * 0.7, 12), red)
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(x + s * r * 0.3, by + r * 0.02), Vector2(x + s * r * 1.2, by + r * 0.1),
				Vector2(x + s * r * 1.15, by + r * 0.24), Vector2(x + s * r * 0.3, by + r * 0.24)]), red.darkened(0.3))
			ci.draw_circle(Vector2(x, by - r * 0.52), r * 0.1, red.darkened(0.3))
		"turkey":
			# beak and wattle (the feathers are drawn behind the head)
			var n := Vector2(x + look * r * 0.08, c.y + r * 0.42)
			var s := 1.0 if look >= 0.0 else -1.0
			ci.draw_colored_polygon(PackedVector2Array([n + Vector2(-s * r * 0.14, -r * 0.14),
				n + Vector2(s * r * 0.34, r * 0.02), n + Vector2(-s * r * 0.14, r * 0.12)]), Color("ffb020"))
			ci.draw_colored_polygon(PackedVector2Array([n + Vector2(0, r * 0.08), n + Vector2(s * r * 0.12, r * 0.12),
				n + Vector2(s * r * 0.06, r * 0.5), n + Vector2(-s * r * 0.04, r * 0.44)]), Color("e63946"))
		"pilgrim":
			var black := Color("1d1a26")
			ci.draw_rect(Rect2(x - r * 0.95, by - r * 0.08, r * 1.9, r * 0.18), black)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - r * 0.58, by), Vector2(x + r * 0.58, by),
				Vector2(x + r * 0.46, by - r * 1.05), Vector2(x - r * 0.46, by - r * 1.05)]), black)
			ci.draw_rect(Rect2(x - r * 0.56, by - r * 0.34, r * 1.12, r * 0.22), Color("4a3a2a"))
			ci.draw_rect(Rect2(x - r * 0.17, by - r * 0.4, r * 0.34, r * 0.34), Color("ffd166"))
			ci.draw_rect(Rect2(x - r * 0.08, by - r * 0.31, r * 0.16, r * 0.16), Color("4a3a2a"))
		"pie":
			# a slice of pumpkin pie with a blob of cream
			var y := by - r * 0.05
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - r * 0.75, y + r * 0.08),
				Vector2(x + r * 0.75, y + r * 0.08), Vector2(x + r * 0.75, y - r * 0.32),
				Vector2(x - r * 0.75, y - r * 0.12)]), Color("ff8c2a"))
			ci.draw_rect(Rect2(x - r * 0.8, y - r * 0.02, r * 1.6, r * 0.2), Color("c98a4a"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + r * 0.6, y + r * 0.08),
				Vector2(x + r * 0.86, y + r * 0.08), Vector2(x + r * 0.86, y - r * 0.4), Vector2(x + r * 0.6, y - r * 0.36)]), Color("c98a4a"))
			ci.draw_circle(Vector2(x - r * 0.05, y - r * 0.38), r * 0.24, Color("fff8ec"))
			ci.draw_circle(Vector2(x + r * 0.12, y - r * 0.5), r * 0.16, Color("fff8ec"))
		"santa":
			var red := Color("e0303a")
			var s := -1.0 if look < -0.05 else 1.0
			var tip := Vector2(x + s * r * 1.0, by - r * 0.45 + sin(time * 3.0) * r * 0.05)
			# flops over to the side the skull is looking
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - s * r * 0.7, by + r * 0.05),
				Vector2(x + s * r * 0.7, by + r * 0.05), Vector2(x + s * r * 0.55, by - r * 0.55), tip,
				Vector2(x + s * r * 0.2, by - r * 1.05)]), red)
			ci.draw_rect(Rect2(x - r * 0.82, by - r * 0.1, r * 1.64, r * 0.3), Color("ffffff"))
			ci.draw_circle(tip, r * 0.2, Color("ffffff"))
			# a fluffy white beard under the jaw
			for i in 5:
				var bx := x + (i - 2) * r * 0.28
				ci.draw_circle(Vector2(bx, c.y + r * (0.86 - absf(i - 2) * 0.12)), r * 0.22, Color("ffffff"))
		"antlers":
			var brown := Color("7a4e2a")
			var w := maxf(1.5, r * 0.13)
			for s in [-1.0, 1.0]:
				var b := Vector2(x + s * r * 0.4, by + r * 0.05)
				var t := b + Vector2(s * r * 0.45, -r * 0.95)
				ci.draw_line(b, t, brown, w)
				ci.draw_line(b.lerp(t, 0.45), b.lerp(t, 0.45) + Vector2(s * r * 0.4, -r * 0.2), brown, w)
				ci.draw_line(b.lerp(t, 0.7), b.lerp(t, 0.7) + Vector2(-s * r * 0.15, -r * 0.35), brown, w)
			# the shiny red nose
			var n := Vector2(x + look * r * 0.08, c.y + r * 0.38)
			ci.draw_circle(n, r * 0.3, Color(1.0, 0.2, 0.2, 0.25 + 0.15 * sin(time * 4.0)))
			ci.draw_circle(n, r * 0.17, Color("ff2a2a"))
			ci.draw_circle(n + Vector2(-r * 0.05, -r * 0.05), r * 0.06, Color(1, 1, 1, 0.8))
		"snowman":
			var black := Color("1d1a26")
			ci.draw_rect(Rect2(x - r * 0.75, by - r * 0.08, r * 1.5, r * 0.16), black)
			ci.draw_rect(Rect2(x - r * 0.44, by - r * 0.85, r * 0.88, r * 0.8), black)
			ci.draw_rect(Rect2(x - r * 0.44, by - r * 0.28, r * 0.88, r * 0.16), Color("2e9e4a"))
			# carrot nose, pointing the way it looks
			var n := Vector2(x + look * r * 0.08, c.y + r * 0.4)
			var s := 1.0 if look >= 0.0 else -1.0
			ci.draw_colored_polygon(PackedVector2Array([n + Vector2(0, -r * 0.1),
				n + Vector2(s * r * 0.55, r * 0.02), n + Vector2(0, r * 0.1)]), Color("ff8c2a"))
			# scarf
			var red := Color("e0303a")
			ci.draw_rect(Rect2(c.x - r * 0.7, c.y + r * 0.78, r * 1.4, r * 0.2), red)
			ci.draw_rect(Rect2(c.x - s * r * 0.45 - r * 0.12, c.y + r * 0.82, r * 0.24, r * 0.3), red.darkened(0.15))
		"stem":
			var top := c.y - r * 1.15
			ci.draw_rect(Rect2(x - r * 0.1, top - r * 0.38, r * 0.22, r * 0.45), Color("5a3a1a"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + r * 0.1, top - r * 0.12),
				Vector2(x + r * 0.62, top - r * 0.46), Vector2(x + r * 0.5, top + r * 0.02)]), Color("4caf3a"))


## Top half of an ellipse, closed along its flat bottom.
static func _dome(centre: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := PI + PI * float(i) / n
		pts.append(centre + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _ellipse(centre: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / n
		pts.append(centre + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func format_gems(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + out
