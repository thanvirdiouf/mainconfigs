#!/usr/bin/env bash
# Outputs JSON for waybar with fields: text, tooltip
# Click toggles between name-only and speed view. Toggle state saved in /tmp/waybar_net_mode

MODEFILE=/tmp/waybar_net_mode
[ -f "$MODEFILE" ] || echo "name" > "$MODEFILE"

case "$1" in
  click)
    # toggle mode
    cur=$(cat "$MODEFILE")
    if [ "$cur" = "name" ]; then echo "speed" > "$MODEFILE"; else echo "name" > "$MODEFILE"; fi
    exit
    ;;
  *) ;;
esac

MODE=$(cat "$MODEFILE")

# Try to find wireless interface and ESSID
IFACE="$(ip -o link show up | awk -F': ' '{print $2}' | grep -E 'wl|wlan' | head -n1)"
[ -z "$IFACE" ] && IFACE="$(ip -o link show up | awk -F': ' '{print $2}' | head -n1)"

ESSID=""
if [ -n "$IFACE" ]; then
  if command -v iw >/dev/null 2>&1; then
    ESSID=$(iw dev "$IFACE" link 2>/dev/null | awk -F': ' '/SSID/ {print $2}')
  fi
fi

# Get local IP
IP=$(ip -4 addr show dev "$IFACE" 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)

# Get link speeds (using /proc/net/dev counters)
RX1=0; TX1=0
if [ -f /proc/net/dev ]; then
  line=$(grep "${IFACE}:" /proc/net/dev 2>/dev/null)
  if [ -n "$line" ]; then
    RX1=$(echo "$line" | awk '{print $2}')
    TX1=$(echo "$line" | awk '{print $10}')
  fi
fi
sleep 1
RX2=0; TX2=0
if [ -f /proc/net/dev ]; then
  line=$(grep "${IFACE}:" /proc/net/dev 2>/dev/null)
  if [ -n "$line" ]; then
    RX2=$(echo "$line" | awk '{print $2}')
    TX2=$(echo "$line" | awk '{print $10}')
  fi
fi

# Calculate bytes/sec
RXBPS=0; TXBPS=0
if [[ $RX2 -gt 0 && $RX1 -gt 0 ]]; then
  RXBPS=$((RX2 - RX1))
fi
if [[ $TX2 -gt 0 && $TX1 -gt 0 ]]; then
  TXBPS=$((TX2 - TX1))
fi

hr() {
  local b=$1
  if [ "$b" -lt 1024 ]; then echo "${b}B/s"; return; fi
  b=$((b/1024))
  if [ "$b" -lt 1024 ]; then echo "${b}KB/s"; return; fi
  b=$((b/1024))
  echo "${b}MB/s"
}

speedstr="$(hr $RXBPS) / $(hr $TXBPS)"

if [ "$MODE" = "speed" ]; then
  TEXT="${speedstr} "
else
  if [ -n "$ESSID" ]; then
    TEXT="${ESSID} "
  else
    # fallback to interface name
    TEXT="${IFACE:-offline} "
  fi
fi

TOOLTIP="IP: ${IP:-N/A}\nRX: $(hr $RXBPS)\nTX: $(hr $TXBPS)"

jq -n --arg text "$TEXT" --arg tooltip "$TOOLTIP" '{text: $text, tooltip: $tooltip}'
