#!/bin/sh
# Install the Pegatron Lucid built-in Wi-Fi fix (Debian/Ubuntu). Run as root.
set -e
[ "$(id -u)" = 0 ] || { echo "run as root"; exit 1; }
cd "$(dirname "$0")"
apt-get install -y acpi-call-dkms
install -m 755 lucid-wlan-enable /usr/local/sbin/lucid-wlan-enable
install -m 644 lucid-wlan-enable.service /etc/systemd/system/lucid-wlan-enable.service
systemctl daemon-reload
systemctl enable --now lucid-wlan-enable.service
rfkill list
