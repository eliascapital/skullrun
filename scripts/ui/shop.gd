extends Control
## The skin shop (title screen → SHOP). Spend soul gems from the gem bag on
## skull skins, or save up for MAKE YOUR OWN, which opens the skull maker.
## The skins themselves are listed in scripts/skins.gd. Skins with a "season"
## go on the SEASONAL tab, grouped under each season's heading.

const UI = preload("res://scripts/ui/ui.gd")
const MenuBackground = preload("res://scripts/ui/menu_background.gd")
const Skins = preload("res://scripts/skins.gd")

const COLUMNS := 6
const CARD := Vector2(136, 132)

var _ids: Array = []  # one skin id per card (both tabs)
var _cards: Array = []
var _bag_label: Label
var _main_page: Control
var _season_page: Control
var _tab_buttons: Array = []  # SKINS, SEASONAL
var _back: Button
var _time := 0.0
var _pics: Array = []  # skull pictures, redrawn every frame

var _confirm_layer: ColorRect
var _confirm_box: VBoxContainer
var _confirm_id := ""

var _maker_layer: ColorRect
var _bone_swatches: Array = []
var _eye_swatches: Array = []
var _hat_label: Label
var _fx_label: Label
var _done: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBackground.new())

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	box.add_child(UI.make_title("SKIN SHOP", 50))

	var bag_row := HBoxContainer.new()
	bag_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bag_row.add_theme_constant_override("separation", 8)
	box.add_child(bag_row)
	for t in ["SKINS", "SEASONAL"]:
		var tab := UI.make_button(t, false, 150)
		tab.custom_minimum_size.y = 42
		tab.pressed.connect(_set_tab.bind(t == "SEASONAL", true))
		bag_row.add_child(tab)
		_tab_buttons.append(tab)
	var gap := Control.new()
	gap.custom_minimum_size.x = 36
	bag_row.add_child(gap)
	bag_row.add_child(_gem_icon())
	_bag_label = UI.make_label("", 24, Config.COLOR_GEM)
	bag_row.add_child(_bag_label)
	box.add_child(UI.make_label("Every gem you carry into an exit portal goes in your gem bag.", 14, Config.COLOR_MUTED))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var pages := VBoxContainer.new()
	center.add_child(pages)

	# the SKINS tab: every skin without a season, then MAKE YOUR OWN
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	pages.add_child(grid)
	_main_page = grid
	for s in Skins.SKINS:
		if not s.has("season"):
			grid.add_child(_add_card(s["id"]))
	grid.add_child(_add_card(Skins.CUSTOM_ID))

	# the SEASONAL tab: a heading and a row of cards for each season
	var seasons := HBoxContainer.new()
	seasons.add_theme_constant_override("separation", 30)
	pages.add_child(seasons)
	_season_page = seasons
	for season in Skins.SEASONS:
		var group := VBoxContainer.new()
		group.add_theme_constant_override("separation", 8)
		seasons.add_child(group)
		group.add_child(UI.make_label(season[1], 22, season[2]))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		group.add_child(row)
		for s in Skins.SKINS:
			if s.get("season", "") == season[0]:
				row.add_child(_add_card(s["id"]))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(bottom)
	_back = UI.make_button("BACK", false, 180)
	_back.pressed.connect(Game.goto_title)
	bottom.add_child(_back)

	_build_confirm()
	_build_maker()
	_update_cards()
	_set_tab(Skins.find(Game.skin_id).has("season"), false)
	(_cards[_ids.find(Game.skin_id)] as Button).grab_focus()


func _process(delta: float) -> void:
	_time += delta
	for p in _pics:
		if is_instance_valid(p) and p.is_visible_in_tree():
			p.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		return
	get_viewport().set_input_as_handled()
	if _maker_layer.visible:
		_close_maker()
	elif _confirm_layer.visible:
		_close_confirm()
	else:
		Game.goto_title()


# ---------------------------------------------------------------------
#  Tabs and skin cards
# ---------------------------------------------------------------------
func _set_tab(seasonal: bool, focus: bool) -> void:
	_main_page.visible = not seasonal
	_season_page.visible = seasonal
	for t in _tab_buttons.size():
		var on := (t == 1) == seasonal
		var b: Button = _tab_buttons[t]
		b.add_theme_stylebox_override("normal", UI.style_box(Color(Config.COLOR_ACCENT, 0.9) if on else Color(0, 0, 0, 0.25),
			Config.COLOR_ACCENT if on else Color(Config.COLOR_BONE, 0.35)))
	if focus:
		(_tab_buttons[1 if seasonal else 0] as Button).grab_focus()


func _add_card(id: String) -> Button:
	_ids.append(id)
	var b := _card(_ids.size() - 1)
	_cards.append(b)
	return b


func _card(i: int) -> Button:
	var b := UI.make_button("", false, CARD.x)
	b.custom_minimum_size = CARD
	b.add_theme_font_size_override("font_size", 15)
	for state in ["hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, _card_style(b.get_theme_stylebox(state)))
	b.pressed.connect(_on_card.bind(i))
	# the skull, drawn above the text
	var pic := Control.new()
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.position = Vector2(0, 4)
	pic.size = Vector2(CARD.x, 72)
	pic.draw.connect(_draw_card_skull.bind(pic, i))
	_pics.append(pic)
	b.add_child(pic)
	return b


## Text sits at the bottom of a card, under the skull.
func _card_style(sb: StyleBox) -> StyleBoxFlat:
	var out: StyleBoxFlat = sb.duplicate()
	out.content_margin_top = 74
	out.content_margin_bottom = 6
	out.content_margin_left = 4
	out.content_margin_right = 4
	return out


func _draw_card_skull(pic: Control, i: int) -> void:
	var id: String = _ids[i]
	var look := sin(_time * 1.3 + i * 0.9) * 0.7
	var c := Vector2(pic.size.x * 0.5, 46)
	if id == Skins.CUSTOM_ID and not Game.owns_skin(id):
		# not bought yet: show off what the skull maker can do
		var k := int(_time * 1.2)
		var demo := {"bone": Skins.BONE_COLORS[(k * 5) % Skins.BONE_COLORS.size()],
			"eye": Skins.EYE_COLORS[(k * 3) % Skins.EYE_COLORS.size()],
			"hat": Skins.HATS[1 + k % (Skins.HATS.size() - 1)], "fx": ""}
		Skins.draw_skin(pic, c, 20.0, demo, _time, look)
		return
	var skin: Dictionary = Game.custom_skin if id == Skins.CUSTOM_ID else Skins.find(id)
	Skins.draw_skin(pic, c, 20.0, skin, _time, look)


func _update_cards() -> void:
	_bag_label.text = "%s gems" % Game.gem_text()
	for i in _ids.size():
		var id: String = _ids[i]
		var b: Button = _cards[i]
		var skin_name := "Make your own" if id == Skins.CUSTOM_ID else str(Skins.find(id)["name"])
		var status := ""
		if id == Game.skin_id:
			status = "WEARING"
		elif Game.owns_skin(id):
			status = "EDIT" if id == Skins.CUSTOM_ID else "WEAR"
		else:
			status = "%s gems" % Skins.format_gems(Skins.price(id))
		if id == Skins.CUSTOM_ID and id == Game.skin_id:
			status = "WEARING • EDIT"
		b.text = "%s\n%s" % [skin_name, status]
		var wearing := id == Game.skin_id
		var bg := Color(Config.COLOR_ACCENT, 0.9) if wearing else Color(0, 0, 0, 0.25)
		var border := Config.COLOR_ACCENT if wearing else Color(Config.COLOR_BONE, 0.35)
		if not Game.owns_skin(id) and Game.can_afford(Skins.price(id)):
			border = Config.COLOR_GEM  # you can buy this one now
		b.add_theme_stylebox_override("normal", _card_style(UI.style_box(bg, border)))
		b.add_theme_color_override("font_color", Config.COLOR_BONE if Game.owns_skin(id) or wearing
			else (Config.COLOR_GEM if Game.can_afford(Skins.price(id)) else Config.COLOR_MUTED))


func _on_card(i: int) -> void:
	var id: String = _ids[i]
	if Game.owns_skin(id):
		Game.wear_skin(id)
		_update_cards()
		if id == Skins.CUSTOM_ID:
			_open_maker()
		else:
			Sfx.play("checkpoint")
	else:
		_open_confirm(id)


# ---------------------------------------------------------------------
#  Buying
# ---------------------------------------------------------------------
func _build_confirm() -> void:
	_confirm_layer = _dim_layer()
	var panel := UI.make_panel(420)
	_confirm_layer.get_child(0).add_child(panel)
	_confirm_box = VBoxContainer.new()
	_confirm_box.add_theme_constant_override("separation", 10)
	panel.add_child(_confirm_box)


func _open_confirm(id: String) -> void:
	_confirm_id = id
	for c in _confirm_box.get_children():
		c.queue_free()
	var custom := id == Skins.CUSTOM_ID
	var cost := Skins.price(id)
	var skin_name := "Make your own skull!" if custom else str(Skins.find(id)["name"])
	_confirm_box.add_child(UI.make_title(skin_name, 40 if custom else 48))
	var pic := _big_skull(110.0, 34.0, func(): return Skins.find(id) if not custom else _maker_demo())
	_confirm_box.add_child(_centered(pic))
	if custom:
		_confirm_box.add_child(UI.make_label("Pick your own colours, eyes, hat and magic.", 15, Config.COLOR_MUTED))
	_confirm_box.add_child(UI.make_label("%s gems" % Skins.format_gems(cost), 22, Config.COLOR_GEM))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var first: Button
	if Game.can_afford(cost):
		first = UI.make_button("BUY IT!", true, 160)
		first.pressed.connect(_buy)
		row.add_child(first)
		var no := UI.make_button("NO", false, 120)
		no.pressed.connect(_close_confirm)
		row.add_child(no)
	else:
		var need := UI.make_label("You need %s more gems.\nFinish levels to fill your gem bag!"
			% Skins.format_gems(cost - Game.gem_bag), 17, Config.COLOR_ACCENT)
		_confirm_box.add_child(need)
		first = UI.make_button("OK", true, 140)
		first.pressed.connect(_close_confirm)
		row.add_child(first)
	_confirm_box.add_child(row)
	_confirm_layer.visible = true
	first.grab_focus()


func _buy() -> void:
	var id := _confirm_id
	if not Game.buy_skin(id):
		return
	Sfx.play("win")
	_confirm_layer.visible = false
	_update_cards()
	if id == Skins.CUSTOM_ID:
		_open_maker()
	else:
		(_cards[_ids.find(id)] as Button).grab_focus()


func _close_confirm() -> void:
	_confirm_layer.visible = false
	var i := _ids.find(_confirm_id)
	(_cards[maxi(i, 0)] as Button).grab_focus()


func _maker_demo() -> Dictionary:
	var k := int(_time * 1.2)
	return {"bone": Skins.BONE_COLORS[(k * 5) % Skins.BONE_COLORS.size()],
		"eye": Skins.EYE_COLORS[(k * 3) % Skins.EYE_COLORS.size()],
		"hat": Skins.HATS[1 + k % (Skins.HATS.size() - 1)], "fx": ""}


# ---------------------------------------------------------------------
#  The skull maker (MAKE YOUR OWN)
# ---------------------------------------------------------------------
func _build_maker() -> void:
	_maker_layer = _dim_layer()
	var panel := UI.make_panel(700)
	_maker_layer.get_child(0).add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UI.make_title("MAKE YOUR OWN", 46))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	box.add_child(row)
	row.add_child(_big_skull(180.0, 52.0, func(): return Game.custom_skin))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(grid)

	grid.add_child(_row_label("Skull"))
	grid.add_child(_swatch_row(Skins.BONE_COLORS, "bone", _bone_swatches))
	grid.add_child(_row_label("Eyes"))
	grid.add_child(_swatch_row(Skins.EYE_COLORS, "eye", _eye_swatches))
	grid.add_child(_row_label("Hat"))
	_hat_label = UI.make_label("", 17, Config.COLOR_BONE)
	grid.add_child(_cycler(_hat_label, "hat", Skins.HATS))
	grid.add_child(_row_label("Magic"))
	_fx_label = UI.make_label("", 17, Config.COLOR_BONE)
	grid.add_child(_cycler(_fx_label, "fx", Skins.FX))

	_done = UI.make_button("DONE", true, 200)
	_done.pressed.connect(_close_maker)
	box.add_child(_centered(_done))
	_update_maker()


func _open_maker() -> void:
	_update_maker()
	_maker_layer.visible = true
	_done.grab_focus()


func _close_maker() -> void:
	_maker_layer.visible = false
	Game.wear_skin(Skins.CUSTOM_ID)  # also saves
	_update_cards()
	(_cards[_ids.find(Skins.CUSTOM_ID)] as Button).grab_focus()


func _update_maker() -> void:
	var skin := Game.custom_skin
	for pair in [[_bone_swatches, "bone"], [_eye_swatches, "eye"]]:
		for b in pair[0]:
			var col: Color = b.get_meta("color")
			var on: bool = col.is_equal_approx(skin[pair[1]])
			b.add_theme_stylebox_override("normal", _swatch_style(col, Config.COLOR_BONE if on else Color(0, 0, 0, 0.6), 3 if on else 2))
	_hat_label.text = Skins.HAT_NAMES[skin["hat"]]
	_fx_label.text = Skins.FX_NAMES[skin["fx"]]


func _row_label(text: String) -> Label:
	return UI.make_label(text, 17, Config.COLOR_ACCENT, HORIZONTAL_ALIGNMENT_RIGHT)


func _swatch_row(colors: Array, key: String, list: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for col in colors:
		var b := Button.new()
		b.custom_minimum_size = Vector2(30, 30)
		b.set_meta("color", col)
		b.add_theme_stylebox_override("hover", _swatch_style(col.lightened(0.15), Config.COLOR_BONE, 2))
		b.add_theme_stylebox_override("pressed", _swatch_style(col, Config.COLOR_BONE, 3))
		b.add_theme_stylebox_override("focus", _swatch_style(Color(0, 0, 0, 0), Color.WHITE, 2))
		b.pressed.connect(func():
			Game.custom_skin[key] = col
			Sfx.play("click")
			_update_maker()
		)
		b.mouse_entered.connect(func(): Sfx.play("hover"))
		row.add_child(b)
		list.append(b)
	return row


## "<  Crown  >": steps through a list of choices.
func _cycler(label: Label, key: String, choices: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	label.custom_minimum_size = Vector2(170, 0)
	for step in [-1, 1]:
		var b := UI.make_button("<" if step < 0 else ">", false, 54)
		b.custom_minimum_size = Vector2(54, 40)
		for state in ["normal", "hover", "pressed", "focus"]:
			var sb: StyleBoxFlat = b.get_theme_stylebox(state).duplicate()
			sb.content_margin_left = 4
			sb.content_margin_right = 4
			sb.content_margin_top = 2
			sb.content_margin_bottom = 2
			b.add_theme_stylebox_override(state, sb)
		b.pressed.connect(func():
			var i := choices.find(Game.custom_skin[key])
			Game.custom_skin[key] = choices[posmod(i + step, choices.size())]
			_update_maker()
		)
		row.add_child(b)
		if step < 0:
			row.add_child(label)
	return row


func _swatch_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := UI.style_box(bg, border, width, 6)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	return sb


# ---------------------------------------------------------------------
#  Helpers
# ---------------------------------------------------------------------
## A big, gently turning skull. `get_skin` returns the skin to draw.
func _big_skull(size_px: float, r: float, get_skin: Callable) -> Control:
	var pic := Control.new()
	pic.custom_minimum_size = Vector2(size_px, size_px * 0.95)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.draw.connect(func():
		var c := Vector2(pic.size.x * 0.5, pic.size.y * 0.58)
		Skins.draw_skin(pic, c, r, get_skin.call(), _time, sin(_time * 1.3) * 0.7)
	)
	_pics = _pics.filter(func(p): return is_instance_valid(p))
	_pics.append(pic)
	return pic


func _gem_icon() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(22, 30)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var m := Vector2(11, 15)
		c.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -12), m + Vector2(9, 0), m + Vector2(0, 12), m + Vector2(-9, 0)]), Config.COLOR_GEM)
		c.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -12), m + Vector2(9, 0), m]), Config.COLOR_GEM.lightened(0.5))
	)
	return c


func _dim_layer() -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	add_child(dim)
	dim.add_child(UI.make_center())
	return dim


func _centered(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc
