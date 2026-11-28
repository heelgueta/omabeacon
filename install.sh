#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="heelgueta.omabeacon"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
TARGET_LINK="$PLUGINS_DIR/$PLUGIN_ID"
LOCAL_BIN="$HOME/.local/bin"

mkdir -p "$PLUGINS_DIR" "$LOCAL_BIN"

ln -sfn "$REPO_DIR" "$TARGET_LINK"
ln -sfn "$REPO_DIR/bin/omabeacon" "$LOCAL_BIN/omabeacon"
"$REPO_DIR/bin/omabeacon" init

omarchy plugin validate "$REPO_DIR"
echo "Linked $TARGET_LINK -> $REPO_DIR"
echo "CLI installed at $LOCAL_BIN/omabeacon"
echo ""
echo "Next steps (if not already configured):"
echo "  1. Add {\"id\": \"$PLUGIN_ID\"} to ~/.config/omarchy/shell.json (e.g. bar.layout.center)"
echo "  2. Bind a shortcut in ~/.config/hypr/bindings.lua:"
echo "     o.bind(\"SUPER + N\", \"Workspace beacon\", \"omarchy-shell shell toggle $PLUGIN_ID\")"
