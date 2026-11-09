import SwiftUI
import AppKit

public struct TransferLogsView: View {
    @ObservedObject var transferManager = TransferManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transfer Activity & Speed History")
                        .font(.system(size: 22, weight: .bold))
                    Text("Track live and completed file transfers between Mac and connected device.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Clear History") {
                    transferManager.clearHistory()
                }
                .buttonStyle(.bordered)
                .disabled(transferManager.transferHistory.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Active Transfers Card (if any)
            if !transferManager.activeTransfers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ACTIVE TRANSFERS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    ForEach(transferManager.activeTransfers) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.direction == .readFromPhone ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(item.direction == .readFromPhone ? .cyan : .green)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.fileName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)
                                
                                HStack(spacing: 8) {
                                    Text(item.formattedTransferred)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(item.mode.rawValue)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Speed Badge
                            Text(String(format: "%.1f MB/s", item.currentSpeedMBs))
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(item.direction == .readFromPhone ? .cyan : .green)
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Completed Transfers Table
            VStack(alignment: .leading, spacing: 8) {
                Text("PAST TRANSFERS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                if transferManager.transferHistory.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("No transfers recorded yet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("Upload or download files via Wi-Fi Portal or USB to see history")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Table(transferManager.transferHistory) {
                        TableColumn("File Name") { item in
                            HStack(spacing: 8) {
                                Image(systemName: item.direction == .readFromPhone ? "arrow.down" : "arrow.up")
                                    .foregroundColor(item.direction == .readFromPhone ? .cyan : .green)
                                    .font(.system(size: 12, weight: .bold))
                                Text(item.fileName)
                                    .font(.system(size: 13))
                            }
                        }
                        .width(min: 200, ideal: 260)
                        
                        TableColumn("Direction") { item in
                            Text(item.direction.shortLabel)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(item.direction == .readFromPhone ? .cyan : .green)
                        }
                        .width(min: 70, ideal: 90)
                        
                        TableColumn("Mode") { item in
                            Text(item.mode.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .width(min: 90, ideal: 110)
                        
                        TableColumn("Size") { item in
                            Text(item.formattedSize)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .width(min: 80, ideal: 100)
                        
                        TableColumn("Average Speed") { item in
                            Text(String(format: "%.1f MB/s", item.avgSpeedMBs))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .width(min: 100, ideal: 120)
                        
                        TableColumn("Time") { item in
                            Text(item.startTime?.formatted(date: .omitted, time: .shortened) ?? "--")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .width(min: 80, ideal: 100)
                    }
                }
            }
        }
    }
}

