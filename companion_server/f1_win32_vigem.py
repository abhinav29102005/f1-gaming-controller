#!/usr/bin/env python3
"""
F1 Gaming Controller — Windows Virtual Xbox Controller Server
=============================================================
Standalone server that receives UDP controller packets from the F1 Controller
mobile app and feeds them into a native Windows Virtual Xbox 360 Controller
via the ViGEmBus driver.

Features:
  - Smart IP detection (skips VirtualBox/VMware/WSL virtual adapters)
  - Auto-discovery responder (mobile app finds this PC automatically)
  - Heartbeat PONG for connection status on mobile
  - Haptic feedback relay (game vibrations -> phone vibration)
  - Real-time telemetry display in terminal

Requirements:
  pip install vgamepad
  (ViGEmBus driver installs automatically with vgamepad)
"""

import importlib
import os
import socket
import struct
import subprocess
import sys
import time

# ── ViGEmBus Import ──────────────────────────────────────────────────────────
try:
    vg = importlib.import_module("vgamepad")
    VIGEM_AVAILABLE = True
except (ImportError, Exception):
    vg = None
    VIGEM_AVAILABLE = False

# ── Virtual Adapter Blacklist ────────────────────────────────────────────────
VIRTUAL_ADAPTER_KEYWORDS = [
    "virtual", "veth", "wsl", "vmware", "tailscale", "loopback",
    "hyper-v", "bluetooth", "isatap", "teredo",
]

def get_real_ip():
    """Get the real LAN/Hotspot IP, skipping virtual adapters."""
    try:
        # Method 1: Use netifaces-like approach via socket connection trick
        # This connects (without sending data) to a public IP to determine
        # which network interface the OS would use for outbound traffic.
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(2)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        if ip and not ip.startswith("127."):
            return ip
    except Exception:
        pass

    # Method 2: Enumerate all interfaces and pick the best one
    try:
        hostname = socket.gethostname()
        all_ips = socket.getaddrinfo(hostname, None, socket.AF_INET)
        for info in all_ips:
            ip = info[4][0]
            if ip.startswith("127."):
                continue
            # Skip common VirtualBox/VMware subnets
            if ip.startswith("192.168.56.") or ip.startswith("172.16."):
                continue
            return ip
    except Exception:
        pass

    return "Could not detect — run 'ipconfig' manually"


def open_firewall_port(port):
    """Attempt to open the UDP firewall port (requires admin)."""
    rule_name = f"F1 Controller UDP {port}"
    try:
        # Check if rule already exists
        check = subprocess.run(
            ["netsh", "advfirewall", "firewall", "show", "rule", f"name={rule_name}"],
            capture_output=True, text=True, timeout=5
        )
        if "No rules match" not in check.stdout and rule_name in check.stdout:
            print(f"  [OK] Firewall rule '{rule_name}' already exists.")
            return True

        # Create the rule
        result = subprocess.run(
            ["netsh", "advfirewall", "firewall", "add", "rule",
             f"name={rule_name}", "dir=in", "action=allow",
             "protocol=UDP", f"localport={port}"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            print(f"  [OK] Firewall rule created for UDP port {port}.")
            return True
        else:
            print(f"  [WARNING] Could not create firewall rule (need admin?): {result.stderr.strip()}")
            return False
    except FileNotFoundError:
        print("  [WARNING] 'netsh' not found. Firewall rule not created.")
        return False
    except Exception as e:
        print(f"  [WARNING] Firewall setup failed: {e}")
        return False


def main():
    PORT = 9999

    os.system("")  # Enable ANSI colors on Windows terminal

    print()
    print("=" * 70)
    print("  F1 GAMING CONTROLLER — WINDOWS VIRTUAL GAMEPAD SERVER")
    print("=" * 70)
    print()

    # ── Step 1: Detect Real IP ───────────────────────────────────────────
    real_ip = get_real_ip()
    print(f"  [NETWORK] Your PC's IP Address: \033[96m{real_ip}\033[0m")
    print(f"            Enter this IP in the mobile app's 'Host IP' field.")
    print()

    # ── Step 2: Open Firewall ────────────────────────────────────────────
    print("  [FIREWALL] Checking Windows Firewall...")
    open_firewall_port(PORT)
    print()

    # ── Step 3: Initialize Virtual Gamepad ───────────────────────────────
    virtual_pad = None
    mobile_addr = None  # Track the connected mobile device for haptics

    if not VIGEM_AVAILABLE or vg is None:
        print("  [WARNING] 'vgamepad' library not installed.")
        print("  To enable virtual Xbox controller, run:  pip install vgamepad")
        print("  Running in telemetry-only mode...\n")
    else:
        print("  [GAMEPAD] Initializing Virtual Xbox 360 Controller...")
        try:
            virtual_pad = vg.VX360Gamepad()
            print("  [OK] Virtual Xbox 360 Controller registered in Windows!")
        except Exception as e:
            print(f"  [ERROR] Could not initialize ViGEmBus: {e}")
            print("  Make sure ViGEmBus driver is installed.")
            virtual_pad = None

    # ── Step 4: Create UDP Socket ────────────────────────────────────────
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    except Exception:
        pass
    sock.bind(("0.0.0.0", PORT))

    # ── Step 5: Register Haptic Feedback Callback ────────────────────────
    if virtual_pad is not None:
        def rumble_callback(client, target, large_motor, small_motor, led_number, user_data):
            nonlocal mobile_addr
            if mobile_addr is not None:
                try:
                    vib_msg = f"F1_VIB:{large_motor}:{small_motor}".encode("utf-8")
                    sock.sendto(vib_msg, mobile_addr)
                except Exception:
                    pass

        try:
            virtual_pad.register_notification(callback_function=rumble_callback)
            print("  [OK] Haptic feedback (game vibrations -> phone) enabled!")
        except Exception as e:
            print(f"  [WARNING] Haptic callback failed: {e}")

    print()
    print("=" * 70)
    print(f"  READY! Listening on UDP port {PORT}...")
    print(f"  Open the F1 Controller app on your phone,")
    print(f"  enter IP: \033[96m{real_ip}\033[0m and tap 'Apply & Save'.")
    print("=" * 70)
    print()
    print("  Waiting for controller connection...\n")

    # ── Main Receive Loop ────────────────────────────────────────────────
    packets_this_sec = 0
    last_report = time.time()
    last_steer = 0.0
    last_throttle = 0.0
    last_brake = 0.0
    connected = False

    while True:
        try:
            data, addr = sock.recvfrom(1024)
            now = time.time()

            # ── Auto-Discovery ───────────────────────────────────────────
            if data == b"F1_CONTROLLER_DISCOVER":
                announce = f"F1_HOST_ANNOUNCE:{PORT}".encode("utf-8")
                sock.sendto(announce, addr)
                if not connected:
                    print(f"  [DISCOVERY] Phone found us from {addr[0]}:{addr[1]}")
                continue

            # ── Validate Packet ──────────────────────────────────────────
            if len(data) < 10 or data[0] != 0xF1:
                continue

            # ── Unpack 10-byte binary HID report ─────────────────────────
            magic, player_id, seq, steer_raw, throttle_raw, brake_raw, dpad, buttons = struct.unpack(
                ">BBBhBBBH", data[:10]
            )

            p_id = player_id & 0x03
            steer = steer_raw / 32767.0
            throttle = throttle_raw / 255.0
            brake = brake_raw / 255.0

            last_steer = steer
            last_throttle = throttle
            last_brake = brake
            packets_this_sec += 1

            # Track mobile device address for haptic feedback
            mobile_addr = addr

            if not connected:
                connected = True
                print(f"\n  \033[92m[CONNECTED]\033[0m Controller from {addr[0]}:{addr[1]}")
                print(f"  Telemetry streaming at ~250 Hz...\n")

            # ── Send Heartbeat PONG ──────────────────────────────────────
            pong = f"F1_HOST_PONG:{seq}".encode("utf-8")
            sock.sendto(pong, addr)

            # ── Feed Virtual Xbox Controller ─────────────────────────────
            if virtual_pad is not None:
                pad = virtual_pad
                pad.reset()

                # Steering -> Left Thumbstick X
                pad.left_joystick_float(x_value_float=steer, y_value_float=0.0)

                # Throttle -> Right Trigger
                pad.right_trigger_float(value_float=throttle)

                # Brake -> Left Trigger
                pad.left_trigger_float(value_float=brake)

                # Gear Paddles -> Shoulder Buttons
                if buttons & (1 << 7):  # Upshift -> RB
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_RIGHT_SHOULDER)
                if buttons & (1 << 8):  # Downshift -> LB
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_LEFT_SHOULDER)

                # Action Buttons
                if buttons & (1 << 0):  # DRS -> A
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_A)
                if buttons & (1 << 1):  # ERS -> Y
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_Y)
                if buttons & (1 << 2):  # Pit Limiter -> B
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_B)
                if buttons & (1 << 3):  # Radio -> X
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_X)

                # D-Pad Hat Switch
                if dpad == 1:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_UP)
                elif dpad == 3:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_RIGHT)
                elif dpad == 5:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_DOWN)
                elif dpad == 7:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_LEFT)

                pad.update()

            # ── Print Telemetry Every Second ──────────────────────────────
            if now - last_report >= 1.0:
                hz = packets_this_sec
                bar_steer = int((last_steer + 1) * 10)
                bar_throttle = int(last_throttle * 20)
                bar_brake = int(last_brake * 20)
                print(
                    f"  [{hz:>3} Hz] "
                    f"Steer: {'█' * bar_steer}{'░' * (20 - bar_steer)} {last_steer:+.2f} | "
                    f"Throt: \033[92m{'█' * bar_throttle}\033[0m{'░' * (20 - bar_throttle)} | "
                    f"Brake: \033[91m{'█' * bar_brake}\033[0m{'░' * (20 - bar_brake)}"
                )
                packets_this_sec = 0
                last_report = now

        except KeyboardInterrupt:
            print("\n  Shutting down F1 Virtual Gamepad Server.")
            if virtual_pad is not None:
                virtual_pad.reset()
                virtual_pad.update()
            sys.exit(0)
        except Exception:
            pass


if __name__ == "__main__":
    main()
