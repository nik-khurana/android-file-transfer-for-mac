import Foundation
import Combine

public final class SpeedTracker: ObservableObject {
    @Published public var currentSpeedMBs: Double = 0.0
    @Published public var currentSpeedMbps: Double = 0.0
    @Published public var peakSpeedMBs: Double = 0.0
    @Published public var averageSpeedMBs: Double = 0.0
    @Published public var totalBytesTransferred: Int64 = 0
    @Published public var activeDirection: TransferDirection = .writeToPhone
    @Published public var isTransferring: Bool = false
    @Published public var samples: [SpeedSample] = []
    @Published public var expectedTotalBytes: Int64 = 0
    @Published public var progressFraction: Double = 0.0
    @Published public var activeFileName: String = ""
    @Published public var progressText: String = ""
    
    private let maxSamples = 40
    private var windowBytes: Int64 = 0
    private var windowStartTime: Date = Date()
    private var transferStartTime: Date?
    private var totalSessionBytes: Int64 = 0
    private let lock = NSLock()
    private var decayTimer: Timer?
    
    public init() {
        // Initialize samples with 0 to make graph look nice immediately
        let now = Date()
        for i in 0..<maxSamples {
            samples.append(SpeedSample(
                timestamp: now.addingTimeInterval(Double(i - maxSamples)),
                speedMBs: 0.0,
                direction: .writeToPhone
            ))
        }
    }
    
    public func startSession(direction: TransferDirection, totalBytes: Int64 = 0, fileName: String = "") {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.startSession(direction: direction, totalBytes: totalBytes, fileName: fileName)
            }
            return
        }
        
        lock.lock()
        defer { lock.unlock() }
        
        isTransferring = true
        activeDirection = direction
        expectedTotalBytes = totalBytes
        activeFileName = fileName
        windowBytes = 0
        windowStartTime = Date()
        transferStartTime = Date()
        totalSessionBytes = 0
        currentSpeedMBs = 0.0
        currentSpeedMbps = 0.0
        progressFraction = totalBytes > 0 ? 0.001 : 0.0
        if totalBytes > 0 {
            let totalFormatted = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
            progressText = "0% (0 B / \(totalFormatted))"
        } else {
            progressText = "Starting transfer..."
        }
    }
    
    public func recordBytes(_ count: Int64, direction: TransferDirection) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.recordBytes(count, direction: direction)
            }
            return
        }
        
        lock.lock()
        defer { lock.unlock() }
        
        windowBytes += count
        totalSessionBytes += count
        totalBytesTransferred += count
        activeDirection = direction
        isTransferring = true
        
        if expectedTotalBytes > 0 {
            let frac = min(1.0, Double(totalSessionBytes) / Double(expectedTotalBytes))
            self.progressFraction = frac
            let pct = min(100, Int(frac * 100.0))
            let transferredStr = ByteCountFormatter.string(fromByteCount: totalSessionBytes, countStyle: .file)
            let totalStr = ByteCountFormatter.string(fromByteCount: expectedTotalBytes, countStyle: .file)
            
            if currentSpeedMBs > 0.1 {
                let remainingBytes = max(0, Double(expectedTotalBytes - totalSessionBytes))
                let remainingSec = max(0, Int(remainingBytes / (currentSpeedMBs * 1024.0 * 1024.0)))
                self.progressText = String(format: "%d%% (%@ / %@) • ETA %ds", pct, transferredStr, totalStr, remainingSec)
            } else {
                self.progressText = String(format: "%d%% (%@ / %@)", pct, transferredStr, totalStr)
            }
        }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(windowStartTime)
        
        if elapsed >= 0.20 {
            let bytesPerSec = Double(windowBytes) / elapsed
            let speedMBs = bytesPerSec / (1024.0 * 1024.0)
            
            // Exponential moving average for smooth display
            let alpha = 0.45
            let smoothedMBs = (alpha * speedMBs) + ((1.0 - alpha) * currentSpeedMBs)
            
            self.currentSpeedMBs = smoothedMBs
            self.currentSpeedMbps = smoothedMBs * 8.0
            
            if smoothedMBs > peakSpeedMBs {
                self.peakSpeedMBs = smoothedMBs
            }
            
            if let start = transferStartTime {
                let totalElapsed = max(0.001, now.timeIntervalSince(start))
                self.averageSpeedMBs = (Double(totalSessionBytes) / totalElapsed) / (1024.0 * 1024.0)
            }
            
            let sample = SpeedSample(timestamp: now, speedMBs: smoothedMBs, direction: direction)
            samples.append(sample)
            if samples.count > maxSamples {
                samples.removeFirst(samples.count - maxSamples)
            }
            
            windowBytes = 0
            windowStartTime = now
        }
    }
    
    public func endSession(success: Bool = true, finalSpeedMBs: Double = 0.0) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.endSession(success: success, finalSpeedMBs: finalSpeedMBs)
            }
            return
        }
        
        lock.lock()
        progressFraction = 1.0
        currentSpeedMBs = finalSpeedMBs > 0 ? finalSpeedMBs : averageSpeedMBs
        if success {
            progressText = String(format: "100%% • Complete (%.1f MB/s)", currentSpeedMBs)
        } else {
            progressText = "Transfer Failed"
        }
        lock.unlock()
        
        // Keep progress bar visible at 100% for 3.5 seconds so the user sees completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            defer { self.lock.unlock() }
            self.isTransferring = false
            self.currentSpeedMBs = 0.0
            self.currentSpeedMbps = 0.0
            self.windowBytes = 0
        }
    }
    
    public func resetStats() {
        lock.lock()
        defer { lock.unlock() }
        
        currentSpeedMBs = 0.0
        currentSpeedMbps = 0.0
        peakSpeedMBs = 0.0
        averageSpeedMBs = 0.0
        totalBytesTransferred = 0
        isTransferring = false
        windowBytes = 0
        
        let now = Date()
        samples = (0..<maxSamples).map { i in
            SpeedSample(
                timestamp: now.addingTimeInterval(Double(i - maxSamples)),
                speedMBs: 0.0,
                direction: activeDirection
            )
        }
    }
}
