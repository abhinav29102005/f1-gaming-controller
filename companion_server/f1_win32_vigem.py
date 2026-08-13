#!/usr/bin/env python3
"""
F1 Gaming Controller — Windows Virtual Xbox Controller Server
Requires: pip install vgamepad
"""

import importlib, os, socket, select, struct, subprocess, sys, time, signal

# ── ViGEmBus ─────────────────────────────────────────────────────────
try:
    vg = importlib.import_module("vgamepad")
    VIGEM_AVAILABLE = True
except (ImportError, Exception):
    vg = None
    VIGEM_AVAILABLE = False

# ── ANSI ─────────────────────────────────────────────────────────────
RESET="\033[0m"; BOLD="\033[1m"; DIM="\033[2m"
RED="\033[91m"; GREEN="\033[92m"; YELLOW="\033[93m"
CYAN="\033[96m"; WHITE="\033[97m"
BG_GREEN="\033[42m"

VIRTUAL_KEYWORDS = ["virtual","veth","wsl","vmware","tailscale","loopback",
                    "hyper-v","bluetooth","isatap","teredo","pseudo","tunnel","6to4","miniport"]

def cls(): os.system("cls" if os.name=="nt" else "clear")

def is_virtual(name):
    return any(k in name.lower() for k in VIRTUAL_KEYWORDS)

def get_interfaces():
    ifaces = []
    if os.name == "nt":
        try:
            r = subprocess.run(["ipconfig"], capture_output=True, text=True, timeout=5, encoding="utf-8", errors="replace")
            adapter = None
            for line in r.stdout.split("\n"):
                s = line.strip()
                if not s.startswith("IPv4") and ":" in line and not line.startswith(" "):
                    adapter = s.rstrip(":").strip()
                    for p in ["Ethernet adapter ","Wireless LAN adapter "]:
                        if adapter.startswith(p): adapter = adapter[len(p):]
                elif s.startswith("IPv4 Address") and adapter:
                    ip = s.split(":")[-1].strip()
                    if ip and not ip.startswith("127.") and not is_virtual(adapter):
                        ifaces.append((adapter, ip))
        except Exception: pass
    if not ifaces:
        try:
            for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
                ip = info[4][0]
                if not ip.startswith("127."):
                    ifaces.append(("Network", ip))
        except Exception: pass
    return ifaces

def print_header():
    print(f"\n{BOLD}{'='*68}{RESET}")
    print(f"{BOLD}   F1 GAMING CONTROLLER — WINDOWS VIRTUAL GAMEPAD SERVER{RESET}")
    print(f"{BOLD}{'='*68}{RESET}\n")

def open_firewall(port):
    rule = f"F1 Controller UDP {port}"
    try:
        c = subprocess.run(["netsh","advfirewall","firewall","show","rule",f"name={rule}"],
                           capture_output=True, text=True, timeout=5)
        if rule in c.stdout: return True
        r = subprocess.run(["netsh","advfirewall","firewall","add","rule",
                             f"name={rule}","dir=in","action=allow","protocol=UDP",f"localport={port}"],
                           capture_output=True, text=True, timeout=10)
        return r.returncode == 0
    except Exception: return False

def make_socket(port):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 4 * 1024 * 1024)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 512 * 1024)
    try: s.setsockopt(socket.IPPROTO_IP, socket.IP_TOS, 0xB8)
    except Exception: pass
    s.bind(("0.0.0.0", port))
    s.setblocking(False)
    return s

def main():
    PORT = 9999
    SLAVE = "--slave" in sys.argv
    os.system("")  # enable ANSI on Windows

    cls()
    print_header()

    # Network interfaces — clean list, no labels
    ifaces = get_interfaces()
    print(f"  {BOLD}{CYAN}[NETWORK INTERFACES]{RESET}\n")
    print(f"    {'Adapter':<35} {'IP Address'}")
    print(f"    {'─'*35} {'─'*18}")
    for name, ip in ifaces:
        print(f"    {name:<35} {CYAN}{ip}{RESET}")
    if not ifaces:
        print(f"    {YELLOW}No network interfaces found.{RESET}")
    print()

    # Firewall
    fw = open_firewall(PORT)
    if fw: print(f"  {GREEN}  ✓ Firewall: UDP port {PORT} open{RESET}")
    else:   print(f"  {YELLOW}  ⚠ Firewall: Run as Administrator if connection fails{RESET}")
    print()

    # Virtual gamepad
    virtual_pad = None
    if not VIGEM_AVAILABLE:
        print(f"  {YELLOW}  ⚠ vgamepad not installed — run: pip install vgamepad{RESET}")
        print(f"    Also install ViGEmBus: https://github.com/nefarius/ViGEmBus/releases\n")
    else:
        try:
            virtual_pad = vg.VX360Gamepad()
            print(f"  {GREEN}  ✓ Virtual Xbox 360 Controller ready{RESET}\n")
        except Exception as e:
            print(f"  {RED}  ✗ ViGEmBus error: {e}{RESET}")
            print(f"    Install ViGEmBus: https://github.com/nefarius/ViGEmBus/releases\n")

    # Socket
    sock = make_socket(PORT)
    mobile_addr = None

    # Haptic callback
    if virtual_pad is not None:
        def rumble_cb(client, target, large, small, led, user_data):
            if mobile_addr and (large > 30 or small > 30):
                try: sock.sendto(f"F1_VIB:{large}:{small}".encode(), mobile_addr)
                except Exception: pass
        try: virtual_pad.register_notification(callback_function=rumble_cb)
        except Exception: pass

    print(f"  {BOLD}{'═'*68}{RESET}")
    print(f"  {GREEN}{BOLD}  READY{RESET} — Listening on UDP :{PORT}")
    print(f"  {BOLD}{'═'*68}{RESET}\n")
    print(f"  {DIM}Waiting for connection... (Ctrl+C to quit){RESET}\n")

    # ── State ──────────────────────────────────────────────────────────
    pkt_total = 0
    pkt_window = [0, 0, 0, 0]  # 4-sample rolling window for Hz
    pkt_win_idx = 0
    pkt_this_sec = 0
    last_hz_time = time.time()
    last_packet_time = 0.0
    last_report = time.time()
    connected = False
    conn_time = None
    disc_count = 0
    sent_times = {}  # seq -> send_timestamp for RTT
    ping_samples = []
    ping_min = 999.0; ping_avg = 0.0; ping_max = 0.0

    # Last telemetry values
    tl = {"steer": 0.0, "thr": 0.0, "brk": 0.0, "dpad": 0, "buttons": 0}

    def graceful_exit(*args):
        print(f"\n  {YELLOW}Shutting down...{RESET}")
        if virtual_pad:
            try: virtual_pad.reset(); virtual_pad.update()
            except Exception: pass
        print(f"  Total packets: {pkt_total}")
        if not SLAVE: 
            try: input("  Press Enter to exit...")
            except Exception: pass
        sys.exit(0)

    signal.signal(signal.SIGTERM, graceful_exit)
    signal.signal(signal.SIGINT, graceful_exit)
    try: signal.signal(signal.SIGBREAK, graceful_exit)
    except AttributeError: pass

    # ── Main Loop (outer restart wrapper) ────────────────────────────
    while True:
        try:
            while True:
                now = time.time()

                # Non-blocking receive with 10ms select timeout
                readable, _, _ = select.select([sock], [], [], 0.01)
                if not readable:
                    # Hz tick
                    if now - last_hz_time >= 1.0:
                        pkt_window[pkt_win_idx % 4] = pkt_this_sec
                        pkt_win_idx += 1
                        pkt_this_sec = 0
                        last_hz_time = now
                    
                    # Stale connection check
                    if connected and (now - last_packet_time) > 5.0:
                        connected = False
                        print(f"\n  {YELLOW}Connection lost — waiting for reconnect...{RESET}\n")
                    continue

                data, addr = sock.recvfrom(1024)
                now = time.time()

                # Discovery
                if data == b"F1_CONTROLLER_DISCOVER":
                    disc_count += 1
                    sock.sendto(f"F1_HOST_ANNOUNCE:{PORT}".encode(), addr)
                    if not connected:
                        print(f"  {CYAN}📡 Discovery #{disc_count} from {addr[0]}{RESET}")
                    continue

                # Binary HID packet
                if len(data) < 10 or data[0] != 0xF1: continue

                magic, player_id, seq, steer_raw, thr_raw, brk_raw, dpad, buttons = struct.unpack(">BBBhBBBH", data[:10])

                steer = steer_raw / 32767.0
                thr = thr_raw / 255.0
                brk = brk_raw / 255.0
                tl.update({"steer":steer, "thr":thr, "brk":brk, "dpad":dpad, "buttons":buttons})

                pkt_total += 1
                pkt_this_sec += 1
                mobile_addr = addr
                last_packet_time = now

                if not connected:
                    connected = True
                    conn_time = now
                    print(f"\n  {BG_GREEN}{BOLD} CONNECTED {RESET} {GREEN}{addr[0]}:{addr[1]}{RESET}\n")

                # PONG with RTT tracking
                sent_times[seq] = now
                pong = f"F1_HOST_PONG:{seq}".encode()
                sock.sendto(pong, addr)
                # Clean up old sent_times (keep last 64)
                if len(sent_times) > 64:
                    oldest = sorted(sent_times.keys())[0]
                    del sent_times[oldest]

                # Feed virtual gamepad
                if virtual_pad is not None:
                    pad = virtual_pad
                    pad.reset()
                    pad.left_joystick_float(x_value_float=steer, y_value_float=0.0)
                    pad.right_trigger_float(value_float=thr)
                    pad.left_trigger_float(value_float=brk)
                    if buttons & (1 << 7):  pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_RIGHT_SHOULDER)
                    if buttons & (1 << 8):  pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_LEFT_SHOULDER)
                    if buttons & (1 << 9)  or buttons & (1 << 0): pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_A)
                    if buttons & (1 << 10) or buttons & (1 << 2): pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_B)
                    if buttons & (1 << 11) or buttons & (1 << 3): pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_X)
                    if buttons & (1 << 12) or buttons & (1 << 1): pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_Y)
                    if buttons & (1 << 13): pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_START)
                    if buttons & (1 << 14): pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_BACK)
                    dpad_map = {
                        1: [vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_UP],
                        2: [vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_UP, vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_RIGHT],
                        3: [vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_RIGHT],
                        4: [vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_DOWN, vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_RIGHT],
                        5: [vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_DOWN],
                        6: [vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_DOWN, vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_LEFT],
                        7: [vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_LEFT],
                        8: [vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_UP, vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_LEFT],
                    }
                    for btn in dpad_map.get(dpad, []):
                        pad.press_button(btn)
                    pad.update()

                # Live telemetry every 1s
                if now - last_report >= 1.0:
                    hz_avg = int(sum(pkt_window) / max(1, min(4, pkt_win_idx)))
                    elapsed = int(now - conn_time) if conn_time else 0
                    m, s_val = divmod(elapsed, 60)

                    steer_pos = int((tl["steer"] + 1) * 15)
                    steer_bar = "░" * steer_pos + "█" + "░" * (30 - steer_pos)
                    thr_fill = int(tl["thr"] * 20)
                    brk_fill = int(tl["brk"] * 20)
                    thr_bar = f"{GREEN}{'█'*thr_fill}{RESET}{'░'*(20-thr_fill)}"
                    brk_bar = f"{RED}{'█'*brk_fill}{RESET}{'░'*(20-brk_fill)}"

                    b = tl["buttons"]
                    ba  = f"{GREEN} A {RESET}"  if b&(1<<9)  or b&(1<<0) else f"{DIM} a {RESET}"
                    bb  = f"{RED} B {RESET}"    if b&(1<<10) or b&(1<<2) else f"{DIM} b {RESET}"
                    bx  = f"{CYAN} X {RESET}"   if b&(1<<11) or b&(1<<3) else f"{DIM} x {RESET}"
                    by_ = f"{YELLOW} Y {RESET}"  if b&(1<<12) or b&(1<<1) else f"{DIM} y {RESET}"
                    brb = f"{WHITE}RB{RESET}" if b&(1<<7) else f"{DIM}rb{RESET}"
                    blb = f"{WHITE}LB{RESET}" if b&(1<<8) else f"{DIM}lb{RESET}"
                    bst = f"{WHITE}ST{RESET}" if b&(1<<13) else f"{DIM}st{RESET}"
                    bse = f"{WHITE}BK{RESET}" if b&(1<<14) else f"{DIM}bk{RESET}"
                    dpad_char = {0:"·",1:"↑",2:"↗",3:"→",4:"↘",5:"↓",6:"↙",7:"←",8:"↖"}.get(tl["dpad"],"·")

                    ping_str = f"{CYAN}{ping_avg:.0f}ms{RESET}" if ping_avg > 0 else f"{DIM}--ms{RESET}"

                    print(f"  {CYAN}{hz_avg:>3}Hz{RESET} {ping_str} │ "
                          f"Steer [{steer_bar}] {tl['steer']:+.2f} │ "
                          f"Thr [{thr_bar}] │ Brk [{brk_bar}]")
                    print(f"  {DIM}{pkt_total:>6} pkts{RESET} │ "
                          f"{ba}{bb}{bx}{by_} │ {blb} {brb} │ {bst} {bse} │ "
                          f"D:{dpad_char} │ {m:02d}:{s_val:02d}")
                    print(f"  {DIM}{'─'*66}{RESET}")
                    last_report = now

                # Hz tick
                if now - last_hz_time >= 1.0:
                    pkt_window[pkt_win_idx % 4] = pkt_this_sec
                    pkt_win_idx += 1
                    pkt_this_sec = 0
                    last_hz_time = now

        except KeyboardInterrupt:
            graceful_exit()
        except Exception as e:
            print(f"\n  {RED}Server error: {e} — restarting in 1s...{RESET}")
            time.sleep(1)
            try:
                sock.close()
                sock = make_socket(PORT)
                connected = False
                mobile_addr = None
            except Exception:
                pass

if __name__ == "__main__":
    main()
