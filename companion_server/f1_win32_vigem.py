#!/usr/bin/env python3
"""
F1 Gaming Controller — Native Windows Virtual Xbox Controller Feeder (ViGEmBus)
Maps incoming UDP multi-controller streams (P1..P4) from phone devices to native
Windows Xbox 360 Virtual Controllers using the ViGEmBus driver (via vgamepad).

Requirements on Windows Host PC:
  pip install vgamepad
  (ViGEmBus driver installs automatically or from https://github.com/nefarius/ViGEmBus)
"""

import importlib
import socket
import struct
import sys
import time
import argparse

try:
    vg = importlib.import_module("vgamepad")
    VIGEM_AVAILABLE = True
except (ImportError, Exception):
    vg = None
    VIGEM_AVAILABLE = False

def main():
    parser = argparse.ArgumentParser(description="F1 Virtual Gamepad Relay")
    parser.add_argument('--slave', action='store_true', help="Run as slave to Flutter UI")
    args = parser.parse_args()

    host = "127.0.0.1" if args.slave else "0.0.0.0"
    port = 9998 if args.slave else 9999

    print("=" * 75)
    print("🏎️  WINDOWS VIRTUAL GAMEPAD RELAY (ViGEmBus / XInput Integration) 🏎️")
    print("=" * 75)

    if not VIGEM_AVAILABLE or vg is None:
        print("[WARNING] 'vgamepad' library not installed.")
        print("To enable native virtual Xbox controllers on Windows, run:")
        print("    pip install vgamepad")
        print("Running in simulation & telemetry reporting mode...\n")
        virtual_pads = {}
    else:
        print("[OK] ViGEmBus integration ready! Initializing 1 Virtual Xbox Controller...")
        try:
            virtual_pad = vg.VX360Gamepad()
            print("[OK] 1 Virtual Xbox 360 Controller registered in Windows Device Manager.")
        except Exception as e:
            print(f"[WARNING] Could not initialize ViGEmBus driver: {e}")
            virtual_pad = None

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((host, port))

    def rumble_callback(client, target, large_motor, small_motor, led_number, user_data):
        if args.slave:
            try:
                vib_msg = f"F1_VIB:{large_motor}:{small_motor}".encode('utf-8')
                sock.sendto(vib_msg, ("127.0.0.1", 9999))
            except Exception:
                pass

    if VIGEM_AVAILABLE and virtual_pad is not None:
        try:
            virtual_pad.register_notification(callback_function=rumble_callback)
        except Exception as e:
            print(f"[WARNING] Could not register haptic rumble callback: {e}")

    print(f"\nListening for F1 Controller UDP packets on {host}:{port}...")
    print("Games supported: F1 24/25, Assetto Corsa, Forza Horizon, EA WRC, iRacing, BeamNG.")
    print("Press Ctrl+C to exit.\n")

    while True:
        try:
            data, addr = sock.recvfrom(1024)

            # Auto-Discovery response
            if data == b"F1_CONTROLLER_DISCOVER":
                if not args.slave:
                    announce = f"F1_HOST_ANNOUNCE:{port}".encode("utf-8")
                    sock.sendto(announce, addr)
                continue

            if len(data) < 10 or data[0] != 0xF1:
                continue

            # Unpack 10-byte binary report
            magic, player_id, seq, steer_raw, throttle_raw, brake_raw, dpad, buttons = struct.unpack(
                ">BBBhBBBH", data[:10]
            )

            p_id = player_id & 0x03
            steer = (steer_raw / 32767.0)
            throttle = (throttle_raw / 255.0)
            brake = (brake_raw / 255.0)

            # Send Pong back to mobile device only if not in slave mode
            if not args.slave:
                pong = f"F1_HOST_PONG:{seq}".encode("utf-8")
                sock.sendto(pong, addr)

            # Feeds values to Windows Virtual Xbox 360 Controller
            if VIGEM_AVAILABLE and vg is not None and virtual_pad is not None:
                pad = virtual_pad
                pad.reset()

                # Steering -> Left Thumbstick X (-1.0 to 1.0)
                pad.left_joystick_float(x_value_float=steer, y_value_float=0.0)

                # Throttle -> Right Trigger (0.0 to 1.0)
                pad.right_trigger_float(value_float=throttle)

                # Brake -> Left Trigger (0.0 to 1.0)
                pad.left_trigger_float(value_float=brake)

                # Gear Paddles -> Shoulder Buttons (LB / RB)
                if buttons & (1 << 7):  # Upshift
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_RIGHT_SHOULDER)
                if buttons & (1 << 8):  # Downshift
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_LEFT_SHOULDER)

                # Action Buttons
                if buttons & (1 << 0):  # DRS -> A
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_A)
                if buttons & (1 << 1):  # ERS -> Y
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_Y)
                if buttons & (1 << 2):  # Pit -> B
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_B)
                if buttons & (1 << 3):  # Radio -> X
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_X)

                # D-Pad Hat Switch mapping
                if dpad == 1:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_UP)
                elif dpad == 3:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_RIGHT)
                elif dpad == 5:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_DOWN)
                elif dpad == 7:
                    pad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_LEFT)

                pad.update()

        except KeyboardInterrupt:
            print("\nExiting Windows Virtual Controller Feeder.")
            sys.exit(0)
        except Exception as e:
            pass

if __name__ == "__main__":
    main()
