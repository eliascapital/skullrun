#!/usr/bin/env bash
# Builds the SKULLRUN website into ./build:
#   build/index.html ...  the landing page (copied from website/)
#   build/play/           the game, exported for the web by Godot
# Usage: website/build.sh [path-to-godot]   (needs Godot 4.3 + its web export templates)
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${1:-godot}"

rm -rf build
mkdir -p build/play
# First run imports fonts/images (it may print errors before the import is done).
"$GODOT" --headless --path . --import || true
"$GODOT" --headless --path . --export-release "Web" build/play/index.html
test -s build/play/index.wasm
test -s build/play/index.pck

cp -r website/. build/
rm -f build/build.sh build/.gdignore build/gen_levels.py
python3 website/gen_levels.py build/index.html
touch build/.nojekyll
echo "Website built in ./build"
