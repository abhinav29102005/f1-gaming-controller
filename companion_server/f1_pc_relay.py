#!/usr/bin/env python3
"""
F1 Gaming Controller — PC Relay Server (Linux/macOS)
Listens on UDP 9999, echoes PONGs, prints live telemetry.
"""
import socket, select, struct, time, sys

HOST = "0.0.0.0"
PORT = 9999
PLAYER_NAMES = ["P1","P2","P3","P4"]

def make_socket(port):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 4 * 1024 * 1024)
    try: s.setsockopt(socket.IPPROTO_IP, socket.IP_TOS, 0xB8)
    except Exception: pass
    s.bind((HOST, port))
    s.setblocking(False)
    return s

def main():
    print("="*60)
    print("  F1 GAMING CONTROLLER — PC RELAY SERVER")
    print(f"  Listening on UDP :{PORT}")
    print("="*60 + "\n")

    sock = make_socket(PORT)

    players = {i: {"pkts": 0, "hz": 0, "last_time": 0.0, "addr": None,
                   "ping": 0.0, "sent_times": {}, "steer": 0.0, "thr": 0.0, "brk": 0.0}
               for i in range(4)}
    last_report = time.time()

    while True:
        try:
            readable, _, _ = select.select([sock], [], [], 0.01)
            if not readable:
                continue

            data, addr = sock.recvfrom(1024)
            now = time.time()

            if data == b"F1_CONTROLLER_DISCOVER":
                sock.sendto(f"F1_HOST_ANNOUNCE:{PORT}".encode(), addr)
                continue

            if len(data) < 10 or data[0] != 0xF1: continue

            magic, pid, seq, steer_raw, thr_raw, brk_raw, dpad, buttons = struct.unpack(">BBBhBBBH", data[:10])
            pid = pid & 0x03
            p = players[pid]
            p["pkts"] += 1
            p["last_time"] = now
            p["addr"] = addr
            p["steer"] = steer_raw / 32767.0
            p["thr"]   = thr_raw / 255.0
            p["brk"]   = brk_raw / 255.0
            p["sent_times"][seq] = now
            if len(p["sent_times"]) > 64:
                del p["sent_times"][min(p["sent_times"])]

            # PONG
            sock.sendto(f"F1_HOST_PONG:{seq}".encode(), addr)

            if now - last_report >= 1.0:
                elapsed = now - last_report
                print(f"[{time.strftime('%H:%M:%S')}] ─────────────────────────────────────")
                any_active = False
                for i, p2 in players.items():
                    if p2["pkts"] > 0:
                        hz = int(p2["pkts"] / elapsed)
                        any_active = True
                        print(f"  {PLAYER_NAMES[i]} {p2['addr'][0] if p2['addr'] else '?'} "
                              f"| {hz:>3}Hz | St:{p2['steer']:+.2f} Thr:{p2['thr']:.2f} Brk:{p2['brk']:.2f}")
                        p2["hz"] = hz
                        p2["pkts"] = 0
                if not any_active:
                    print("  Waiting for connection...")
                last_report = now

        except KeyboardInterrupt:
            print("\nStopped.")
            sys.exit(0)
        except Exception as e:
            print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
