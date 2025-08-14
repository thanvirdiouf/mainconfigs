#!/bin/sh

# This script will attempt to get the GPU temperature, prioritizing NVIDIA.
# For NVIDIA, 'nvidia-smi' must be installed.
# For AMD, it checks standard hwmon sysfs entries.

# Check for NVIDIA GPU
if command -v nvidia-smi &> /dev/null; then
    temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
    echo "${temp}°C"
    exit 0
fi

# Check for AMD GPU by looking for the "amdgpu" hwmon name
for i in /sys/class/hwmon/hwmon*; do
    if [ "$(cat "$i/name")" = "amdgpu" ]; then
        # The temp1_input file contains temperature in millidegrees Celsius
        temp=$(cat "$i/temp1_input")
        echo "$((temp / 1000))°C"
        exit 0
    fi
done

# If no supported GPU is found
echo "N/A"
