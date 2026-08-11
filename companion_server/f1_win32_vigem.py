#!/usr/bin/env python3
"""
F1 Gaming Controller — Windows Virtual Xbox Controller Server
=============================================================
Standalone terminal server. Shows everything in CMD — no GUI needed.

Features:
  - Lists ALL network interfaces with real vs virtual labels
  - Auto-opens Windows Firewall for UDP port 9999
  - Virtual Xbox 360 Controller via ViGEmBus
  - Haptic feedback relay (game vibrations -> phone)
  - Rich live telemetry display in terminal

Requirements:
  pip install vgamepad
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

# ── ANSI Color Helpers ───────────────────────────────────────────────────────
RESET   = "\033[0m"
BOLD    = "\033[1m"
DIM     = "\033[2m"
RED     = "\033[91m"
GREEN   = "\033[92m"
YELLOW  = "\033[93m"
CYAN    = "\033[96m"
WHITE   = "\033[97m"
BG_RED  = "\033[41m"
BG_GREEN = "\033[42m"

VIRTUAL_KEYWORDS = [
    "virtual", "veth", "wsl", "vmware", "tailscale", "loopback",
    "hyper-v", "bluetooth", "isatap", "teredo", "pseudo", "tunnel",
    "6to4", "miniport",
]

def cls():
    os.system("cls" if os.name == "nt" else "clear")

def is_virtual_adapter(name):
    lower = name.lower()
    return any(kw in lower for kw in VIRTUAL_KEYWORDS)

def get_all_interfaces():
    """Get all IPv4 network interfaces using ipconfig on Windows, or socket on Linux."""
    interfaces = []
    
    if os.name == "nt":
        try:
            result = subprocess.run(
                ["ipconfig"], capture_output=True, text=True, timeout=5, encoding="utf-8", errors="replace"
            )
            lines = result.stdout.split("\n")
            current_adapter = None
            for line in lines:
                stripped = line.strip()
                # Adapter header lines end with ":"
                if not stripped.startswith("IPv4") and ":" in line and not line.startswith(" "):
                    current_adapter = stripped.rstrip(":").strip()
                    # Remove "Ethernet adapter " or "Wireless LAN adapter " prefix
                    for prefix in ["Ethernet adapter ", "Wireless LAN adapter "]:
                        if current_adapter.startswith(prefix):
                            current_adapter = current_adapter[len(prefix):]
                elif stripped.startswith("IPv4 Address") and current_adapter:
                    ip = stripped.split(":")[-1].strip()
                    if ip and not ip.startswith("127."):
                        virtual = is_virtual_adapter(current_adapter)
                        interfaces.append((current_adapter, ip, virtual))
        except Exception:
            pass
    
    # Fallback: socket method
    if not interfaces:
        try:
            hostname = socket.gethostname()
            all_ips = socket.getaddrinfo(hostname, None, socket.AF_INET)
            seen = set()
            for info in all_ips:
                ip = info[4][0]
                if ip not in seen and not ip.startswith("127."):
                    seen.add(ip)
                    virtual = ip.startswith("192.168.56.") or ip.startswith("172.16.")
                    name = "VirtualBox" if ip.startswith("192.168.56.") else "Network"
                    interfaces.append((name, ip, virtual))
        except Exception:
            pass
    
    return interfaces


def get_best_ip(interfaces):
    """Pick the best real (non-virtual) IP."""
    for name, ip, virtual in interfaces:
        if not virtual:
            return ip
    # Fallback: try outbound socket trick
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(2)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        pass
    return None


def open_firewall(port):
    """Open the Windows Firewall for UDP port."""
    rule_name = f"F1 Controller UDP {port}"
    status = {"opened": False, "already": False, "error": None}
    try:
        check = subprocess.run(
            ["netsh", "advfirewall", "firewall", "show", "rule", f"name={rule_name}"],
            capture_output=True, text=True, timeout=5
        )
        if "No rules match" not in check.stdout and rule_name in check.stdout:
            status["already"] = True
            status["opened"] = True
            return status

        result = subprocess.run(
            ["netsh", "advfirewall", "firewall", "add", "rule",
             f"name={rule_name}", "dir=in", "action=allow",
             "protocol=UDP", f"localport={port}"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            status["opened"] = True
        else:
            status["error"] = "Run setup.bat as Administrator"
    except FileNotFoundError:
        status["error"] = "netsh not found"
    except Exception as e:
        status["error"] = str(e)
    return status


def print_header():
    print(f"\n{BOLD}{'=' * 72}{RESET}")
    print(f"{BOLD}   F1 GAMING CONTROLLER — WINDOWS VIRTUAL GAMEPAD SERVER{RESET}")
    print(f"{BOLD}{'=' * 72}{RESET}\n")


def print_section(title):
    print(f"  {BOLD}{CYAN}[{title}]{RESET}")


def print_ok(msg):
    print(f"  {GREEN}  ✓ {msg}{RESET}")


def print_warn(msg):
    print(f"  {YELLOW}  ⚠ {msg}{RESET}")


def print_err(msg):
    print(f"  {RED}  ✗ {msg}{RESET}")


def print_network_table(interfaces, best_ip):
    print()
    print_section("NETWORK INTERFACES")
    print()
    print(f"    {'Adapter Name':<35} {'IP Address':<18} {'Status'}")
    print(f"    {'─' * 35} {'─' * 18} {'─' * 15}")
    for name, ip, virtual in interfaces:
        if virtual:
            tag = f"{DIM}VIRTUAL (skip){RESET}"
        elif ip == best_ip:
            tag = f"{GREEN}{BOLD}◀ USE THIS{RESET}"
        else:
            tag = f"{WHITE}Real{RESET}"
        virt_marker = f"{DIM}" if virtual else ""
        print(f"    {virt_marker}{name:<35}{RESET} {CYAN}{ip:<18}{RESET} {tag}")
    
    if not interfaces:
        print_warn("No network interfaces found. Check your connection.")
    print()


def print_divider():
    print(f"  {DIM}{'─' * 68}{RESET}")


def main():
    PORT = 9999
    os.system("")  # Enable ANSI on Windows

    cls()
    print_header()

    # ── 1. Network Discovery ─────────────────────────────────────────────
    interfaces = get_all_interfaces()
    best_ip = get_best_ip(interfaces)
    print_network_table(interfaces, best_ip)

    if best_ip:
        print(f"  {BOLD}  ➤ Enter this IP in the mobile app:{RESET} {CYAN}{BOLD}{best_ip}{RESET}")
    else:
        print_err("Could not detect a usable IP. Run 'ipconfig' manually.")
    print()

    # ── 2. Firewall ──────────────────────────────────────────────────────
    print_section("FIREWALL")
    fw = open_firewall(PORT)
    if fw["already"]:
        print_ok(f"UDP port {PORT} is already allowed through Windows Firewall.")
    elif fw["opened"]:
        print_ok(f"Firewall rule created: UDP port {PORT} open for incoming.")
    else:
        print_err(f"Could not open firewall: {fw['error']}")
        print_warn("Try: Right-click setup.bat → Run as Administrator")
    print()

    # ── 3. Virtual Gamepad ───────────────────────────────────────────────
    print_section("VIRTUAL XBOX CONTROLLER")
    virtual_pad = None
    if not VIGEM_AVAILABLE or vg is None:
        print_warn("'vgamepad' library not installed.")
        print(f"      Run: {CYAN}pip install vgamepad{RESET}")
        print(f"      Server will run in {YELLOW}telemetry-only{RESET} mode.\n")
    else:
        try:
            virtual_pad = vg.VX360Gamepad()
            print_ok("Virtual Xbox 360 Controller registered in Windows!")
        except Exception as e:
            print_err(f"ViGEmBus init failed: {e}")
            print_warn("Install ViGEmBus: https://github.com/nefarius/ViGEmBus/releases")
    print()

    # ── 4. Create Socket ─────────────────────────────────────────────────
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    except Exception:
        pass
    sock.bind(("0.0.0.0", PORT))

    # ── 5. Haptic Feedback Callback ──────────────────────────────────────
    mobile_addr = None

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
            print_ok("Haptic feedback enabled (game vibrations → phone)")
        except Exception:
            print_warn("Haptic callback registration failed")
        print()

    # ── 6. Ready Banner ──────────────────────────────────────────────────
    print(f"  {BOLD}{'═' * 68}{RESET}")
    if best_ip:
        print(f"  {GREEN}{BOLD}  READY!{RESET} Listening on UDP port {CYAN}{PORT}{RESET}")
        print(f"  {BOLD}  Phone App → Enter IP: {CYAN}{best_ip}{RESET} → Tap 'Apply & Save'")
    else:
        print(f"  {GREEN}{BOLD}  READY!{RESET} Listening on UDP port {CYAN}{PORT}{RESET}")
        print(f"  {BOLD}  Run 'ipconfig' to find your IP, then enter it in the phone app.{RESET}")
    print(f"  {BOLD}{'═' * 68}{RESET}")
    print()
    print(f"  {DIM}Waiting for controller connection... (Press Ctrl+C to quit){RESET}")
    print()

    # ── Main Receive Loop ────────────────────────────────────────────────
    packets_this_sec = 0
    total_packets = 0
    last_report = time.time()
    last_steer = 0.0
    last_throttle = 0.0
    last_brake = 0.0
    last_dpad = 0
    last_buttons = 0
    connected = False
    connected_ip = ""
    connection_time = None
    discovery_count = 0

    while True:
        try:
            data, addr = sock.recvfrom(1024)
            now = time.time()

            # ── Auto-Discovery ───────────────────────────────────────────
            if data == b"F1_CONTROLLER_DISCOVER":
                announce = f"F1_HOST_ANNOUNCE:{PORT}".encode("utf-8")
                sock.sendto(announce, addr)
                discovery_count += 1
                if not connected:
                    print(f"  {CYAN}📡 Discovery ping from {addr[0]}:{addr[1]} (#{discovery_count}){RESET}")
                continue

            # ── Validate ─────────────────────────────────────────────────
            if len(data) < 10 or data[0] != 0xF1:
                continue

            # ── Unpack 10-byte HID report ────────────────────────────────
            magic, player_id, seq, steer_raw, throttle_raw, brake_raw, dpad, buttons = struct.unpack(
                ">BBBhBBBH", data[:10]
            )

            steer = steer_raw / 32767.0
            throttle = throttle_raw / 255.0
            brake = brake_raw / 255.0

            last_steer = steer
            last_throttle = throttle
            last_brake = brake
            last_dpad = dpad
            last_buttons = buttons
            packets_this_sec += 1
            total_packets += 1
            mobile_addr = addr

            if not connected:
                connected = True
                connected_ip = addr[0]
                connection_time = now
                print()
                print(f"  {BG_GREEN}{BOLD} CONNECTED {RESET} {GREEN}Controller from {CYAN}{addr[0]}:{addr[1]}{RESET}")
                print(f"  {DIM}Telemetry streaming... gauges updating every second.{RESET}")
                print()

            # ── Heartbeat PONG ───────────────────────────────────────────
            pong = f"F1_HOST_PONG:{seq}".encode("utf-8")
            sock.sendto(pong, addr)

            # ── Feed Virtual Xbox Controller ─────────────────────────────
            if virtual_pad is not None:
                pad = virtual_pad
                pad.reset()
                pad.left_joystick_float(x_value_float=steer, y_value_float=0.0)
                pad.right_trigger_float(value_float=throttle)
                pad.left_trigger_float(value_float=brake)

                if buttons & (1 << 7):
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_RIGHT_SHOULDER)
                if buttons & (1 << 8):
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_LEFT_SHOULDER)
                if buttons & (1 << 0):
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_A)
                if buttons & (1 << 1):
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_Y)
                if buttons & (1 << 2):
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_B)
                if buttons & (1 << 3):
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_X)
                if dpad == 1:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_UP)
                elif dpad == 3:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_RIGHT)
                elif dpad == 5:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_DOWN)
                elif dpad == 7:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_LEFT)

                pad.update()

            # ── Live Telemetry Print ─────────────────────────────────────
            if now - last_report >= 1.0:
                hz = packets_this_sec
                elapsed = int(now - connection_time) if connection_time else 0
                mins, secs = divmod(elapsed, 60)

                # Build visual bars
                steer_pos = int((last_steer + 1) * 15)
                steer_bar = "░" * steer_pos + "█" + "░" * (30 - steer_pos)

                thr_fill = int(last_throttle * 20)
                thr_bar = f"{GREEN}{'█' * thr_fill}{RESET}{'░' * (20 - thr_fill)}"

                brk_fill = int(last_brake * 20)
                brk_bar = f"{RED}{'█' * brk_fill}{RESET}{'░' * (20 - brk_fill)}"

                # Button indicators
                btn_drs   = f"{GREEN}DRS{RESET}"  if buttons & (1 << 0) else f"{DIM}drs{RESET}"
                btn_ers   = f"{YELLOW}ERS{RESET}"  if buttons & (1 << 1) else f"{DIM}ers{RESET}"
                btn_pit   = f"{RED}PIT{RESET}"    if buttons & (1 << 2) else f"{DIM}pit{RESET}"
                btn_radio = f"{CYAN}RAD{RESET}"   if buttons & (1 << 3) else f"{DIM}rad{RESET}"
                btn_up    = f"{WHITE}UP↑{RESET}"   if buttons & (1 << 7) else f"{DIM}up↑{RESET}"
                btn_dn    = f"{WHITE}DN↓{RESET}"   if buttons & (1 << 8) else f"{DIM}dn↓{RESET}"

                # Dpad display
                dpad_map = {0: "·", 1: "↑", 2: "↗", 3: "→", 4: "↘", 5: "↓", 6: "↙", 7: "←", 8: "↖"}
                dpad_str = dpad_map.get(last_dpad, "·")

                print(f"  {CYAN}{hz:>3} Hz{RESET} │ "
                      f"Steer [{steer_bar}] {last_steer:+.2f} │ "
                      f"Thr [{thr_bar}] │ "
                      f"Brk [{brk_bar}]")
                print(f"  {DIM}{total_packets:>5} pkts{RESET} │ "
                      f"{btn_drs} {btn_ers} {btn_pit} {btn_radio} │ "
                      f"Gear {btn_up} {btn_dn} │ "
                      f"D-Pad {dpad_str} │ "
                      f"Uptime {mins:02d}:{secs:02d}")
                print_divider()

                packets_this_sec = 0
                last_report = now

        except KeyboardInterrupt:
            print(f"\n  {YELLOW}Shutting down F1 Virtual Gamepad Server.{RESET}")
            if virtual_pad is not None:
                virtual_pad.reset()
                virtual_pad.update()
            print(f"  Total packets received: {total_packets}")
            sys.exit(0)
        except Exception:
            pass


if __name__ == "__main__":
    main()
