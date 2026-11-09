import SwiftUI

public struct ContentView: View {
    @ObservedObject var transferManager = TransferManager.shared
    @ObservedObject var speedTracker = TransferManager.shared.speedTracker
    @ObservedObject var adbService = ADBService.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Ambient Liquid Glass atmospheric backdrop
            Color.black.opacity(0.94).ignoresSafeArea()
            
            Circle()
                .fill(Color(red: 0.1, green: 0.45, blue: 0.95).opacity(0.18))
                .frame(width: 440, height: 440)
                .blur(radius: 95)
                .offset(x: -220, y: -200)
            
            Circle()
                .fill(Color(red: 0.65, green: 0.25, blue: 0.95).opacity(0.16))
                .frame(width: 400, height: 400)
                .blur(radius: 105)
                .offset(x: 280, y: 160)
            
            Circle()
                .fill(Color(red: 0.0, green: 0.85, blue: 0.75).opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 85)
                .offset(x: 120, y: -240)
            
            NavigationSplitView {
                sidebarContent
                    .navigationSplitViewColumnWidth(min: 230, ideal: 250, max: 290)
                    .background(.ultraThinMaterial)
            } detail: {
                ZStack(alignment: .top) {
                    detailContent
                        .background(.ultraThinMaterial)
                    
                    if adbService.showEjectBanner {
                        ejectBannerView
                    }
                }
            }
        }
        .frame(minWidth: 900, minHeight: 620)
    }
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // App branding header in Apple Liquid Glass styling
            HStack(spacing: 12) {
                if let appIcon = (Bundle.main.path(forResource: "AppIcon", ofType: "icns").flatMap { NSImage(contentsOfFile: $0) }) ?? NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                        .shadow(color: Color.cyan.opacity(0.35), radius: 6, x: 0, y: 2)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.0, green: 0.8, blue: 0.95), Color(red: 0.2, green: 0.4, blue: 1.0), Color(red: 0.6, green: 0.2, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 38, height: 38)
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Android File Transfer")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                    Text(adbService.isDeviceConnected ? "\(adbService.connectedDevice.shortName) • macOS" : "Ready • macOS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            Divider().opacity(0.3)
            
            // Navigation Links
            List(selection: $transferManager.selectedTab) {
                Section(header: Text("TRANSFERS").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)) {
                    NavigationLink(value: TransferManager.SidebarTab.wifiPortal) {
                        Label {
                            Text("Wi-Fi Fast Portal")
                        } icon: {
                            Image(systemName: "wifi")
                                .foregroundColor(.cyan)
                        }
                    }
                    
                    NavigationLink(value: TransferManager.SidebarTab.fileExplorer) {
                        HStack {
                            Label {
                                Text("\(adbService.isDeviceConnected ? adbService.connectedDevice.shortName : "Device") Storage")
                            } icon: {
                                Image(systemName: "internaldrive.fill")
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            if adbService.isDeviceConnected {
                                Button(action: {
                                    adbService.safelyEjectDevice()
                                }) {
                                    Image(systemName: "eject.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Safely Eject \(adbService.connectedDevice.shortName) (⌘E)")
                            }
                        }
                    }
                }
                
                Section(header: Text("HELP & SETUP").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)) {
                    NavigationLink(value: TransferManager.SidebarTab.connectionGuide) {
                        Label {
                            Text("Setup & Guide")
                        } icon: {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.teal)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            
            Spacer()
            
            // Sidebar Footer: Floating Liquid Glass Mini-Ticker
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(speedTracker.isTransferring ? Color.green : (adbService.isDeviceConnected || transferManager.isServerRunning ? Color.cyan : Color.gray))
                        .frame(width: 8, height: 8)
                        .shadow(color: speedTracker.isTransferring ? Color.green : (adbService.isDeviceConnected ? Color.cyan : Color.clear), radius: 4)
                    
                    Text(speedTracker.isTransferring ? (speedTracker.activeFileName.isEmpty ? "Transferring Data" : speedTracker.activeFileName) : (adbService.isDeviceConnected ? "\(adbService.connectedDevice.shortName) Connected" : "Wi-Fi Ready"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if adbService.isDeviceConnected && !speedTracker.isTransferring {
                        Button(action: {
                            adbService.safelyEjectDevice()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "eject.fill")
                                    .font(.system(size: 8))
                                Text("Eject")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.18))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .help("Safely Eject \(adbService.connectedDevice.shortName) (⌘E)")
                    } else if speedTracker.isTransferring {
                        HStack(spacing: 6) {
                            Text(String(format: "%d%%", Int(min(1.0, speedTracker.progressFraction) * 100.0)))
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(speedTracker.progressFraction >= 1.0 ? .green : .cyan)
                            Text(String(format: "%.1f MB/s", speedTracker.currentSpeedMBs))
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(.green)
                        }
                    }
                }
                
                if speedTracker.isTransferring {
                    if !speedTracker.progressText.isEmpty {
                        Text(speedTracker.progressText)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    ProgressView(value: max(0.01, min(1.0, speedTracker.progressFraction)), total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(LinearGradient(colors: [.cyan, .green], startPoint: .leading, endPoint: .trailing))
                }
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .padding(12)
        }
    }
    
    private var ejectBannerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(adbService.ejectedDeviceName) Safely Ejected")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                Text("Storage caches synchronized (sync). Safe to disconnect USB cable.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Reconnect") {
                adbService.reconnectAfterEject()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button(action: {
                withAnimation {
                    adbService.showEjectBanner = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LinearGradient(colors: [.green.opacity(0.6), .green.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    @ViewBuilder
    private var detailContent: some View {
        switch transferManager.selectedTab {
        case .wifiPortal:
            WifiPortalView()
        case .fileExplorer:
            FileExplorerView()
        case .speedBenchmark:
            SpeedBenchmarkView()
        case .transferLogs:
            TransferLogsView()
        case .connectionGuide:
            ConnectionGuideView()
        }
    }
}

