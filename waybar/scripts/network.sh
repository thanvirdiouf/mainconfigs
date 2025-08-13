#!/usr/bin/env bash

iface=$(ip route | awk '/^default/ {print $5}' | head -n1)

if [ -n "$iface" ] && ip link show "$iface" | grep -q "state UP"; then
    ip_addr=$(ip -4 addr show "$iface" | awk '/inet / {print $2}' | cut -d/ -f1)
    icon=""
    color="#3498db" # blue
    text="$iface"
    tooltip="Connected: $iface ($ip_addr)"
else
    icon=""
    color="#e74c3c" # red
    text="disconnected"
    tooltip="No active network connection"
fi

echo "{\"text\": \"${icon} ${text}\", \"tooltip\": \"${tooltip}\", \"class\": \"network\", \"color\": \"${color}\"}"

