@echo off
echo =======================================================
echo   F1 Gaming Controller - Windows PC Setup
echo =======================================================
echo.
echo Step 1: Installing required Python libraries (vgamepad)...
pip install vgamepad

echo.
echo Step 2: Starting the Virtual Controller Receiver...
python f1_win32_vigem.py

pause
