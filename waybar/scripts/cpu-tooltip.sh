#!/bin/bash

# Get CPU temperature from the first thermal zone (adjust if needed)
TEMP=$(cat /sys/class/thermal/thermal_zone7/temp)
TEMP_C=$((TEMP / 1000))

# Get per-core usage with mpstat (requires sysstat package)
# The sed lines format the output neatly
CORE_USAGE=$(mpstat -P ALL 1 1 | awk '/Average:/ && $2 ~ /^[0-9]+$/ {print "Core " $2 ": " 100-$12 "%"}' | sed 's/Core/core /g')

# Combine and format for Waybar tooltip
echo -e " Overall: ${TEMP_C}°C\n${CORE_USAGE}"
