"""Renames the exported game data (index.pck) to a name based on its contents,
e.g. index-3f2a9c1b7e.pck, and points the game page at it.

Browsers keep their saved copy of a file as long as its name doesn't change,
so without this, players can keep getting the old game after an update.
Usage: python3 website/cache_bust.py build/play
"""
import hashlib
import os
import sys

play = sys.argv[1]
pck = os.path.join(play, "index.pck")
digest = hashlib.sha1(open(pck, "rb").read()).hexdigest()[:10]
new_name = "index-%s.pck" % digest
os.replace(pck, os.path.join(play, new_name))

page = os.path.join(play, "index.html")
html = open(page, encoding="utf-8").read()
assert '"executable":"index"' in html and '"index.pck":' in html, "unexpected Godot web page"
html = html.replace('"executable":"index"', '"executable":"index","mainPack":"%s"' % new_name)
html = html.replace('"index.pck":', '"%s":' % new_name)
open(page, "w", encoding="utf-8").write(html)
print("Game data saved as play/%s" % new_name)
