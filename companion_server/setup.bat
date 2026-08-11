@echo off
title F1 Gaming Controller - Windows Setup
color 0F

echo.
echo ========================================================
echo   F1 GAMING CONTROLLER - WINDOWS PC SETUP
echo ========================================================
echo.
echo   This script will:
echo     1. Install required Python libraries (vgamepad)
echo     2. Open Windows Firewall for UDP port 9999
echo     3. Launch the Virtual Xbox Controller Server
echo.
echo --------------------------------------------------------
echo.

:: Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] Python is not installed or not in PATH!
    echo   Please install Python 3 from https://python.org
    echo   Make sure to check "Add Python to PATH" during install.
    echo.
    pause
    exit /b 1
)

echo   [1/3] Installing vgamepad library...
pip install vgamepad --quiet --disable-pip-version-check
echo        Done.
echo.

echo   [2/3] Opening firewall for UDP port 9999...
netsh advfirewall firewall add rule name="F1 Controller UDP 9999" dir=in action=allow protocol=UDP localport=9999 >nul 2>&1
if errorlevel 1 (
    echo        [WARNING] Could not open firewall. Try running as Administrator.
) else (
    echo        Done.
)
echo.

echo   [3/3] Starting Virtual Xbox Controller Server...
echo.
echo ========================================================
echo.

python f1_win32_vigem.py

echo.
pause
