import SwiftUI
import AppKit
import Combine

public final class WifiPortalViewModel: ObservableObject {
    @Published public var qrImage: NSImage? = nil
    @Published public var copiedAlert: Bool = false
    
    public init() {}
    
    public func generateQR(url: String) {
        self.qrImage = NetworkUtils.generateQRCode(from: url, size: 260)
    }
    
    public func copyURL(url: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
        copiedAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copiedAlert = false
        }
    }
}

public final class FileExplorerViewModel: ObservableObject {
    @Published public var currentPath: String = "/sdcard/"
    @Published public var pathHistory: [String] = ["/sdcard/"]
    @Published public var files: [RemoteFileItem] = []
    @Published public var selectedFile: RemoteFileItem? = nil
    @Published public var isLoading: Bool = false
    @Published public var statusMessage: String = ""
    @Published public var isTargetedForDrop: Bool = false
    private var cancellable: AnyCancellable?
    
    public init() {
        cancellable = ADBService.shared.$isDeviceConnected.sink { [weak self] connected in
            if connected {
                self?.loadDirectory(path: self?.currentPath ?? "/sdcard/")
            }
        }
    }
    
    public func loadDirectory(path: String) {
        isLoading = true
        let normalized = path.hasSuffix("/") ? path : "\(path)/"
        currentPath = normalized
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let items = ADBService.shared.listDirectory(path: normalized)
            DispatchQueue.main.async {
                self.files = items
                self.isLoading = false
            }
        }
    }
    
    public func navigateTo(path: String) {
        let normalized = path.hasSuffix("/") ? path : "\(path)/"
        pathHistory.append(normalized)
        loadDirectory(path: normalized)
    }
    
    public func navigateUp() {
        guard currentPath != "/sdcard" && currentPath != "/sdcard/" && currentPath != "/" else { return }
        var clean = currentPath
        if clean.hasSuffix("/") { clean.removeLast() }
        let parent = (clean as NSString).deletingLastPathComponent
        let target = (parent.isEmpty || parent == "/sdcard") ? "/sdcard/" : (parent.hasSuffix("/") ? parent : "\(parent)/")
        pathHistory.append(target)
        loadDirectory(path: target)
    }
    
    public func pickAndUploadFile(speedTracker: SpeedTracker) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a file to write to \(ADBService.shared.connectedDevice.shortName):"
        
        if panel.runModal() == .OK, let url = panel.url {
            uploadFile(url: url, speedTracker: speedTracker)
        }
    }
    
    public func uploadFile(url: URL, speedTracker: SpeedTracker) {
        statusMessage = "Uploading '\(url.lastPathComponent)' to \(ADBService.shared.connectedDevice.shortName)..."
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        ADBService.shared.pushFile(localPath: url,
                                   remoteDestination: currentPath,
                                   speedTracker: speedTracker) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let speed):
                self.statusMessage = String(format: "✅ Uploaded '%@' (%.1f MB/s)", url.lastPathComponent, speed)
                self.loadDirectory(path: self.currentPath)
                TransferManager.shared.postTransferNotification(
                    fileName: url.lastPathComponent,
                    totalBytes: fileSize,
                    direction: .writeToPhone
                )
            case .failure(let err):
                self.statusMessage = "❌ Upload failed: \(err.localizedDescription)"
            }
        }
    }
    
    public func downloadSelectedFile(speedTracker: SpeedTracker) {
        guard let file = selectedFile else { return }
        downloadItem(item: file, destinationFolder: nil, speedTracker: speedTracker)
    }
    
    public func quickSaveToDesktop(item: RemoteFileItem, speedTracker: SpeedTracker) {
        guard let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else { return }
        downloadItem(item: item, destinationFolder: desktop, speedTracker: speedTracker)
    }
    
    public func quickSaveToDownloads(item: RemoteFileItem, speedTracker: SpeedTracker) {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
        downloadItem(item: item, destinationFolder: downloads, speedTracker: speedTracker)
    }
    
    public func downloadItem(item: RemoteFileItem, destinationFolder: URL? = nil, speedTracker: SpeedTracker) {
        if let folder = destinationFolder {
            performDownload(item: item, destinationFolder: folder, fileName: item.name, speedTracker: speedTracker)
        } else {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = item.name
            panel.message = "Choose destination on your Mac for '\(item.name)':"
            if panel.runModal() == .OK, let dest = panel.url {
                performDownload(item: item, destinationFolder: dest.deletingLastPathComponent(), fileName: dest.lastPathComponent, speedTracker: speedTracker)
            }
        }
    }
    
    private func performDownload(item: RemoteFileItem, destinationFolder: URL, fileName: String, speedTracker: SpeedTracker) {
        statusMessage = "Copying '\(item.name)' to Mac..."
        ADBService.shared.pullFile(
            remotePath: item.path,
            fileName: fileName,
            fileSize: item.size,
            localDestination: destinationFolder,
            speedTracker: speedTracker
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let speed):
                self.statusMessage = String(format: "✅ Saved '%@' to Mac (%.1f MB/s)", fileName, speed)
                let savedFile = destinationFolder.appendingPathComponent(fileName)
                NSWorkspace.shared.activateFileViewerSelecting([savedFile])
                TransferManager.shared.postTransferNotification(
                    fileName: fileName,
                    totalBytes: item.size,
                    direction: .readFromPhone
                )
            case .failure(let err):
                self.statusMessage = "❌ Copy failed: \(err.localizedDescription)"
            }
        }
    }
    
    public func copyPath(item: RemoteFileItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.path, forType: .string)
        statusMessage = "Copied '\(item.path)' to clipboard"
    }

    public func deleteItem(item: RemoteFileItem) {
        let alert = NSAlert()
        alert.messageText = "Delete '\(item.name)'?"
        alert.informativeText = "Are you sure you want to permanently delete this from your \(ADBService.shared.connectedDevice.shortName)? This cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            statusMessage = "Deleting '\(item.name)'..."
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                guard let adb = ADBService.shared.resolvedAdbPath else { return }
                let escapedPath = "'" + item.path.replacingOccurrences(of: "'", with: "'\\''") + "'"
                _ = ADBService.shared.runSystemCommand(adb, arguments: ["shell", "rm", "-rf", escapedPath])
                DispatchQueue.main.async {
                    self.statusMessage = "Deleted '\(item.name)'"
                    self.loadDirectory(path: self.currentPath)
                }
            }
        }
    }
}

public final class BenchmarkViewModel: ObservableObject {
    @Published public var selectedSizeMB: Int = 50
    @Published public var isRunningTest: Bool = false
    @Published public var testStage: String = "Ready"
    @Published public var currentWriteSpeed: Double = 0.0
    @Published public var currentReadSpeed: Double = 0.0
    @Published public var lastResult: BenchmarkResult? = nil
    
    public init() {}
    
    public func startBenchmark(speedTracker: SpeedTracker, transferManager: TransferManager) {
        isRunningTest = true
        testStage = "Testing Write Throughput..."
        
        ADBService.shared.runAdbBenchmark(sizeMB: selectedSizeMB, speedTracker: speedTracker) { [weak self] result in
            guard let self = self else { return }
            self.lastResult = result
            self.currentWriteSpeed = result.writeSpeedMBs
            self.currentReadSpeed = result.readSpeedMBs
            transferManager.recordBenchmark(result: result)
            self.isRunningTest = false
            self.testStage = "Ready"
        }
    }
}

public final class ConnectionGuideViewModel: ObservableObject {
    @Published public var adbPathInput: String = ""
    
    public init() {
        self.adbPathInput = ADBService.shared.resolvedAdbPath ?? ""
    }
    
    public func applyCustomPath() {
        ADBService.shared.customAdbPath = adbPathInput
        ADBService.shared.refreshAdbStatus()
    }
}

