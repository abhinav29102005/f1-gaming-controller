#!/usr/bin/env python3
"""
F1 Gaming Controller — PC Companion Relay & Latency Server (Multiplayer Supported)
Listens for low-latency UDP gamepad packets from multiple F1 Controller mobile devices (P1..P4).

Packet Format (10 Bytes):
  [0]     Magic Byte: 0xF1
  [1]     Player ID: 0..3 (P1=0, P2=1, P3=2, P4=3)
  [2]     Sequence Number: 0..255
  [3..4]  Steering Axis: Int16 (-32768 to 32767)
  [5]     Throttle Axis: Uint8 (0 to 255)
  [6]     Brake Axis: Uint8 (0 to 255)
  [7]     D-Pad Hat Switch: Uint8 (0=Center, 1=N, 2=NE, 3=E, 4=SE, 5=S, 6=SW, 7=W, 8=NW)
  [8..9]  Button Bitmask: Uint16 (16-bit flags for DRS, ERS, Pit Limiter, Radio, Gear Paddles)
"""

import socket
import struct
import time
import sys

HOST = "0.0.0.0"
PORT = 9999

PLAYER_NAMES = ["P1 (Red)", "P2 (Cyan)", "P3 (Amber)", "P4 (Purple)"]

def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    except Exception:
        pass

    sock.bind((HOST, PORT))

    print("=" * 70)
    print(f"🏎️  F1 GAMING CONTROLLER — PC COMPANION RELAY SERVER 🏎️")
    print(f"Listening on UDP port {PORT} for multi-controller inputs...")
    print("Auto-discovery active. Press Ctrl+C to stop.")
    print("=" * 70)

    player_stats = {
        i: {"packets": 0, "last_seq": -1, "last_time": time.time(), "hz": 0}
        for i in range(4)
    }

    last_report_time = time.time()

    while True:
        try:
            data, addr = sock.recvfrom(1024)
            now = time.time()

            # Handle Auto-Discovery Request from Phone
            if data == b"F1_CONTROLLER_DISCOVER":
                announce_msg = f"F1_HOST_ANNOUNCE:{PORT}".encode("utf-8")
                sock.sendto(announce_msg, addr)
                print(f"[DISCOVERY] Host announce sent to {addr[0]}:{addr[1]}")
                continue

            # Validate Packet Header
            if len(data) < 10 or data[0] != 0xF1:
                continue

            # Unpack Binary Packet
            magic, player_id, seq, steer_raw, throttle, brake, dpad, buttons = struct.unpack(
                ">BBBhBBBH", data[:10]
            )

            if player_id not in player_stats:
                player_id = 0

            # Normalize values for display / virtual joystick injection
            steering_norm = steer_raw / 32767.0
            throttle_norm = throttle / 255.0
            brake_norm = brake / 255.0

            stats = player_stats[player_id]
            stats["packets"] += 1
            stats["last_seq"] = seq

            # Send Pong for RTT Ping calculation back to controller
            pong_msg = f"F1_HOST_PONG:{seq}".encode("utf-8")
            sock.sendto(pong_msg, addr)

            # Print telemetry summary every 1 second
            if now - last_report_time >= 1.0:
                elapsed = now - last_report_time
                print("-" * 70)
                print(f"[{time.strftime('%H:%M:%S')}] CONNECTED CONTROLLERS TELEMETRY:")
                for p_id, p_info in player_stats.items():
                    if p_info["packets"] > 0:
                        hz = int(p_info["packets"] / elapsed)
                        p_info["hz"] = hz
                        print(
                            f"  🏎️  {PLAYER_NAMES[p_id]}: {hz} Hz | "
                            f"Steer: {steering_norm:+.2f} | Throttle: {throttle_norm:.2f} | "
                            f"Brake: {brake_norm:.2f} | DPad: {dpad} | Buttons: 0x{buttons:04X}"
                        )
                        p_info["packets"] = 0
                last_report_time = now

        except KeyboardInterrupt:
            print("\nShutting down F1 Relay Server.")
            sys.exit(0)
        except Exception as e:
            print(f"[ERROR] Packet decode error: {e}")

if __name__ == "__main__":
    main()
