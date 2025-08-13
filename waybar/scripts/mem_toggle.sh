#!/usr/bin/env bash
# ~/.config/waybar/scripts/mem_toggle.sh
# Toggles display between percentage and absolute usage.
STATE=/tmp/waybar_mem_mode  # 0 = percent, 1 = absolute

toggle() {
  [ -f "$STATE" ] || echo 0 >"$STATE"
  cur=$(cat "$STATE")
  if [ "$cur" = "0" ]; then echo 1 >"$STATE"; else echo 0 >"$STATE"; fi
  pkill -RTMIN+1 waybar 2>/dev/null || true
}

format_human() {
  awk -v bytes="$1" 'BEGIN{
    kib=1024; mib=kib*kib; gib=mib*kib;
    if(bytes>=gib){printf("%.1fG", bytes/gib); }
    else if(bytes>=mib){printf("%.1fM", bytes/mib);}
    else if(bytes>=kib){printf("%.1fK", bytes/kib);}
    else {printf("%dB", bytes);}
  }'
}

if [ "$1" = "toggle" ]; then toggle; exit 0; fi

[ -f "$STATE" ] || echo 0 >"$STATE"
mode=$(cat "$STATE")
# read meminfo
mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')   # kB
mem_free=$(grep -E 'MemAvailable|MemFree' /proc/meminfo | head -n1 | awk '{print $2}')
used_kb=$((mem_total - mem_free))
pct=$(( (used_kb * 100) / mem_total ))
total_bytes=$((mem_total * 1024))
used_bytes=$((used_kb * 1024))
if [ "$mode" = "0" ]; then
  text=" ${pct}%"
  tooltip="${pct}% used"
else
  text=" $(format_human $used_bytes) / $(format_human $total_bytes)"
  tooltip="$(format_human $used_bytes) used of $(format_human $total_bytes)"
fi
jq -n --arg t "$text" --arg tooltip "$tooltip" '{text:$t, tooltip:$tooltip}'

