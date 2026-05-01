# N100 DSI Black Screen Fix for Linux

Kernel patches and workarounds for the black screen issue affecting Intel N100 (Alder Lake) DSI internal displays on Linux.

## Affected Hardware

- Topton P8
- Koosmile P8
- Kingnovy
- Any 8-inch mini laptop with Intel N100 and DSI internal display

## Problem

On boot, the internal DSI display remains black (backlight on) while external HDMI works fine. The display works after a suspend/resume cycle.

### Root Cause

Several issues were identified:

1. **VBT Block 42** contains incorrect panel data (640x480 instead of 800x1280). The correct timings are in Block 58.
2. **DMC firmware** loads after the DSI encoder initializes, causing an assertion failure.
3. **GDM** disables the DSI pipe when HDMI is connected, treating it as secondary.
4. **CDCLK** inherited from BIOS (652800 kHz) is not recalculated on first modeset.

## Solution

A combination of kernel patches and workarounds:

### Kernel Patches
- `intel_ddi.c` — Wait for DMC firmware before initializing DSI encoder
- `intel_modeset_setup.c` — Force full modeset for DSI encoders on first boot
- `intel_dsi.c` — Add proper power cycle delay for panel initialization

### Workarounds
- Auto suspend/resume on boot via `rtcwake`
- Auto suspend/resume when HDMI is connected/disconnected via udev
- GDM monitor configuration to keep DSI as primary display

## Installation

### Requirements

- Ubuntu 25.04 (kernel 7.0.0) or similar
- `linux-source` package
- `build-essential`, `libdw-dev`

### Quick Install

```bash
chmod +x install.sh
sudo ./install.sh
```

## Credits

- Research and patches by [diego-p8](https://github.com/YOUR_USERNAME)
- Original bug report: https://gitlab.freedesktop.org/drm/intel/issues/9063
