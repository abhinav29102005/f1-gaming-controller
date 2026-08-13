#!/bin/bash
echo ""
echo "========================================================"
echo "  F1 GAMING CONTROLLER — PC SETUP (Linux/macOS)"
echo "========================================================"
echo ""

command -v python3 &>/dev/null || { echo "  [ERROR] Python 3 not found."; exit 1; }
echo "  Python 3 found."
echo ""

echo "  [1/1] Installing dependencies..."
pip3 install vgamepad --quiet 2>/dev/null || pip install vgamepad --quiet 2>/dev/null || true

echo ""
echo "  Starting server..."
echo ""

python3 f1_win32_vigem.py "$@"
