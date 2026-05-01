#!/bin/bash

STAMPFILE=/tmp/hdmi-dsi-last-run

# If executed less than 15 seconds ago, ignore
if [ -f "$STAMPFILE" ]; then
    LAST=$(cat "$STAMPFILE")
    NOW=$(date +%s)
    DIFF=$((NOW - LAST))
    if [ "$DIFF" -lt 15 ]; then
        exit 0
    fi
fi

date +%s > "$STAMPFILE"

sleep 5

HDMI_STATUS=$(cat /sys/class/drm/card1-HDMI-A-1/status 2>/dev/null)

if [ "$HDMI_STATUS" = "connected" ] || [ "$HDMI_STATUS" = "disconnected" ]; then
    DSI_STATUS=$(cat /sys/class/drm/card1-DSI-1/status 2>/dev/null)
    if [ "$DSI_STATUS" = "connected" ]; then
        /usr/sbin/rtcwake -u -s 3 -m mem
    fi
fi
