#!/bin/bash

# Set the path to your icons
ICON_PATH="$HOME/.config/rofi/scripts/icons"

# Define options and their corresponding icon files
declare -A options
options=(
    ["Shutdown"]="$ICON_PATH/shutdown.svg"
    ["Reboot"]="$ICON_PATH/reboot.svg"
    ["Lock"]="$ICON_PATH/lock.svg"
    ["Suspend"]="$ICON_PATH/suspend.svg"
    ["Logout"]="$ICON_PATH/logout.svg"
)

# Function to generate Rofi entries with icons
generate_rofi_input() {
    for option in "${!options[@]}"; do
        icon_path="${options[$option]}"
        # Correct format for Rofi with image icons: "Text\0icon\x1f/path/to/icon.svg"
        echo -e "$option\0icon\x1f$icon_path"
    done
}

# Get user choice from Rofi
chosen_entry=$(generate_rofi_input | rofi \
    -dmenu \
    -i \
    -p "Power Menu" \
    -format 's' \
    -theme ~/.config/rofi/themes/catppuccin.rasi \
    -theme-str 'element-icon { size: 48px; }' \
    -theme-str 'listview { columns: 5; lines: 1; }' \
    -theme-str 'window { width: 30%; }'
)

# Execute command based on choice
case "$chosen_entry" in
    "Shutdown")
        systemctl poweroff
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Lock")
        swaylock
        ;;
    "Suspend")
        systemctl suspend
        ;;
    "Logout")
        hyprctl dispatch exit 0
        ;;
esac
