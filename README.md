# Omabeacon

Per-workspace purpose beacons, color tags, local window/process sensing, and demoscene lab FX for [Omarchy](https://omarchy.org/) + Hyprland.

## Features

- **Center Bar Beacon (`BarWidget.qml`)**: Displays your current workspace's custom note and color right next to the clock in the top bar.
- **Instant Quick-Edit Overlay (`BeaconOverlay.qml`)**: Pop open with `SUPER + N`, type what the workspace is about, optionally pick a color (`Ctrl+1..9`), press `Enter`.
- **1–0 Workspace Minimap**: See all tagged workspaces at a glance inside the overlay; click to edit or `Shift+Click` to jump.
- **Local Process/Window Sensing (`omabeacon sense`)**: Zero-API, zero-screenshot local `/proc` + `hyprctl clients -j` inspection that summarizes all terminals and apps in the workspace (e.g. `3×term (nvim@omabeacon, lazygit) + chromium`). Use `Ctrl+S` in the overlay to pre-fill, or toggle **Auto-Sense** as a live fallback for untagged workspaces.
- **Optional Lower-Third Flash HUD**: Toggleable hacker news-bar banner that briefly flashes the workspace number and note in big monospace letters at the bottom of the screen when you switch workspaces, then fades away.
- **Toggleable Lab FX** (right-click the bar widget or pick inside the overlay):
  - `clean` — Crisp native pill
  - `pulse` — Expanding sonar beacon ring & breathing border
  - `copper` — Amiga copperbar sweep & subtle CRT scanlines
  - `scramble` — Demoscene glyph decoder on workspace switch
  - `marquee` — Retro horizontal scroller for long notes
  - `stealth` — Auto-dims after idle, flares on switch or hover

## Install

```bash
./install.sh
```

Add `{"id": "heelgueta.omabeacon"}` to `bar.layout.center` in `~/.config/omarchy/shell.json`, and bind `SUPER + N` in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + N", "Workspace beacon", "omarchy-shell shell toggle heelgueta.omabeacon")
```

## CLI

```bash
omabeacon set 3 "auth refactor" --color "#7dcfff"
omabeacon clear 3
omabeacon fx copper
omabeacon autosense toggle
omabeacon hud toggle
omabeacon sense
```
