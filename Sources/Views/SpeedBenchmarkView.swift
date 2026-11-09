import SwiftUI

public struct SpeedBenchmarkView: View {
    @ObservedObject var transferManager = TransferManager.shared
    @ObservedObject var adbService = ADBService.shared
    @StateObject var vm = BenchmarkViewModel()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Read / Write Speed Benchmark")
                        .font(.system(size: 22, weight: .bold))
                    Text("Measure exact hardware bus transfer rates between your Mac and \(ADBService.shared.isDeviceConnected ? ADBService.shared.connectedDevice.shortName : "connected device").")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Controls card
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PAYLOAD SIZE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Picker("", selection: $vm.selectedSizeMB) {
                            Text("10 MB (Quick)").tag(10)
                            Text("50 MB (Recommended)").tag(50)
                            Text("100 MB (Stress Test)").tag(100)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 320)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        vm.startBenchmark(speedTracker: transferManager.speedTracker, transferManager: transferManager)
                    }) {
                        HStack(spacing: 8) {
                            if vm.isRunningTest {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: "bolt.fill")
                            }
                            Text(vm.isRunningTest ? vm.testStage : "Run Benchmark")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                    .disabled(vm.isRunningTest)
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
                
                // Live Gauges (Liquid Glass Cockpit)
                HStack(spacing: 20) {
                    // Write Speed Gauge (Mac -> Phone)
                    VStack(spacing: 12) {
                        Text("WRITE THROUGHPUT (MAC ➔ \(ADBService.shared.isDeviceConnected ? ADBService.shared.connectedDevice.shortName.uppercased() : "DEVICE"))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        SpeedometerView(
                            speedMBs: vm.isRunningTest ? transferManager.speedTracker.currentSpeedMBs : (vm.lastResult?.writeSpeedMBs ?? 0.0),
                            peakMBs: vm.lastResult?.writeSpeedMBs ?? 0.0,
                            direction: .writeToPhone,
                            isTransferring: vm.isRunningTest && transferManager.speedTracker.activeDirection == .writeToPhone
                        )
                        
                        Text(String(format: "%.1f MB/s", vm.lastResult?.writeSpeedMBs ?? vm.currentWriteSpeed))
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                    
                    // Read Speed Gauge (Phone -> Mac)
                    VStack(spacing: 12) {
                        Text("READ THROUGHPUT (\(ADBService.shared.isDeviceConnected ? ADBService.shared.connectedDevice.shortName.uppercased() : "DEVICE") ➔ MAC)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        SpeedometerView(
                            speedMBs: vm.isRunningTest ? transferManager.speedTracker.currentSpeedMBs : (vm.lastResult?.readSpeedMBs ?? 0.0),
                            peakMBs: vm.lastResult?.readSpeedMBs ?? 0.0,
                            direction: .readFromPhone,
                            isTransferring: vm.isRunningTest && transferManager.speedTracker.activeDirection == .readFromPhone
                        )
                        
                        Text(String(format: "%.1f MB/s", vm.lastResult?.readSpeedMBs ?? vm.currentReadSpeed))
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(.cyan)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                }
                
                // Hardware Bus Comparison Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("HARDWARE BUS PERFORMANCE REFERENCE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 10) {
                        BusBarRow(
                            name: "\(ADBService.shared.isDeviceConnected ? ADBService.shared.connectedDevice.shortName : "Device") Current Speed",
                            speedMBs: vm.lastResult?.readSpeedMBs ?? 88.0,
                            maxScale: 350.0,
                            color: .blue,
                            isCurrent: true
                        )
                        
                        BusBarRow(
                            name: "USB 3.2 Gen 2 (Direct Type-C 10Gbps)",
                            speedMBs: 320.0,
                            maxScale: 350.0,
                            color: .green,
                            isCurrent: false
                        )
                        
                        BusBarRow(
                            name: "Wi-Fi 7 / 6E (160MHz / 320MHz Channel)",
                            speedMBs: 140.0,
                            maxScale: 350.0,
                            color: .purple,
                            isCurrent: false
                        )
                        
                        BusBarRow(
                            name: "USB 2.0 Legacy (Basic Charging Cable Limit)",
                            speedMBs: 41.0,
                            maxScale: 350.0,
                            color: .orange,
                            isCurrent: false
                        )
                    }
                }
                .padding(18)
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(14)
                
                // Past benchmark runs
                if !transferManager.benchmarkHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("BENCHMARK HISTORY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        ForEach(transferManager.benchmarkHistory) { res in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(res.rating)
                                        .font(.system(size: 13, weight: .bold))
                                    Text("\(res.testSizeMB) MB test • \(res.timestamp.formatted(date: .omitted, time: .standard))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                HStack(spacing: 16) {
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text("Write")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.1f MB/s", res.writeSpeedMBs))
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.green)
                                    }
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text("Read")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.1f MB/s", res.readSpeedMBs))
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.cyan)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

private struct BusBarRow: View {
    let name: String
    let speedMBs: Double
    let maxScale: Double
    let color: Color
    let isCurrent: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.system(size: 12, weight: isCurrent ? .bold : .medium))
                    .foregroundColor(isCurrent ? .primary : .secondary)
                Spacer()
                Text(String(format: "%.1f MB/s", speedMBs))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
            
            GeometryReader { geo in
                let norm = min(1.0, CGFloat(speedMBs / maxScale))
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * norm, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
