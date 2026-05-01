#!/bin/bash

# Ignore events during first 60 seconds of boot
UPTIME=$(cut -d. -f1 /proc/uptime)
if [ "$UPTIME" -lt 60 ]; then
    exit 0
fi

LOCKFILE=/tmp/hdmi-dsi-fix.lock
exec 9>"$LOCKFILE"
flock -n 9 || exit 0

sleep 5

HDMI_STATUS=$(cat /sys/class/drm/card1-HDMI-A-1/status 2>/dev/null)

if [ "$HDMI_STATUS" = "connected" ] || [ "$HDMI_STATUS" = "disconnected" ]; then
    DSI_STATUS=$(cat /sys/class/drm/card1-DSI-1/status 2>/dev/null)
    if [ "$DSI_STATUS" = "connected" ]; then
        /usr/sbin/rtcwake -u -s 3 -m mem
    fi
fi
