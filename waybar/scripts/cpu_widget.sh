#!/usr/bin/env bash
# Outputs JSON with text and tooltip. text = overall usage% and temp. tooltip = per-core usage/temps
# This script attempts to be portable. It stores /proc/stat previous values in /tmp for delta calculation.

PREV=/tmp/waybar_cpu_prev

get_usage() {
  # Read aggregate CPU line
  read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
  total=$((user+nice+system+idle+iowait+irq+softirq+steal))
  idleall=$((idle + iowait))
  echo "$total $idleall"
}

prev_total=0; prev_idle=0
if [ -f "$PREV" ]; then
  read prev_total prev_idle < "$PREV"
fi
read total idleall < <(get_usage)

echo "$total $idleall" > "$PREV"

if [ "$prev_total" -gt 0 ]; then
  diff_total=$((total - prev_total))
  diff_idle=$((idleall - prev_idle))
  usage=$(( (1000 * (diff_total - diff_idle) / diff_total + 5) / 10 ))
else
  usage=0
fi

# Get a representative temperature (try hwmon, then thermal_zone)
get_temp() {
  # look for hwmon temp*_input
  for f in /sys/class/hwmon/hwmon*/temp*_input; do
    [ -r "$f" ] || continue
    # temp usually in millidegree
    t=$(cat "$f" 2>/dev/null)
    if [ -n "$t" ]; then
      echo $((t/1000))
      return
    fi
  done
  # fallback to thermal_zone
  for f in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$f" ] || continue
    t=$(cat "$f" 2>/dev/null)
    if [ -n "$t" ]; then
      echo $((t/1000))
      return
    fi
  done
  echo "N/A"
}

TEMP=$(get_temp)
TEXT="${usage}% ${TEMP}°C "

# Build per-core usage + temp tooltip
cores=$(nproc --all)
tooltip=""
for i in $(seq 0 $((cores-1))); do
  # per-core usage using /proc/stat lines starting with cpuN
  line=$(grep "^cpu$i " /proc/stat)
  read _ u n s id w irq si st g gn <<< "$line"
  total=$((u+n+s+id+w+irq+si+st))
  idlec=$((id+w))
  # store per-core prev files
  PREVCORE=/tmp/waybar_cpu_prev_core_$i
  prevt=0; previ=0
  if [ -f "$PREVCORE" ]; then read prevt previ < "$PREVCORE"; fi
  echo "$total $idlec" > "$PREVCORE"
  if [ "$prevt" -gt 0 ]; then
    dt=$((total - prevt))
    di=$((idlec - previ))
    ucore=$(( (1000*(dt-di)/dt +5)/10 ))
  else
    ucore=0
  fi
  # try per-core temp
  ctemp="N/A"
  # look for hwmon temp*_input that mentions core index is unreliable; skip detailed mapping
  # as reasonable fallback attempt sensors if available
  if command -v sensors >/dev/null 2>&1; then
    # try to find "Core i:" line
    ctemp=$(sensors 2>/dev/null | awk -v c=$i '/Core/ && NR>0{gsub("+","",$0); print $3; exit}' )
    # cleanup
    ctemp=${ctemp//°C/}
  fi
  tooltip+="Core $i: ${ucore}% / ${ctemp}°C\\n"
done

jq -n --arg text "$TEXT" --arg tooltip "$tooltip" '{text: $text, tooltip: $tooltip}'
