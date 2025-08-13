#!/usr/bin/env bash
# Outputs JSON that shows memory percentage or absolute depending on toggle state saved in /tmp/waybar_mem_mode
MODEFILE=/tmp/waybar_mem_mode
[ -f "$MODEFILE" ] || echo "percent" > "$MODEFILE"

if [ "$1" = "click" ]; then
  cur=$(cat "$MODEFILE")
  if [ "$cur" = "percent" ]; then echo "absolute" > "$MODEFILE"; else echo "percent" > "$MODEFILE"; fi
  exit
fi

MODE=$(cat "$MODEFILE")
# use /proc/meminfo
mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
mem_used_kb=$((mem_total - mem_avail))
mem_percent=$(( (mem_used_kb * 100) / mem_total ))

if [ "$MODE" = "percent" ]; then
  TEXT="${mem_percent}% "
else
  # Convert to human readable
  hr() {
    local k=$1
    if [ $k -lt 1024 ]; then echo "${k}KB"; return; fi
    m=$((k/1024))
    if [ $m -lt 1024 ]; then echo "${m}MB"; return; fi
    echo "$((m/1024))GB"
  }
  TEXT="$(hr $mem_used_kb) / $(hr $mem_total) "
fi

# Provide tooltip with both representations
TOOLTIP="${mem_percent}% — ${mem_used_kb} KB used"
jq -n --arg text "$TEXT" --arg tooltip "$TOOLTIP" '{text: $text, tooltip: $tooltip}'

