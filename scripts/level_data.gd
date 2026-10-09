extends RefCounted
## Reads a level text file (see levels/README.md for the format) and turns
## it into a grid of characters plus some settings.

const MIN_HEIGHT := 20  # levels shorter than this get empty sky added on top

const KNOWN_CHARS := ".#-X^~IoPECGBSMVJKWR123456789 "


static func list_level_files() -> PackedStringArray:
	var files := PackedStringArray()
	for f in DirAccess.get_files_at(Config.LEVELS_DIR):
		# In exported games files can show up with a ".remap" suffix.
		var name := f.trim_suffix(".remap")
		if name.begins_with("level_") and name.ends_with(".txt") and not files.has(name):
			files.append(name)
	files.sort()
	var paths := PackedStringArray()
	for f in files:
		paths.append(Config.LEVELS_DIR.path_join(f))
	return paths


## Only reads the settings at the top of the file (fast, for the level menu).
static func read_header(path: String) -> Dictionary:
	var info := {"name": path.get_file().get_basename(), "theme": Config.DEFAULT_THEME}
	var text := FileAccess.get_file_as_string(path)
	for raw in text.split("\n"):
		var line := raw.strip_edges()
		if line == "---":
			break
		_parse_header_line(line, info)
	return info


static func load_level(path: String) -> Dictionary:
	var data := {
		"name": path.get_file().get_basename(),
		"theme": Config.DEFAULT_THEME,
		"abilities": "jump double dash wall",
		"banner": "",
		"signs": {},
		"grid": [],
		"width": 0,
		"height": 0,
	}
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Could not read level file: " + path)
		return data

	var lines := text.replace("\r", "").split("\n")
	var i := 0
	# --- header -------------------------------------------------------
	while i < lines.size():
		var line := lines[i].strip_edges()
		i += 1
		if line == "---":
			break
		_parse_header_line(line, data)

	# --- map blocks (separated by blank lines, placed left to right) ---
	var blocks: Array = []
	var current: Array = []
	while i < lines.size():
		var row := lines[i].strip_edges(false, true)
		i += 1
		if row.is_empty():
			if not current.is_empty():
				blocks.append(current)
				current = []
			continue
		if row.begins_with(";"):  # comment line inside the map
			continue
		current.append(row)
	if not current.is_empty():
		blocks.append(current)

	var height := MIN_HEIGHT
	for b in blocks:
		height = maxi(height, b.size())

	var grid: Array = []
	for y in height:
		grid.append("")
	for b in blocks:
		var w := 0
		for row in b:
			w = maxi(w, row.length())
		var pad_top: int = height - b.size()
		for y in height:
			var row: String = ""
			if y >= pad_top:
				row = b[y - pad_top]
			row = row.replace(" ", ".").rpad(w, ".")
			grid[y] += row

	var width := 0
	for row in grid:
		width = maxi(width, row.length())
	for y in height:
		grid[y] = (grid[y] as String).rpad(width, ".")
		for c in grid[y]:
			if not KNOWN_CHARS.contains(c):
				push_warning("%s: unknown map character '%s' (treated as empty)" % [path.get_file(), c])

	data["grid"] = grid
	data["width"] = width
	data["height"] = height
	return data


static func _parse_header_line(line: String, info: Dictionary) -> void:
	if line.is_empty() or line.begins_with(";") or not line.contains(":"):
		return
	var key := line.get_slice(":", 0).strip_edges().to_lower()
	var value := line.substr(line.find(":") + 1).strip_edges()
	if key.begins_with("sign") and key.length() == 5 and key[4].is_valid_int():
		if not info.has("signs"):
			info["signs"] = {}
		info["signs"][key[4]] = value.replace("\\n", "\n")
	elif key in ["name", "theme", "abilities", "banner"]:
		info[key] = value.replace("\\n", "\n")
