#!/bin/bash

set -e

echo "================================================"
echo " N100 DSI Black Screen Fix - Installer"
echo "================================================"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./install.sh)"
    exit 1
fi

echo "What would you like to do?"
echo ""
echo "1) Install boot fix only (rtcwake on boot)"
echo "2) Install HDMI fix only (rtcwake on HDMI connect/disconnect)"
echo "3) Install both (recommended)"
echo "4) Uninstall everything"
echo ""
read -p "Enter option [1-4]: " OPTION

install_boot_fix() {
    echo ""
    echo "Installing boot fix..."
    cp systemd/dsi-init.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable dsi-init.service
    echo "Boot fix installed and enabled."
}

install_hdmi_fix() {
    echo ""
    echo "Installing HDMI fix..."
    cp scripts/hdmi-dsi-fix.sh /usr/local/bin/
    chmod +x /usr/local/bin/hdmi-dsi-fix.sh
    cp systemd/hdmi-dsi-fix.service /etc/systemd/system/
    cp udev/99-hdmi-dsi.rules /etc/udev/rules.d/
    systemctl daemon-reload
    udevadm control --reload-rules
    udevadm trigger
    echo "HDMI fix installed and enabled."
}

install_gdm_fix() {
    echo ""
    echo "Installing GDM monitor configuration..."
    mkdir -p /etc/gdm3
    cp gdm/monitors.xml /etc/gdm3/
    echo "GDM configuration installed."
}

uninstall() {
    echo ""
    echo "Uninstalling..."
    systemctl disable dsi-init.service 2>/dev/null || true
    systemctl disable hdmi-dsi-fix.service 2>/dev/null || true
    rm -f /etc/systemd/system/dsi-init.service
    rm -f /etc/systemd/system/hdmi-dsi-fix.service
    rm -f /etc/udev/rules.d/99-hdmi-dsi.rules
    rm -f /usr/local/bin/hdmi-dsi-fix.sh
    rm -f /etc/gdm3/monitors.xml
    systemctl daemon-reload
    udevadm control --reload-rules
    echo "Uninstall complete. Please reboot."
}

case $OPTION in
    1)
        install_boot_fix
        install_gdm_fix
        ;;
    2)
        install_hdmi_fix
        install_gdm_fix
        ;;
    3)
        install_boot_fix
        install_hdmi_fix
        install_gdm_fix
        ;;
    4)
        uninstall
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac

echo ""
echo "Note: A reboot is required for all fixes to take effect."
echo ""
echo "================================================"
echo " Installation complete!"
echo " Please reboot your system."
echo "================================================"
