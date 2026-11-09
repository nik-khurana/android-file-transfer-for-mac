import SwiftUI
import AppKit

public struct FileExplorerView: View {
    @ObservedObject var adbService = ADBService.shared
    @ObservedObject var transferManager = TransferManager.shared
    @ObservedObject var speedTracker = TransferManager.shared.speedTracker
    @StateObject var vm = FileExplorerViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Device Info Banner
            deviceInfoBanner
            
            Divider()
            
            // Path Breadcrumbs & Actions Toolbar (when connected)
            if adbService.isDeviceConnected {
                pathAndToolbar
                Divider()
            }
            
            // Main Content: Authorization Assistant or File Browser
            if !adbService.isDeviceConnected {
                authorizationAssistantView
            } else if vm.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Reading \(adbService.connectedDevice.shortName) storage...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Group {
                    if vm.files.isEmpty {
                        emptyFolderView
                    } else {
                        fileTableView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onDrop(of: ["public.file-url"], isTargeted: $vm.isTargetedForDrop) { providers in
                    for provider in providers {
                        _ = provider.loadObject(ofClass: URL.self) { url, _ in
                            if let fileUrl = url {
                                DispatchQueue.main.async {
                                    vm.uploadFile(url: fileUrl, speedTracker: transferManager.speedTracker)
                                }
                            }
                        }
                    }
                    return true
                }
                .overlay(
                    Group {
                        if vm.isTargetedForDrop {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                                    .background(Color.blue.opacity(0.12))
                                
                                VStack(spacing: 10) {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.cyan)
                                    Text("Drop to Upload to \(adbService.connectedDevice.shortName)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("Destination: \(vm.currentPath)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                .padding(24)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 12)
                            }
                            .padding(12)
                        }
                    }
                )
            }
            
            // Bottom Status Bar
            bottomStatusBar
        }
        .onAppear {
            adbService.startAutoDetectionLoop()
            if adbService.isDeviceConnected {
                vm.loadDirectory(path: vm.currentPath)
            } else {
                adbService.checkConnectedDevices()
            }
        }
    }
    
    // MARK: - Device Info Header (Apple Liquid Glass)
    private var deviceInfoBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: adbService.isDeviceConnected
                            ? [Color.cyan.opacity(0.4), Color.blue.opacity(0.7)]
                            : [Color.orange.opacity(0.4), Color.red.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                    .shadow(color: adbService.isDeviceConnected ? Color.cyan.opacity(0.35) : Color.orange.opacity(0.25), radius: 6, x: 0, y: 2)
                
                Image(systemName: adbService.isDeviceConnected ? "candybarphone" : "cable.connector")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(adbService.connectedDevice.modelName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    
                    if adbService.isSimulatedMode {
                        Text("DEMO SIMULATION")
                            .font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.25))
                            .foregroundColor(.purple)
                            .clipShape(Capsule())
                    } else if adbService.isDeviceConnected {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("USB CONNECTED")
                                .font(.system(size: 9, weight: .heavy))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.18))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                    } else {
                        Text("WAITING FOR USB")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.25))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 10) {
                    Text(adbService.connectedDevice.androidVersion)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if adbService.isDeviceConnected {
                        Text("•").foregroundColor(.secondary.opacity(0.4))
                        HStack(spacing: 4) {
                            Image(systemName: "battery.100.bolt")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                            Text("\(adbService.connectedDevice.batteryLevel)%")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        }
                        Text("•").foregroundColor(.secondary.opacity(0.4))
                        Text(adbService.connectedDevice.storageFormattedSummary)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else {
                        Text("•").foregroundColor(.secondary.opacity(0.4))
                        Text(adbService.authorizationMessage)
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                adbService.toggleSimulationMode()
                if adbService.isDeviceConnected {
                    vm.loadDirectory(path: "/sdcard")
                }
            }) {
                Label(adbService.isSimulatedMode ? "Demo Active" : "Demo Mode",
                      systemImage: adbService.isSimulatedMode ? "sparkles" : "play.fill")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
            
            if adbService.isDeviceConnected {
                Button(action: {
                    adbService.safelyEjectDevice()
                }) {
                    Label(adbService.isEjecting ? "Syncing..." : "Eject", systemImage: "eject.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(adbService.isEjecting)
                .help("Safely disconnect \(adbService.connectedDevice.shortName) (⌘E)")
            }
            
            Button(action: {
                if adbService.isSafelyEjected {
                    adbService.reconnectAfterEject()
                } else {
                    adbService.checkConnectedDevices(force: true)
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help("Refresh Connection Status")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Interactive USB Authorization Assistant
    private var authorizationAssistantView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if adbService.isSafelyEjected {
                    safelyEjectedCard
                } else {
                    switch adbService.authStatus {
                    case .unauthorized(let serial):
                        unauthorizedCard(serial: serial)
                    case .requestingAuth:
                        requestingAuthCard
                    case .disconnected, .authorized:
                        disconnectedCard
                    }
                }
                
                // In-App Live ADB Console & Hardware Inspector
                adbConsoleInspectorCard
                
                samsungTroubleshootingCard
            }
            .padding(24)
            .frame(maxWidth: 720)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var safelyEjectedCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 76, height: 76)
                
                Image(systemName: "eject.circle.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 6) {
                Text("\(adbService.ejectedDeviceName) Safely Ejected")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("All write buffers and flash caches have been flushed (`sync`).")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text("It is now completely safe to unplug your USB cable from your Mac and phone.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.green)
            }
            .multilineTextAlignment(.center)
            
            Divider().opacity(0.4).padding(.horizontal, 40)
            
            HStack(spacing: 12) {
                Button(action: {
                    adbService.reconnectAfterEject()
                }) {
                    Label("Reconnect \(adbService.ejectedDeviceName)", systemImage: "cable.connector")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button(action: {
                    transferManager.selectedTab = .wifiPortal
                }) {
                    Label("Switch to Wi-Fi Portal", systemImage: "wifi")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.35), lineWidth: 1.5)
        )
    }
    
    private func unauthorizedCard(serial: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Action Required on Your Device")
                        .font(.system(size: 17, weight: .bold))
                    Text("Device detected (\(serial)), waiting for RSA debugging authorization.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if adbService.isPollingAuthorization {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                        Text("Waiting for tap...")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Please follow these steps on your phone right now:")
                    .font(.system(size: 13, weight: .semibold))
                
                InstructionStep(num: "1", text: "Unlock your phone screen.")
                InstructionStep(num: "2", text: "Look for the dialog titled: **\"Allow USB debugging?\"**")
                InstructionStep(num: "3", text: "Check the checkbox: **\"Always allow from this computer\"**.")
                InstructionStep(num: "4", text: "Tap **\"Allow\"**.")
            }
            .padding(14)
            .background(Color.orange.opacity(0.08))
            .cornerRadius(10)
            
            HStack(spacing: 12) {
                Button(action: {
                    adbService.triggerAuthorizationPrompt()
                }) {
                    Label("Send Authorization Prompt Again", systemImage: "bell.badge.fill")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                
                Button(action: {
                    adbService.restartAdbDaemon()
                }) {
                    Text("Restart ADB Daemon")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
        )
    }
    
    private var requestingAuthCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            VStack(spacing: 4) {
                Text("Requesting Handshake on Device...")
                    .font(.system(size: 16, weight: .bold))
                Text("Restarting ADB and pinging USB interfaces. Please watch your phone screen.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(14)
    }
    
    private var disconnectedCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "cable.connector")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 6) {
                Text("Connect Device via USB")
                    .font(.system(size: 18, weight: .bold))
                Text("Plug in your USB-C cable and ensure USB Debugging is enabled.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                adbService.triggerAuthorizationPrompt()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                    Text("Trigger Authorization Handshake")
                        .font(.system(size: 13, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(14)
    }
    
    private var adbConsoleInspectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "terminal.fill")
                        .foregroundColor(.cyan)
                        .font(.system(size: 14))
                    Text("IN-APP ADB CONSOLE & HARDWARE INSPECTOR")
                        .font(.system(size: 11, weight: .bold))
                }
                Spacer()
                if adbService.isRunningAdbCommand {
                    ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                }
            }
            
            Text("Run real-time ADB commands to verify that macOS detects your connected Android device.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            // Command Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    adbService.runRawAdbCommand(args: ["devices", "-l"])
                }) {
                    Label("Run 'adb devices'", systemImage: "play.fill")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                
                Button(action: {
                    adbService.runRawAdbCommand(args: ["start-server"])
                }) {
                    Label("Start Server", systemImage: "power")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    adbService.runRawAdbCommand(args: ["get-state"])
                }) {
                    Label("Check State", systemImage: "waveform.path.ecg")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    adbService.runRawAdbCommand(args: ["reconnect"])
                }) {
                    Label("Reconnect USB", systemImage: "cable.connector")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    adbService.restartAdbDaemon()
                }) {
                    Label("Restart Server", systemImage: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
            }
            
            // Dark Terminal Output Screen
            ScrollView {
                Text(adbService.rawAdbConsoleOutput)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(red: 0.2, green: 0.95, blue: 0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(height: 120)
            .background(Color.black.opacity(0.4))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(18)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private var samsungTroubleshootingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DEVICE CONNECTION TROUBLESHOOTING")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                TroubleBullet(
                    title: "1. Reset Stale Authorizations (Most Common Fix)",
                    detail: "On phone: Go to **Settings ➔ Developer options ➔ Revoke USB debugging authorizations**. Tap OK, then toggle USB debugging OFF and back ON."
                )
                
                TroubleBullet(
                    title: "2. Change USB Mode in Notification Panel",
                    detail: "Swipe down from the top of your phone screen, tap the notification that says **\"USB for file transfer\"** (or charging), and select **\"Transferring files\" (MTP)**."
                )
                
                TroubleBullet(
                    title: "3. Check USB Cable",
                    detail: "Ensure you are using a data-capable cable (like the Samsung cable). Some third-party cables only provide power and have no data lines."
                )
                
                TroubleBullet(
                    title: "4. No Cable Needed? Use Wi-Fi Mode",
                    detail: "You can switch to the **Wi-Fi Fast Portal** tab in the sidebar anytime. It works wirelessly at high speeds with zero developer options needed."
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.04))
        .cornerRadius(12)
    }
    
    // MARK: - Path and Toolbar (Apple Liquid Glass)
    private var pathAndToolbar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: { vm.navigateUp() }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.bordered)
                .disabled(vm.currentPath == "/sdcard" || vm.currentPath == "/sdcard/" || vm.currentPath == "/")
                .help("Up one level")
                
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.cyan)
                        .font(.system(size: 11))
                    Text(vm.currentPath)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
                
                // Open Folder button when directory is selected
                if let sel = vm.selectedFile, sel.isDirectory {
                    Button(action: { vm.navigateTo(path: sel.path) }) {
                        Label("Open '\(sel.name)'", systemImage: "arrow.right.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                
                // One-Click Save to Desktop for selected item
                if let sel = vm.selectedFile {
                    Button(action: { vm.quickSaveToDesktop(item: sel, speedTracker: transferManager.speedTracker) }) {
                        Label("Save to Desktop", systemImage: "desktopcomputer")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    Button(action: { vm.downloadItem(item: sel, speedTracker: transferManager.speedTracker) }) {
                        Label("Save As...", systemImage: "square.and.arrow.down")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                // Write to Phone (Upload)
                Button(action: { vm.pickAndUploadFile(speedTracker: transferManager.speedTracker) }) {
                    Label("Write to \(adbService.isDeviceConnected ? adbService.connectedDevice.shortName : "Device")", systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(LinearGradient(colors: [.teal, .green], startPoint: .leading, endPoint: .trailing))
                
                Button(action: { vm.loadDirectory(path: vm.currentPath) }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .help("Refresh Directory")
            }
            
            // Quick Jump Liquid Glass Capsules
            HStack(spacing: 8) {
                Text("QUICK JUMP:")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.secondary)
                
                QuickJumpPill(title: "Home", icon: "house.fill") {
                    vm.navigateTo(path: "/sdcard/")
                }
                QuickJumpPill(title: "Camera DCIM", icon: "camera.fill") {
                    vm.navigateTo(path: "/sdcard/DCIM/")
                }
                QuickJumpPill(title: "Downloads", icon: "arrow.down.circle.fill") {
                    vm.navigateTo(path: "/sdcard/Download/")
                }
                QuickJumpPill(title: "Pictures", icon: "photo.fill") {
                    vm.navigateTo(path: "/sdcard/Pictures/")
                }
                QuickJumpPill(title: "Movies", icon: "film.fill") {
                    vm.navigateTo(path: "/sdcard/Movies/")
                }
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.03))
    }
    
    // MARK: - Table View
    private var fileTableView: some View {
        Table(vm.files, selection: Binding(
            get: { vm.selectedFile?.id },
            set: { id in vm.selectedFile = vm.files.first(where: { $0.id == id }) }
        )) {
            TableColumn("Name") { item in
                HStack(spacing: 8) {
                    Image(systemName: fileIcon(for: item))
                        .foregroundColor(fileIconColor(for: item))
                        .font(.system(size: 14, weight: .semibold))
                    Text(item.name)
                        .font(.system(size: 13, weight: .medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .contextMenu {
                    contextMenuItems(for: item)
                }
                .onTapGesture(count: 2) {
                    if item.isDirectory {
                        vm.navigateTo(path: item.path)
                    } else {
                        vm.quickSaveToDesktop(item: item, speedTracker: transferManager.speedTracker)
                    }
                }
            }
            .width(min: 240, ideal: 340)
            
            TableColumn("Size") { item in
                Text(item.formattedSize)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .width(min: 80, ideal: 100)
            
            TableColumn("Date Modified") { item in
                Text(item.dateModified)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .width(min: 120, ideal: 150)
        }
        .contextMenu(forSelectionType: RemoteFileItem.ID.self) { selection in
            if let id = selection.first, let item = vm.files.first(where: { $0.id == id }) {
                contextMenuItems(for: item)
            }
        }
    }
    
    @ViewBuilder
    private func contextMenuItems(for item: RemoteFileItem) -> some View {
        Button {
            vm.quickSaveToDesktop(item: item, speedTracker: transferManager.speedTracker)
        } label: {
            Label("Save to Desktop", systemImage: "desktopcomputer")
        }
        
        Button {
            vm.quickSaveToDownloads(item: item, speedTracker: transferManager.speedTracker)
        } label: {
            Label("Save to Downloads", systemImage: "arrow.down.circle")
        }
        
        Button {
            vm.downloadItem(item: item, speedTracker: transferManager.speedTracker)
        } label: {
            Label("Save As...", systemImage: "square.and.arrow.down")
        }
        
        Divider()
        
        if item.isDirectory {
            Button {
                vm.navigateTo(path: item.path)
            } label: {
                Label("Open Folder", systemImage: "folder")
            }
        }
        
        Button {
            vm.copyPath(item: item)
        } label: {
            Label("Copy Phone Path", systemImage: "doc.on.doc")
        }
        
        Divider()
        
        Button(role: .destructive) {
            vm.deleteItem(item: item)
        } label: {
            Label("Delete from \(adbService.isDeviceConnected ? adbService.connectedDevice.shortName : "Device")", systemImage: "trash")
        }
    }
    
    private var emptyFolderView: some View {
        VStack(spacing: 14) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 46))
                .foregroundColor(.secondary)
            Text("Folder is empty")
                .font(.system(size: 15, weight: .bold))
            Text("Drag & drop files here to upload to \(adbService.connectedDevice.shortName)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var bottomStatusBar: some View {
        HStack(spacing: 16) {
            if adbService.isDeviceConnected {
                HStack(spacing: 6) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                    Text("\(vm.files.count) items")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                if let selected = vm.selectedFile {
                    Text("•").foregroundColor(.secondary.opacity(0.4))
                    HStack(spacing: 4) {
                        Image(systemName: fileIcon(for: selected))
                            .font(.system(size: 11))
                            .foregroundColor(fileIconColor(for: selected))
                        Text(selected.name)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                        Text("(\(selected.formattedSize))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack(spacing: 6) {
                    Circle().fill(Color.orange).frame(width: 6, height: 6)
                    Text(adbService.authStatus.label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if speedTracker.isTransferring {
                HStack(spacing: 10) {
                    ProgressView(value: max(0.01, speedTracker.progressFraction), total: 1.0)
                        .progressViewStyle(.linear)
                        .frame(width: 140)
                        .tint(LinearGradient(colors: [.cyan, .green], startPoint: .leading, endPoint: .trailing))
                    
                    if !speedTracker.progressText.isEmpty {
                        Text(speedTracker.progressText)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    Text(String(format: "%.1f MB/s", speedTracker.currentSpeedMBs))
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
            } else if !vm.statusMessage.isEmpty {
                Text(vm.statusMessage)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private func fileIcon(for item: RemoteFileItem) -> String {
        if item.isDirectory { return "folder.fill" }
        let ext = (item.name as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "dng", "heic", "webp": return "photo.fill"
        case "mp4", "mkv", "mov", "avi": return "film.fill"
        case "mp3", "flac", "wav", "m4a": return "music.note"
        case "pdf": return "doc.richtext.fill"
        case "zip", "tar", "gz", "rar", "7z": return "archivebox.fill"
        case "apk": return "app.badge.fill"
        default: return "doc.fill"
        }
    }
    
    private func fileIconColor(for item: RemoteFileItem) -> Color {
        if item.isDirectory { return Color(red: 0.98, green: 0.78, blue: 0.20) }
        let ext = (item.name as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "dng", "heic", "webp": return Color.pink
        case "mp4", "mkv", "mov", "avi": return Color.purple
        case "mp3", "flac", "wav", "m4a": return Color(red: 0.95, green: 0.25, blue: 0.65)
        case "pdf": return Color.red
        case "zip", "tar", "gz", "rar", "7z": return Color.orange
        case "apk": return Color.green
        default: return Color.cyan
        }
    }
}

private struct InstructionStep: View {
    let num: String
    let text: LocalizedStringKey
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(.orange)
                .frame(width: 18, height: 18)
                .background(Color.orange.opacity(0.15))
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 12))
        }
    }
}

private struct TroubleBullet: View {
    let title: String
    let detail: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
            Text(detail)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

private struct QuickJumpPill: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}
