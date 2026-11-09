import Foundation
import Combine

public final class TransferManager: ObservableObject {
    public static let shared = TransferManager()
    
    @Published public var speedTracker = SpeedTracker()
    @Published public var adbService = ADBService.shared
    @Published public var localIP: String = "127.0.0.1"
    @Published public var isServerRunning: Bool = false
    @Published public var activeTransfers: [TransferItem] = []
    @Published public var transferHistory: [TransferItem] = []
    @Published public var benchmarkHistory: [BenchmarkResult] = []
    @Published public var selectedTab: SidebarTab = .wifiPortal
    
    public enum SidebarTab: Hashable {
        case wifiPortal
        case fileExplorer
        case speedBenchmark
        case transferLogs
        case connectionGuide
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        speedTracker.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        refreshNetworkInfo()
        setupServerCallbacks()
        startServer()
    }
    
    public func refreshNetworkInfo() {
        self.localIP = NetworkUtils.getLocalIPAddress()
    }
    
    public func startServer(port: UInt16 = 8888) {
        refreshNetworkInfo()
        let success = LocalWebServer.shared.start(port: port, speedTracker: speedTracker)
        self.isServerRunning = success
    }
    
    public func stopServer() {
        LocalWebServer.shared.stop()
        self.isServerRunning = false
    }
    
    public var portalURL: String {
        "http://\(localIP):\(LocalWebServer.shared.port)"
    }
    
    private func setupServerCallbacks() {
        LocalWebServer.shared.onTransferProgress = { [weak self] transferred, totalBytes, direction, fileName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let index = self.activeTransfers.firstIndex(where: { $0.fileName == fileName }) {
                    self.activeTransfers[index].bytesTransferred = transferred
                    self.activeTransfers[index].fileSize = totalBytes
                    self.activeTransfers[index].progress = totalBytes > 0 ? Double(transferred) / Double(totalBytes) : 0.0
                    self.activeTransfers[index].currentSpeedMBs = self.speedTracker.currentSpeedMBs
                    self.activeTransfers[index].status = .inProgress
                } else {
                    let item = TransferItem(
                        fileName: fileName,
                        remotePath: ADBService.shared.connectedDevice.shortName,
                        fileSize: totalBytes,
                        bytesTransferred: transferred,
                        progress: totalBytes > 0 ? Double(transferred) / Double(totalBytes) : 0.0,
                        direction: direction,
                        mode: .wifiPortal,
                        status: .inProgress,
                        startTime: Date()
                    )
                    self.activeTransfers.append(item)
                }
            }
        }
        
        LocalWebServer.shared.onTransferCompleted = { [weak self] fileName, totalBytes, direction in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let index = self.activeTransfers.firstIndex(where: { $0.fileName == fileName }) {
                    var item = self.activeTransfers[index]
                    item.status = .completed
                    item.bytesTransferred = totalBytes
                    item.fileSize = totalBytes
                    item.endTime = Date()
                    item.avgSpeedMBs = self.speedTracker.averageSpeedMBs
                    self.activeTransfers.remove(at: index)
                    self.transferHistory.insert(item, at: 0)
                } else {
                    let item = TransferItem(
                        fileName: fileName,
                        remotePath: ADBService.shared.connectedDevice.shortName,
                        fileSize: totalBytes,
                        bytesTransferred: totalBytes,
                        avgSpeedMBs: self.speedTracker.averageSpeedMBs,
                        direction: direction,
                        mode: .wifiPortal,
                        status: .completed,
                        startTime: Date(),
                        endTime: Date()
                    )
                    self.transferHistory.insert(item, at: 0)
                }
            }
        }
    }
    
    public func recordTransfer(item: TransferItem) {
        transferHistory.insert(item, at: 0)
    }
    
    public func recordBenchmark(result: BenchmarkResult) {
        benchmarkHistory.insert(result, at: 0)
    }
    
    public func clearHistory() {
        transferHistory.removeAll()
    }
}

