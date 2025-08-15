#!/bin/bash

# Directory: ~/.config/rofi/scripts/screenshot.sh
# Make executable: chmod +x ~/.config/rofi/scripts/screenshot.sh

# Define save directory
SAVE_DIR=~/Pictures/Screenshots
mkdir -p "$SAVE_DIR"
FILENAME="$SAVE_DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

# Catppuccin-Mocha colors
background="#1e1e2e"
foreground="#cdd6f4"
selection="#313244"
blue="#89b4fa"

# Options with Nerd Font icons
area="󰆞 Area"
screen="󰍹 Screen"
window="󰖲 Window"

# Get user choice
chosen=$(echo -e "$area\n$screen\n$window" | rofi -dmenu \
    -p "Screenshot" \
    -theme-str "window {background-color: $background;}" \
    -theme-str "element-text {color: $foreground;}" \
    -theme-str "element selected {background-color: $selection;}" \
    -theme-str "inputbar {background-color: $background; text-color: $foreground;}" \
    -theme-str "prompt {background-color: $background; text-color: $blue;}"
)

# Execute command based on choice
case "$chosen" in
    "$area")
        grim -g "$(slurp)" "$FILENAME" && wl-copy < "$FILENAME"
        ;;
    "$screen")
        grim "$FILENAME" && wl-copy < "$FILENAME"
        ;;
    "$window")
        # This requires getting the geometry of the active window
        grim -g "$(hyprctl activewindow | grep 'at:' | cut -d' ' -f2) $(hyprctl activewindow | grep 'size:' | cut -d' ' -f2 | sed 's/,/x/')" "$FILENAME" && wl-copy < "$FILENAME"
        ;;
esac
