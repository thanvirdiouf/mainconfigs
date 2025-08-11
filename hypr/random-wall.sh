#!/bin/bash
WALL_DIR="$HOME/.config/hypr/wall"
swww init &>/dev/null

while true; do
    WALL=$(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)
    swww img "$WALL" --transition-type any
    sleep 120  # every 30 minutes
done

