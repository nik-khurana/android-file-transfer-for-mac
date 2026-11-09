import SwiftUI
import AppKit

public struct WifiPortalView: View {
    @ObservedObject var transferManager = TransferManager.shared
    @ObservedObject var speedTracker = TransferManager.shared.speedTracker
    @StateObject var vm = WifiPortalViewModel()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Wi-Fi Fast Transfer Portal")
                                .font(.system(size: 22, weight: .bold))
                            
                            // Status Pill
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(transferManager.isServerRunning ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(transferManager.isServerRunning ? "Server Online" : "Server Stopped")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(transferManager.isServerRunning ? .green : .red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((transferManager.isServerRunning ? Color.green : Color.red).opacity(0.12))
                            .clipShape(Capsule())
                        }
                        
                        Text("Instant zero-install transfer between Mac and phone over your local Wi-Fi.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if transferManager.isServerRunning {
                            transferManager.stopServer()
                        } else {
                            transferManager.startServer()
                            vm.generateQR(url: transferManager.portalURL)
                        }
                    }) {
                        Label(transferManager.isServerRunning ? "Restart Server" : "Start Server",
                              systemImage: transferManager.isServerRunning ? "arrow.clockwise" : "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 4)
                
                // Active Wi-Fi Transfer Live Progress Card
                if speedTracker.isTransferring {
                    activeTransferCard
                }
                
                // Top Grid: QR Code & Connection Card + Real-time Speedometer
                HStack(alignment: .top, spacing: 18) {
                    // QR Code Card
                    VStack(spacing: 12) {
                        Text("SCAN WITH PHONE CAMERA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .frame(width: 200, height: 200)
                                .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
                            
                            if let qr = vm.qrImage {
                                Image(nsImage: qr)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180, height: 180)
                            } else {
                                ProgressView()
                            }
                        }
                        
                        // URL & Copy
                        HStack(spacing: 8) {
                            Text(transferManager.displayPortalURL)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button(action: {
                                vm.copyURL(url: transferManager.portalURL)
                            }) {
                                Image(systemName: vm.copiedAlert ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.borderless)
                            .help("Copy Secured Portal URL")
                            
                            Button(action: {
                                if let url = URL(string: transferManager.portalURL) {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Image(systemName: "safari")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.borderless)
                            .help("Open in Browser")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(8)
                        
                        // Secured Session Pairing Pill
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 11))
                            Text("Secured QR Pairing")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            Button(action: {
                                LocalWebServer.shared.regenerateAuthToken()
                                vm.generateQR(url: transferManager.portalURL)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 9))
                                    Text("New Token")
                                        .font(.system(size: 9, weight: .semibold))
                                }
                                .foregroundColor(.cyan)
                            }
                            .buttonStyle(.borderless)
                            .help("Regenerate Session Pairing Token")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(6)
                        
                        // Chrome HTTPS notice
                        HStack(spacing: 5) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("If Chrome forces HTTPS, use **http://** or try **Brave / Firefox**")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(18)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                    
                    // Live Speedometer & Metrics Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("LIVE TRANSFER SPEED")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(transferManager.speedTracker.isTransferring ? "ACTIVE" : "IDLE")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(transferManager.speedTracker.isTransferring ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                                .foregroundColor(transferManager.speedTracker.isTransferring ? .green : .secondary)
                                .clipShape(Capsule())
                        }
                        
                        HStack(spacing: 20) {
                            SpeedometerView(
                                speedMBs: transferManager.speedTracker.currentSpeedMBs,
                                peakMBs: transferManager.speedTracker.peakSpeedMBs,
                                direction: transferManager.speedTracker.activeDirection,
                                isTransferring: transferManager.speedTracker.isTransferring
                            )
                            
                            VStack(alignment: .leading, spacing: 10) {
                                MetricRow(label: "Direction",
                                          value: transferManager.speedTracker.activeDirection.shortLabel,
                                          color: transferManager.speedTracker.activeDirection == .readFromPhone ? .cyan : .green)
                                
                                MetricRow(label: "Throughput",
                                          value: String(format: "%.0f Mbps", transferManager.speedTracker.currentSpeedMbps),
                                          color: .primary)
                                
                                MetricRow(label: "Average Speed",
                                          value: String(format: "%.1f MB/s", transferManager.speedTracker.averageSpeedMBs),
                                          color: .secondary)
                                
                                MetricRow(label: "Peak Speed",
                                          value: String(format: "%.1f MB/s", transferManager.speedTracker.peakSpeedMBs),
                                          color: .orange)
                                
                                MetricRow(label: "Session Bytes",
                                          value: ByteCountFormatter.string(fromByteCount: transferManager.speedTracker.totalBytesTransferred, countStyle: .file),
                                          color: .secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Live Graph
                        SpeedGraphView(
                            samples: transferManager.speedTracker.samples,
                            maxSpeed: max(80.0, transferManager.speedTracker.peakSpeedMBs),
                            direction: transferManager.speedTracker.activeDirection
                        )
                    }
                    .padding(18)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                }
                
                // Bottom Row: Folders and Quick Actions
                HStack(spacing: 16) {
                    // Downloads received from phone
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.cyan)
                            Text("Received from Phone")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Button("Show in Finder") {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: LocalWebServer.shared.downloadDirectory.path)
                            }
                            .font(.system(size: 11))
                        }
                        Text("Files sent from your phone are saved here:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(LocalWebServer.shared.downloadDirectory.path)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.06))
                    .cornerRadius(10)
                    
                    // Shared with phone
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.green)
                            Text("Shared with Phone")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Button("Show in Finder") {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: LocalWebServer.shared.sharedDirectory.path)
                            }
                            .font(.system(size: 11))
                        }
                        Text("Drop files here on your Mac to let your phone download them:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(LocalWebServer.shared.sharedDirectory.path)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.06))
                    .cornerRadius(10)
                }
            }
            .padding(20)
        }
        .onAppear {
            vm.generateQR(url: transferManager.portalURL)
        }
    }
    
    private var activeTransferCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(speedTracker.activeDirection == .readFromPhone ? Color.cyan.opacity(0.2) : Color.green.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: speedTracker.activeDirection == .readFromPhone ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(speedTracker.activeDirection == .readFromPhone ? .cyan : .green)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(speedTracker.activeFileName.isEmpty ? "Wi-Fi File Transfer" : speedTracker.activeFileName)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                        
                        Text(speedTracker.activeDirection == .readFromPhone ? "RECEIVING FROM PHONE" : "SENDING TO PHONE")
                            .font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((speedTracker.activeDirection == .readFromPhone ? Color.cyan : Color.green).opacity(0.2))
                            .foregroundColor(speedTracker.activeDirection == .readFromPhone ? .cyan : .green)
                            .clipShape(Capsule())
                    }
                    
                    Text(speedTracker.progressText.isEmpty ? "Transferring live over Wi-Fi..." : speedTracker.progressText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%d%%", Int(min(1.0, speedTracker.progressFraction) * 100.0)))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(speedTracker.progressFraction >= 1.0 ? .green : .cyan)
                    
                    Text(String(format: "%.1f MB/s", speedTracker.currentSpeedMBs))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
            
            // Real-time Gradient Progress Bar
            ProgressView(value: max(0.01, min(1.0, speedTracker.progressFraction)), total: 1.0)
                .progressViewStyle(.linear)
                .tint(LinearGradient(colors: [.cyan, .green], startPoint: .leading, endPoint: .trailing))
                .scaleEffect(x: 1, y: 1.6, anchor: .center)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(LinearGradient(colors: [.cyan.opacity(0.5), .green.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
        )
        .shadow(color: Color.cyan.opacity(0.18), radius: 8, x: 0, y: 2)
    }
}

private struct MetricRow: View {
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}
