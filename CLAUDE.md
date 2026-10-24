# SKULLRUN — notes for Claude

A Godot 4.3 platformer. Levels are text files in `levels/` (format in `levels/README.md`).
The website (`website/`) is published to GitHub Pages by `.github/workflows/website.yml`.

## Keep the website in sync

The owner wants the website to grow with the game, with no empty placeholder slots.

- **New level:** give the level file an `about:` line. The website's level list and level
  count are generated from the level files at build time (`website/gen_levels.py`),
  so nothing else is needed. A new theme also needs its colour in `THEME_COLORS` there.
- **New power/ability:** add a card to the `#powers` section of `website/index.html`
  (icon, name, one-line description, the level it unlocks in), and add it to the
  controls section and the in-game How to Play panel (`scripts/ui/title_screen.gd`) if it has a key.
- **New mechanic or hazard:** add a pill to "Strange places" in `#powers`.
- **New enemy or boss:** add a card to `#enemies` with a picture rendered from the
  game's own drawing code, cropped and saved as `website/img/e_<name>.webp`.
- **New world/theme:** consider adding a screenshot to the gallery (`website/img/<name>.webp`).
- Also update the level table in `README.md`.
