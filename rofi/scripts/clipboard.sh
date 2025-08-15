#!/bin/bash

# Directory: ~/.config/rofi/scripts/clipboard.sh
# Make executable: chmod +x ~/.config/rofi/scripts/clipboard.sh

# Ensure the cliphist daemon is running in the background
# You should add this to your hyprland.conf: exec-once = wl-paste --watch cliphist store

cliphist list | rofi -dmenu -p "Clipboard" | cliphist decode | wl-copy
