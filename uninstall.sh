#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID="heelgueta.omabeacon"
rm -f "$HOME/.config/omarchy/plugins/$PLUGIN_ID"
rm -f "$HOME/.local/bin/omabeacon"
echo "Removed $PLUGIN_ID symlink and CLI link."
