# N100 DSI Black Screen Fix for Linux

Kernel patches and workarounds for the black screen issue affecting Intel N100 (Alder Lake) DSI internal displays on Linux.

## Affected Hardware

- Topton P8
- Koosmile P8
- Kingnovy
- Any 8-inch mini laptop with Intel N100 and DSI internal display

## Problem

On boot, the internal DSI display remains black (backlight on) while external HDMI works fine. The display works after a suspend/resume cycle. The same issue occurs when connecting or disconnecting an HDMI monitor.

## Root Cause

Several issues were identified after extensive debugging:

1. **VBT Block 42** contains incorrect panel data (640x480 instead of 800x1280). The correct timings are in Block 58.
2. **DMC firmware** loads after the DSI encoder initializes, causing an assertion failure on first boot.
3. **GDM** disables the DSI pipe when HDMI is connected, treating it as secondary display.
4. **CDCLK** inherited from BIOS (652800 kHz) is not recalculated on first modeset.
5. **Panel power cycle delay** is not respected on first boot since `panel_power_off_time` is 0.

## Solution

A combination of kernel patches and workarounds that together make the display work reliably.

### Kernel Patches
- `intel_ddi.c` — Wait for DMC firmware before initializing DSI encoder
- `intel_modeset_setup.c` — Force full modeset for DSI encoders on first boot
- `intel_dsi.c` — Add proper power cycle delay for panel initialization

### Workarounds
- GRUB parameters for correct panel orientation and EDID firmware
- Auto suspend/resume on boot via `rtcwake`
- Auto suspend/resume when HDMI is connected/disconnected via udev
- GDM monitor configuration to keep DSI as primary display

## Installation

### Requirements

- Ubuntu 25.04 (kernel 7.0.0) or similar
- `git`

### Quick Install

```bash
git clone https://github.com/dascenci/n100-dsi-blackscreen-fix.git
cd n100-dsi-blackscreen-fix
chmod +x install.sh
sudo ./install.sh
```

The installer will ask what you want to install:

1. Boot fix only
2. HDMI fix only
3. Both (recommended)
4. Uninstall everything

A reboot is required after installation.

## Known Limitations

- The kernel patches alone do not fully solve the problem. The `rtcwake` workaround is still required.
- The HDMI fix may take a few seconds to activate after connecting/disconnecting.
- This has only been tested on Ubuntu 25.04 with kernel 7.0.0.

## Contributing

If you have a different kernel version or distro and managed to get it working, please open a PR or issue.

## Credits

- Research and patches by [dascenci](https://github.com/dascenci)
- Original bug report: https://gitlab.freedesktop.org/drm/intel/issues/9063