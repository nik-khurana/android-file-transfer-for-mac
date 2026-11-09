# 🤖 Android File Transfer Pro (macOS ➔ All Android Devices)

A high-performance, native macOS application designed for ultra-fast bidirectional file transfers between your Mac and any Android device (**OnePlus, Samsung Galaxy, Google Pixel, Motorola, Xiaomi, Nothing**, etc.).

Built with **Swift, SwiftUI, and AppKit**, Android File Transfer Pro provides hardware-level transfer speeds, live throughput gauges, rolling real-time graphs, and a dual-engine architecture:
1. **Wi-Fi Fast Portal (Universal & Zero-Install)**: High-speed local transfer with QR-code pairing. No cables, no developer mode, no Android apps required.
2. **USB-C Direct (ADB Mode)**: Direct bus file management and push/pull sync reaching maximum USB 3.2 Gen 2 speeds (up to 300+ MB/s).

---

## ⚡ Key Features

- **Universal Multi-Brand Support**:
  - Automatically identifies any connected Android phone or tablet (**OnePlus, Samsung, Pixel**, etc.) and resolves custom Bluetooth/device names.
- **Real-Time Read & Write Speed Monitoring**:
  - Live animated radial speedometer gauge.
  - High-precision rolling throughput graph (last 40 seconds) showing instantaneous **MB/s** and **Mbps**.
  - Peak speed and session average speed calculations.
- **Live Transfer Progress & ETA**:
  - Continuous linear progress bar with live percentage (`0%` ➔ `100%`).
  - Byte counters (e.g. `142.5 MB / 192.0 MB`) and remaining time countdown (`ETA 2s`).
- **Dedicated Speed Benchmark Tool**:
  - Run synthetic 10 MB, 50 MB, or 100 MB read/write throughput tests between your Mac and connected phone.
  - Compares your active speed against USB 2.0 (40 MB/s), Wi-Fi 6E/7 (140 MB/s), and USB 3.2 Gen 2 (320 MB/s).
- **Dual Transfer Engines**:
  - **Wi-Fi Portal**: Scan the on-screen QR code with your phone camera to instantly open the mobile web dashboard. Stream photos, 4K/8K videos, and files both ways.
  - **USB Explorer**: Full Android `/sdcard` directory tree navigator (DCIM, Download, Pictures, Documents) with right-click Save to Desktop, Save to Downloads, Save As, and drag-and-drop upload.
- **Built specifically for macOS & Apple Silicon**:
  - Zero external dependencies.
  - Native Mach-O 64-bit arm64 binary.
  - Modern Apple Liquid Glass aesthetic and Retina squircle icon (`AppIcon.icns`).

---

## 📦 macOS Application Bundle Structure

```text
Android File Transfer Pro.app/
└── Contents/
    ├── Info.plist               # App identity, permissions, version, bundle ID
    ├── PkgInfo                  # macOS package signature ('APPL????')
    ├── MacOS/
    │   └── AndroidFileTransfer  # Native arm64 executable binary
    ├── Resources/
    │   ├── AppIcon.icns         # Multi-resolution macOS icon (16x16 to 1024x1024)
    │   └── platform-tools/      # Bundled official Google platform-tools (adb)
    └── _CodeSignature/          # Apple Silicon designated requirement signature
```

### How to Rebuild the Bundle Anytime

To recompile and assemble the bundle from source, run:

```bash
cd /Users/nikhil/Desktop/android-file-transfer
./Scripts/build_bundle.sh
```

The script automatically:
1. Generates `Resources/AppIcon.icns` with all resolutions.
2. Compiles the Swift codebase with `-O` compiler optimizations.
3. Assembles the `.app` bundle directory layout.
4. Applies ad-hoc code-signing (`codesign -s - --force --deep`).
5. Generates a release archive `AndroidFileTransferPro.zip`.

---

## 🚀 How to Launch and Use

### 1. Launching the App
Run directly from Terminal:
```bash
open "Android File Transfer Pro.app"
```
Or double-click `Android File Transfer Pro.app` in Finder. You can also drag it into your `/Applications` folder.

---

### 2. Transferring via Wi-Fi (No Cables Required)

1. Connect your Mac and phone to the same Wi-Fi network (supports Wi-Fi 6E and Wi-Fi 7).
2. Open **Android File Transfer Pro** on your Mac and select the **Wi-Fi Fast Portal** tab.
3. Open the **Camera app** on your phone and point it at the QR code displayed on the Mac screen.
4. Tap the link banner to open the portal. *(Note: If Chrome forces HTTPS or shows 'ERR_SSL_PROTOCOL_ERROR', ensure the URL starts with plain `http://`, or open the link in **Brave, Firefox, or Samsung Internet**)*.
5. In the web dashboard on your phone:
   - **Upload to Mac**: Tap *Select Files on Phone*, choose photos, videos, or documents, and tap *Start Transfer to Mac*. Watch the real-time MB/s counter on both screens!
   - **Download to Phone**: Tap the *Download* tab to view files shared on your Mac, and tap *Download* to save them.
   - **Speed Test**: Tap *Speed Test* to measure live Wi-Fi read/write throughput.

---

### 3. Transferring via USB Cable (Direct Mode)

1. Connect your Android phone (OnePlus, Samsung, Pixel, etc.) to your Mac using a USB-C data cable.
2. **Enable USB Debugging on your phone**:
   - Open **Settings** ➔ **About device** ➔ **Version**.
   - Tap **Build number** 7 times rapidly until Developer Options are unlocked.
   - Go to **Developer options** ➔ switch **USB debugging** to ON.
   - When the popup appears on your phone screen, check *"Always allow from this computer"* and tap **Allow**.
3. In **Android File Transfer Pro**, click the **Device Storage** tab.
4. Browse files, drag & drop files from your Mac to upload, or right-click any file to **Save to Desktop** or **Save to Downloads**.
5. **Safely Eject Device Before Unplugging**:
   - Just like ejecting an external SSD on macOS, click the **Eject** button (`⏏`) in the sidebar or top banner, or press **`Cmd+E`**.
   - The app automatically flushes all pending dirty buffers to phone flash storage (`adb shell sync`) so zero files are corrupted.
   - A confirmation banner appears stating that it is safe to unplug your USB cable. You can click **Reconnect** anytime to remount without disconnecting the cable.

---

## 📁 Default Mac Transfer Folders

- **Received from Phone**: `~/Downloads/AndroidFileTransfer`
- **Shared with Phone**: `~/Downloads/AndroidFileTransfer/SharedWithPhone`

You can quickly open these in Finder using the app menu or `Cmd+O` / `Cmd+Shift+S`.
