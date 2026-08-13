@echo off
title F1 Gaming Controller - PC Server
color 0F
setlocal

echo.
echo ============================================================
echo   F1 GAMING CONTROLLER - WINDOWS PC SERVER SETUP
echo ============================================================
echo.

:: Python check
python --version >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] Python not found.
    echo   Install Python 3 from https://python.org
    echo   Check "Add Python to PATH" during install.
    echo.
    pause & exit /b 1
)

:: Python version check
for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PYVER=%%v
echo   Python %PYVER% found.
echo.

:: Install vgamepad
echo   [1/2] Installing vgamepad...
pip install vgamepad --quiet --disable-pip-version-check
if errorlevel 1 (
    echo   [WARNING] vgamepad install failed.
    echo   If ViGEmBus is not installed, get it from:
    echo   https://github.com/nefarius/ViGEmBus/releases
) else (
    echo   vgamepad ready.
)
echo.

:: Firewall
echo   [2/2] Opening firewall port 9999...
netsh advfirewall firewall show rule name="F1 Controller UDP 9999" >nul 2>&1
if errorlevel 1 (
    netsh advfirewall firewall add rule name="F1 Controller UDP 9999" dir=in action=allow protocol=UDP localport=9999 >nul 2>&1
    if errorlevel 1 (
        echo   [WARNING] Firewall rule failed - run as Administrator if connection fails.
    ) else (
        echo   Firewall port 9999 opened.
    )
) else (
    echo   Firewall port 9999 already open.
)
echo.

echo ============================================================
echo.

:: Check for --slave flag (launched from Flutter app)
echo %* | findstr /i "slave" >nul 2>&1
if not errorlevel 1 (
    python f1_win32_vigem.py --slave
    exit /b 0
)

python f1_win32_vigem.py
echo.
pause
