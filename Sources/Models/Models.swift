import Foundation

public enum TransferDirection: String, Codable, CaseIterable {
    case readFromPhone = "Read (Phone ➔ Mac)"
    case writeToPhone = "Write (Mac ➔ Phone)"
    
    public var shortLabel: String {
        switch self {
        case .readFromPhone: return "Read"
        case .writeToPhone: return "Write"
        }
    }
}

public enum TransferStatus: Equatable {
    case pending
    case inProgress
    case completed
    case failed(String)
    case cancelled
    
    public var description: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "Transferring"
        case .completed: return "Completed"
        case .failed(let msg): return "Failed: \(msg)"
        case .cancelled: return "Cancelled"
        }
    }
}

public enum TransferMode: String, Codable {
    case wifiPortal = "Wi-Fi Portal"
    case adbUsb = "USB (ADB)"
    case adbWifi = "Wireless ADB"
}

public enum DeviceAuthStatus: Equatable {
    case disconnected
    case unauthorized(serial: String)
    case authorized(serial: String)
    case requestingAuth
    
    public var label: String {
        switch self {
        case .disconnected: return "No USB Device Detected"
        case .unauthorized(let s): return "Detected (\(s)) — Authorization Required"
        case .authorized(let s): return "Authorized & Connected (\(s))"
        case .requestingAuth: return "Prompting Phone for Authorization..."
        }
    }
}

public struct TransferItem: Identifiable {
    public let id: UUID
    public var fileName: String
    public var localPath: URL?
    public var remotePath: String
    public var fileSize: Int64
    public var bytesTransferred: Int64
    public var progress: Double
    public var currentSpeedMBs: Double
    public var peakSpeedMBs: Double
    public var avgSpeedMBs: Double
    public var direction: TransferDirection
    public var mode: TransferMode
    public var status: TransferStatus
    public var startTime: Date?
    public var endTime: Date?
    public var errorMessage: String?
    
    public init(id: UUID = UUID(),
                fileName: String,
                localPath: URL? = nil,
                remotePath: String,
                fileSize: Int64 = 0,
                bytesTransferred: Int64 = 0,
                progress: Double = 0.0,
                currentSpeedMBs: Double = 0.0,
                peakSpeedMBs: Double = 0.0,
                avgSpeedMBs: Double = 0.0,
                direction: TransferDirection,
                mode: TransferMode,
                status: TransferStatus = .pending,
                startTime: Date? = nil,
                endTime: Date? = nil,
                errorMessage: String? = nil) {
        self.id = id
        self.fileName = fileName
        self.localPath = localPath
        self.remotePath = remotePath
        self.fileSize = fileSize
        self.bytesTransferred = bytesTransferred
        self.progress = progress
        self.currentSpeedMBs = currentSpeedMBs
        self.peakSpeedMBs = peakSpeedMBs
        self.avgSpeedMBs = avgSpeedMBs
        self.direction = direction
        self.mode = mode
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.errorMessage = errorMessage
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    public var formattedTransferred: String {
        ByteCountFormatter.string(fromByteCount: bytesTransferred, countStyle: .file)
    }
    
    public var formattedSpeed: String {
        String(format: "%.1f MB/s", currentSpeedMBs)
    }
}

public struct RemoteFileItem: Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var path: String
    public var isDirectory: Bool
    public var size: Int64
    public var permissions: String
    public var dateModified: String
    
    public init(id: UUID = UUID(),
                name: String,
                path: String,
                isDirectory: Bool,
                size: Int64 = 0,
                permissions: String = "",
                dateModified: String = "") {
        self.id = id
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.size = size
        self.permissions = permissions
        self.dateModified = dateModified
    }
    
    public var formattedSize: String {
        if isDirectory { return "--" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

public struct SpeedSample: Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let speedMBs: Double
    public let direction: TransferDirection
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), speedMBs: Double, direction: TransferDirection) {
        self.id = id
        self.timestamp = timestamp
        self.speedMBs = speedMBs
        self.direction = direction
    }
}

public struct DeviceInfo: Equatable {
    public var modelName: String
    public var shortName: String
    public var productCode: String
    public var androidVersion: String
    public var batteryLevel: Int
    public var storageUsedBytes: Int64
    public var storageTotalBytes: Int64
    public var connectionType: String
    public var isConnected: Bool
    
    public init(modelName: String = "Android Device",
                shortName: String = "Device",
                productCode: String = "",
                androidVersion: String = "Android",
                batteryLevel: Int = 100,
                storageUsedBytes: Int64 = 0,
                storageTotalBytes: Int64 = 0,
                connectionType: String = "USB-C Direct Bus",
                isConnected: Bool = false) {
        self.modelName = modelName
        self.shortName = shortName
        self.productCode = productCode
        self.androidVersion = androidVersion
        self.batteryLevel = batteryLevel
        self.storageUsedBytes = storageUsedBytes
        self.storageTotalBytes = storageTotalBytes
        self.connectionType = connectionType
        self.isConnected = isConnected
    }
    
    public var storageFreeBytes: Int64 {
        max(0, storageTotalBytes - storageUsedBytes)
    }
    
    public var storageFormattedSummary: String {
        if storageTotalBytes <= 0 {
            return "Calculating..."
        }
        let freeStr = ByteCountFormatter.string(fromByteCount: storageFreeBytes, countStyle: .file)
        let totalStr = ByteCountFormatter.string(fromByteCount: storageTotalBytes, countStyle: .file)
        return "\(freeStr) free of \(totalStr)"
    }
}

public struct BenchmarkResult: Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let readSpeedMBs: Double
    public let writeSpeedMBs: Double
    public let testSizeMB: Int
    public let latencyMs: Double
    public let connectionType: String
    public let rating: String
    
    public init(id: UUID = UUID(),
                timestamp: Date = Date(),
                readSpeedMBs: Double,
                writeSpeedMBs: Double,
                testSizeMB: Int,
                latencyMs: Double,
                connectionType: String,
                rating: String) {
        self.id = id
        self.timestamp = timestamp
        self.readSpeedMBs = readSpeedMBs
        self.writeSpeedMBs = writeSpeedMBs
        self.testSizeMB = testSizeMB
        self.latencyMs = latencyMs
        self.connectionType = connectionType
        self.rating = rating
    }
}

