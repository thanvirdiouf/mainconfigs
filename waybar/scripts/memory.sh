#!/usr/bin/env bash

# CPU usage calculation
cpu_usage=$(grep -m1 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}')

# Choose icon & color
if (( $(echo "$cpu_usage < 30" | bc -l) )); then
    icon=""
    color="#2ecc71" # green
elif (( $(echo "$cpu_usage < 70" | bc -l) )); then
    icon=""
    color="#f1c40f" # yellow
else
    icon=""
    color="#e74c3c" # red
fi

# Output JSON
echo "{\"text\": \"${icon} ${cpu_usage}%\", \"tooltip\": \"CPU Usage: ${cpu_usage}%\", \"class\": \"cpu\", \"color\": \"${color}\"}"

