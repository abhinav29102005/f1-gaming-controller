# 🏎️ F1 Gaming Controller

> **Turn your phone into a high-performance F1 racing controller for PC games.**

A cross-platform Flutter + Kotlin application that transforms your Android phone into a real-time racing gamepad with native **Bluetooth HID** and ultra-low-latency **UDP relay** connectivity. Supports **local multiplayer (P1–P4)** and includes a built-in **Windows/Linux PC Host Receiver Dashboard**.

---

## 🎮 Features

| Feature | Description |
|---------|-------------|
| **Dual Transport** | Native Bluetooth HID (no PC software needed) + UDP Socket Relay (sub-5ms latency) |
| **250Hz Input Loop** | Fixed 4ms tick sampling — zero-GC pre-allocated binary packets |
| **F1 Cockpit HUD** | CustomPainter steering wheel, split throttle/brake sliders, paddle shifters, F1 button cluster |
| **Local Multiplayer** | P1–P4 player slots with unique LED accent colors and packet tagging |
| **Gyro Steering** | Tilt-to-steer mode using phone accelerometer/gyroscope |
| **Profile System** | Hive-persisted deadzone calibration, sensitivity curves, and game presets |
| **PC Host Dashboard** | Built-in UDP receiver with live telemetry gauges for all connected controllers |
| **Virtual Xbox Controller** | ViGEmBus companion maps phone inputs to native Windows Xbox 360 controllers |
| **Cross-Platform** | Android (controller) + Windows/Linux (controller or host receiver) |

---

## 📋 Requirements

### Android Phone (Controller Mode)
- Android 9+ (API 28+) — required for `BluetoothHidDevice`
- Bluetooth 4.0+ for BLE HID mode
- USB tethering capability for UDP relay mode

### PC (Host / Receiver)
- **Windows 10/11** or **Linux** for the desktop Flutter app
- Python 3.8+ for companion server scripts
- [ViGEmBus Driver](https://github.com/nefarius/ViGEmBus/releases) (Windows only, for virtual Xbox controller)

### Development
- Flutter SDK (stable channel)
- Android SDK with API 28+
- Kotlin 1.8+

---

## 🚀 Quick Start

### 1. Clone & Install Dependencies

```bash
git clone https://github.com/abhinav29102005/f1-gaming-controller.git
cd f1-gaming-controller
flutter pub get
```

### 2. Build Android APK

```bash
# Fast debug build (for testing)
flutter build apk --debug --target-platform android-arm64

# Production release build (optimized, 18MB)
flutter build apk --release --target-platform android-arm64
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 3. Build Desktop (Linux)

```bash
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/f1_gaming_controller`

### 4. Build Desktop (Windows)

> ⚠️ Must be run on a Windows machine. Cannot cross-compile from Linux.

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/`

Or use **GitHub Actions** — push to `main` and download the pre-built Windows `.exe` from the [Actions tab](../../actions).

### 5. Install APK on Phone

```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Or transfer the APK file to your phone and install manually
```

---

## 🔌 Connection Setup

### Option A: UDP Socket Relay (Recommended — Lowest Latency)

This is the primary mode for competitive gaming. Sub-5ms input latency.

#### Step 1: Start the PC Server

On your Windows PC, navigate to the `companion_server` folder and **right-click `setup.bat` → Run as Administrator**:

```
companion_server/
├── setup.bat              ← Double-click this! (Run as Admin for firewall)
├── f1_win32_vigem.py      ← The server (launched by setup.bat)
└── setup.sh               ← Linux/macOS alternative
```

The setup script will automatically:
1. ✅ Install Python dependencies (`vgamepad`)
2. ✅ Open Windows Firewall for UDP port 9999
3. ✅ Detect your **real** IP address (skips VirtualBox/VMware virtual adapters)
4. ✅ Launch the Virtual Xbox Controller Server

You should see:
```
  [NETWORK] Your PC's IP Address: 192.168.43.50
            Enter this IP in the mobile app's 'Host IP' field.

  [FIREWALL] Checking Windows Firewall...
  [OK] Firewall rule created for UDP port 9999.

  [GAMEPAD] Initializing Virtual Xbox 360 Controller...
  [OK] Virtual Xbox 360 Controller registered in Windows!

  READY! Listening on UDP port 9999...
```

#### Step 2: Connect Phone to PC

| Method | Latency | Setup |
|--------|---------|-------|
| **Phone Hotspot (Best)** | ~3-5ms | Phone creates hotspot → PC connects to it |
| **USB Tethering** | ~2-3ms | Enable USB tethering on phone → connect USB to PC |
| **Same Wi-Fi Network** | ~5-15ms | Both devices on same router (**not** university/corporate Wi-Fi!) |

> ⚠️ **University/Corporate Wi-Fi** networks have "Client Isolation" enabled, which blocks device-to-device communication. Use Phone Hotspot instead.

#### Step 3: Configure in App

1. Open the F1 Controller app on your phone
2. Tap the **📡 Connection** icon in the top bar
3. Select **UDP Socket Relay**
4. Enter the IP shown in the PC terminal (e.g., `192.168.43.50`)
5. Tap **APPLY & SAVE CONNECTION**

### Option B: Bluetooth HID (No PC Software Needed)

Phone registers as a native Bluetooth gamepad — PC/Console sees it as a real controller.

1. Open the F1 Controller app
2. Tap **📡 Connection** → Select **Bluetooth HID Gamepad**
3. Go to PC Bluetooth settings → Pair with `F1 Controller - P1`
4. The phone appears as a standard Xbox-compatible gamepad

> **Note:** Bluetooth HID has ~8-15ms latency. For competitive F1 racing, UDP relay is recommended.

---

## 🕹️ Virtual Xbox Controller (Windows — For Games)

The `setup.bat` script handles everything automatically! When you run it, your PC registers a Virtual Xbox 360 Controller that all racing games detect natively.

### Prerequisites (One-Time)
- **Python 3**: Download from https://python.org (check "Add Python to PATH")
- **ViGEmBus Driver**: Installs automatically with `pip install vgamepad`, or manually from https://github.com/nefarius/ViGEmBus/releases

### Haptic Feedback (Game Vibrations → Phone)
When a game triggers controller vibration (e.g., hitting curbs, losing traction), the vibration is sent over the network to your phone in real-time!

### Button Mapping (In-Game)

Open your racing game and go to **Controller Settings**:

| Phone Input | Xbox Mapping | In-Game Function |
|-------------|-------------|-----------------|
| Steering Wheel | Left Stick X | Steering |
| Throttle Slider | Right Trigger (RT) | Accelerate |
| Brake Slider | Left Trigger (LT) | Brake |
| Upshift Paddle | Right Bumper (RB) | Gear Up |
| Downshift Paddle | Left Bumper (LB) | Gear Down |
| DRS Button | A Button | DRS Toggle |
| ERS Button | Y Button | ERS Deploy |
| Pit Limiter | B Button | Pit Limiter |
| Radio | X Button | Team Radio |
| D-Pad | D-Pad | Menu Navigation |

### Supported Games
- **EA Sports F1 24 / F1 25**
- **Assetto Corsa / Competizione**
- **Forza Motorsport / Horizon**
- **EA Sports WRC**
- **iRacing**
- **BeamNG.drive**
- Any game with XInput/DirectInput controller support

---

## 👥 Local Multiplayer (P1–P4)

Up to 4 phones can connect simultaneously as separate controllers.

### Setup

1. Each phone selects a unique **Player Slot** (P1, P2, P3, or P4) from the top bar
2. All phones connect to the same PC host via UDP relay
3. Run `f1_win32_vigem.py` on the PC — it registers 4 separate virtual Xbox controllers
4. In-game, assign each virtual controller to a different player/car

### Player Slot Colors

| Slot | Color | Bluetooth Name |
|------|-------|----------------|
| P1 | 🔴 Electric Red | `F1 Controller - P1` |
| P2 | 🔵 Neon Cyan | `F1 Controller - P2` |
| P3 | 🟡 Amber Gold | `F1 Controller - P3` |
| P4 | 🟣 Neon Purple | `F1 Controller - P4` |

---

## ⚙️ Controller Calibration & Profiles

Access via the **⚙️ Settings** icon in the top bar.

### Deadzone Tuning
- **Steering Deadzone**: 0–20% (eliminates drift at center)
- **Throttle Deadzone**: 0–20%
- **Brake Deadzone**: 0–20%

### Steering Configuration
- **Rotation Range**: 270° (Arcade) / 360° (F1) / 540° (Rally) / 900° (Road)
- **Response Curve**: Linear / Exponential / S-Curve
- **Gyro Tilt Steering**: Enable/disable accelerometer-based steering

### Built-In Presets

| Preset | Rotation | Deadzone | Curve | Best For |
|--------|----------|----------|-------|----------|
| **F1 24/25** | 360° | 3% | Linear | Formula 1 games |
| **GT3 / GT4** | 540° | 5% | Exponential | Endurance racing |
| **Arcade** | 270° | 2% | S-Curve | Casual racing |

---

## 🖥️ Windows/Linux Host Receiver Dashboard

The desktop Flutter app includes a built-in **Host Receiver Mode** for monitoring connected controllers.

### Launch

```bash
# Linux
./build/linux/x64/release/bundle/f1_gaming_controller

# Windows
build\windows\x64\runner\Release\f1_gaming_controller.exe
```

Then tap the **🖥️ Computer** icon in the top bar to open the Host Dashboard.

### Dashboard Features
- Real-time steering angle gauge per player
- Throttle & brake pressure meters
- Live refresh rate (Hz) per controller
- DRS / ERS / PIT / RADIO active LED indicators
- Auto-discovery of incoming phone controllers

---

## 📁 Project Structure

```
f1-gaming-controller/
├── .github/workflows/
│   └── build-releases.yml           # CI/CD: Auto-builds Windows .exe + Android APK
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml       # Bluetooth, network, vibration permissions
│       └── kotlin/.../MainActivity.kt # BLE HID + UDP + Volume key platform channels
├── companion_server/
│   ├── f1_pc_relay.py                # Python UDP relay server (all platforms)
│   └── f1_win32_vigem.py             # Windows ViGEmBus virtual Xbox controller feeder
├── lib/
│   ├── main.dart                     # App entrypoint (Hive init, landscape lock)
│   ├── core/
│   │   ├── hid/
│   │   │   ├── hid_report.dart       # Zero-GC 10-byte binary packet serializer
│   │   │   ├── input_loop.dart       # 250Hz fixed-tick input sampler
│   │   │   ├── connection_manager.dart # BLE HID / UDP transport router
│   │   │   ├── native_hid_bridge.dart # Platform channel bridge (Android-guarded)
│   │   │   ├── socket_relay.dart     # UDP client + auto-discovery
│   │   │   └── host_receiver_engine.dart # UDP server engine for host mode
│   │   ├── models/
│   │   │   ├── controller_state.dart # Mutable input state snapshot
│   │   │   ├── profile_model.dart    # Hive-persisted controller profile
│   │   │   └── connection_stats.dart # Telemetry statistics model
│   │   └── theme/
│   │       └── f1_theme.dart         # F1 carbon dark theme + glassmorphism
│   └── features/
│       ├── controller_ui/
│       │   ├── controller_screen.dart # Main cockpit HUD layout
│       │   └── widgets/
│       │       ├── steering_wheel_widget.dart  # CustomPainter F1 wheel (gyro + touch)
│       │       ├── pedal_slider_widget.dart    # Vertical throttle/brake pressure sliders
│       │       ├── paddle_shifters.dart        # Gear shift paddles + gear indicator
│       │       ├── f1_button_cluster.dart      # DRS, ERS, Pit Limiter, Radio buttons
│       │       └── dpad_cluster.dart           # 8-way hat switch D-Pad
│       ├── host_mode/
│       │   └── host_receiver_screen.dart       # PC host telemetry dashboard
│       ├── connectivity/
│       │   ├── connection_screen.dart          # Transport mode & IP configuration
│       │   └── widgets/
│       │       └── multiplayer_lobby_widget.dart # P1-P4 slot selector + Hz monitor
│       └── profiles/
│           └── profile_manager_screen.dart     # Deadzone tuning & preset manager
├── test/
│   └── hid_report_test.dart          # Binary serializer unit tests
├── windows/                          # Windows desktop runner (CMake)
├── linux/                            # Linux desktop runner (CMake)
└── pubspec.yaml                      # Flutter dependencies
```

---

## 🔧 Development Commands

```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit tests
flutter test

# Run on connected Android device
flutter run

# Run on Linux desktop
flutter run -d linux

# Hot reload (while running)
# Press 'r' in terminal

# Build Android APK (release)
flutter build apk --release --target-platform android-arm64

# Build Linux desktop (release)
flutter build linux --release

# Build Windows desktop (release) — Windows only
flutter build windows --release
```

---

## 📡 Binary Packet Format (10 Bytes)

The controller sends a compact 10-byte binary packet at 250Hz:

```
Byte  | Field              | Type   | Range
------|--------------------|--------|------------------
  0   | Magic Header       | uint8  | Always 0xF1
  1   | Player ID          | uint8  | 0–3 (P1–P4)
  2   | Sequence Number    | uint8  | 0–255 (wrapping)
 3–4  | Steering Axis      | int16  | -32768 to 32767
  5   | Throttle           | uint8  | 0–255
  6   | Brake              | uint8  | 0–255
  7   | D-Pad Hat Switch   | uint8  | 0=Center, 1–8=directions
 8–9  | Button Bitmask     | uint16 | 16 button flags
```

### Button Bitmask Layout

```
Bit 0:  DRS
Bit 1:  ERS Deploy
Bit 2:  Pit Limiter
Bit 3:  Radio
Bit 4:  Box Box
Bit 5:  Engine Map Up
Bit 6:  Engine Map Down
Bit 7:  Paddle Upshift
Bit 8:  Paddle Downshift
```

---

## 🏗️ CI/CD (GitHub Actions)

Every push to `main` automatically builds:
- ✅ **Android APK** (Ubuntu runner)
- ✅ **Windows .exe** (Windows runner)

Download built artifacts from the [Actions tab](../../actions).

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with ❤️ and Flutter for the F1 racing community
</p>
