#!/bin/bash
set -e 

cd "$(dirname "$0")"

if [ "$EUID" -ne 0 ]; then
  echo "Requesting root privileges..."
  sudo "$0" "$@"
  exit $?
fi

INTERFACE="enx9cebe8b97bfa"
MY_IP="192.168.1.20/24"
CAMERA_IP="192.168.1.10"
APP_NAME="./cameraconfig"
UDP_PORT=5600

echo "--- STARTING SETUP (UDP PORT $UDP_PORT) ---"

if [ ! -f "$APP_NAME" ]; then
    echo "Error: File '$APP_NAME' not found!"
    exit 1
fi
chmod +x "$APP_NAME"

echo "[1/5] Checking libraries..."
INSTALL_LIST=""
if ! dpkg -s libssh-dev >/dev/null 2>&1; then 
    INSTALL_LIST="$INSTALL_LIST libssh-dev"
fi

if ! command -v gst-launch-1.0 >/dev/null 2>&1; then 
    INSTALL_LIST="$INSTALL_LIST gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libav"
fi

if [ ! -z "$INSTALL_LIST" ]; then
    echo "Installing missing packages: $INSTALL_LIST"
    apt update -qq && apt install -y $INSTALL_LIST
fi

echo "[2/5] Configuring network interface..."
ip link set $INTERFACE up
ip addr add $MY_IP dev $INTERFACE 2>/dev/null || true

echo "[3/5] Waiting for camera connection..."
until ping -c 1 -W 1 $CAMERA_IP >/dev/null 2>&1; do 
    echo -n "."
    sleep 1
done
echo ""
echo "Camera is online."

echo "Running configuration tool..."
$APP_NAME

echo "[4/5] Waiting for camera reboot (25s)..."
sleep 25

echo "Waiting for network recovery..."
until ping -c 1 -W 1 $CAMERA_IP >/dev/null 2>&1; do 
    echo -n "."
    sleep 1
done
echo ""
echo "Network is back."

echo "[5/5] Starting UDP stream viewer..."
REAL_USER=${SUDO_USER:-$USER}

sudo -u $REAL_USER gst-launch-1.0 udpsrc port=$UDP_PORT \
    caps="application/x-rtp, media=video, encoding-name=H264, payload=96" \
    ! rtph264depay ! avdec_h264 ! autovideosink sync=false
