#!/bin/bash
# F1 Gaming Controller — Linux/macOS Setup
# Installs dependencies and launches the virtual gamepad server.

echo ""
echo "========================================================"
echo "  F1 GAMING CONTROLLER — PC SETUP (Linux/macOS)"
echo "========================================================"
echo ""

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "  [ERROR] Python 3 not found. Install it with:"
    echo "    sudo apt install python3 python3-pip   (Debian/Ubuntu)"
    echo "    brew install python3                    (macOS)"
    exit 1
fi

echo "  [1/2] Installing dependencies..."
pip3 install vgamepad --quiet --disable-pip-version-check 2>/dev/null || \
pip install vgamepad --quiet --disable-pip-version-check 2>/dev/null || \
echo "  [NOTE] vgamepad may only work on Windows. Server will run in telemetry mode."

echo ""
echo "  [2/2] Starting server..."
echo ""

python3 f1_win32_vigem.py
