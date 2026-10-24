"""Fills the website's level list from the level files.

Every levels/level_XX.txt becomes one entry, using its `name:` and `about:`
lines, so new levels show up on the website automatically.
Usage: python3 website/gen_levels.py build/index.html
"""
import glob
import html
import os
import sys

# Accent colour per theme (the theme's tile_top colour in scripts/config.gd).
THEME_COLORS = {
    "crypt": "#6d5f8f", "graveyard": "#3f7a4a", "bonecaves": "#d8c9a8", "forge": "#ff7b2e",
    "tower": "#e63946", "frost": "#8fd8f0", "wells": "#6bd49a", "ossuary": "#efe4cc",
    "throne": "#ffd166", "abyss": "#4ff0d0",
}


def read_level(path):
    info = {"name": os.path.basename(path)[:-4], "theme": "crypt", "about": ""}
    is_boss = False
    in_map = False
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line == "---":
            in_map = True
            continue
        if in_map:
            if not line.startswith(";") and "K" in line:
                is_boss = True
        elif ":" in line and not line.startswith(";"):
            key, value = line.split(":", 1)
            if key.strip().lower() in info:
                info[key.strip().lower()] = value.strip()
    info["boss"] = is_boss
    return info


def main():
    page = sys.argv[1]
    root = os.path.join(os.path.dirname(__file__), "..")
    paths = sorted(glob.glob(os.path.join(root, "levels", "level_*.txt")))
    items = []
    for p in paths:
        lv = read_level(p)
        color = THEME_COLORS.get(lv["theme"], "#e63946")
        cls = ' class="boss"' if lv["boss"] else ""
        items.append('    <li style="--c:%s"%s><b>%s</b><span>%s</span></li>'
                     % (color, cls, html.escape(lv["name"]), html.escape(lv["about"])))
    text = open(page, encoding="utf-8").read()
    text = text.replace("<!-- LEVEL_LIST -->", "\n".join(items))
    text = text.replace("{{LEVEL_COUNT}}", str(len(items)))
    open(page, "w", encoding="utf-8").write(text)
    print("Website level list: %d levels" % len(items))


main()
