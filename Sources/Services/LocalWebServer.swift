import Foundation
import Darwin

public final class LocalWebServer {
    public static let shared = LocalWebServer()
    
    public private(set) var port: UInt16 = 8888
    public private(set) var isRunning: Bool = false
    public var sharedDirectory: URL
    public var downloadDirectory: URL
    
    private var serverSocket: Int32 = -1
    private var isListening = false
    private let queue = DispatchQueue(label: "com.androidfiletransfer.webserver", qos: .userInitiated)
    
    public var onTransferProgress: ((Int64, Int64, TransferDirection, String) -> Void)?
    public var onTransferCompleted: ((String, Int64, TransferDirection) -> Void)?
    
    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.downloadDirectory = home.appendingPathComponent("Downloads/AndroidFileTransfer", isDirectory: true)
        self.sharedDirectory = home.appendingPathComponent("Downloads/AndroidFileTransfer/SharedWithPhone", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: sharedDirectory, withIntermediateDirectories: true)
    }
    
    public func start(port: UInt16 = 8888, speedTracker: SpeedTracker) -> Bool {
        if isRunning { stop() }
        
        let candidatePorts: [UInt16] = [port, 8889, 8890, 8080, 8081, 9090]
        var boundSocket: Int32 = -1
        var activePort: UInt16 = port
        
        for p in candidatePorts {
            let s = socket(AF_INET, SOCK_STREAM, 0)
            guard s >= 0 else { continue }
            
            var reuse: Int32 = 1
            setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
            setsockopt(s, SOL_SOCKET, SO_REUSEPORT, &reuse, socklen_t(MemoryLayout<Int32>.size))
            
            var addr = sockaddr_in()
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = in_port_t(p).bigEndian
            addr.sin_addr.s_addr = in_addr_t(0) // INADDR_ANY
            
            let bindResult = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    bind(s, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            
            if bindResult == 0 && listen(s, 32) == 0 {
                boundSocket = s
                activePort = p
                break
            } else {
                Darwin.close(s)
            }
        }
        
        guard boundSocket >= 0 else { return false }
        
        self.serverSocket = boundSocket
        self.port = activePort
        self.isRunning = true
        self.isListening = true
        
        queue.async { [weak self] in
            guard let self = self else { return }
            while self.isListening {
                var clientAddr = sockaddr_in()
                var clientLen = socklen_t(MemoryLayout<sockaddr_in>.size)
                
                let clientSocket = withUnsafeMutablePointer(to: &clientAddr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        accept(self.serverSocket, $0, &clientLen)
                    }
                }
                
                guard clientSocket >= 0 else { break }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    self.handleClient(clientSocket: clientSocket, speedTracker: speedTracker)
                }
            }
        }
        
        return true
    }
    
    public func stop() {
        isListening = false
        isRunning = false
        if serverSocket >= 0 {
            Darwin.close(serverSocket)
            serverSocket = -1
        }
    }
    
    @discardableResult
    private func sendAll(socket: Int32, data: Data) -> Bool {
        var totalSent = 0
        let count = data.count
        while totalSent < count {
            let remaining = count - totalSent
            let sent = data.withUnsafeBytes { rawBuffer -> Int in
                guard let base = rawBuffer.baseAddress else { return -1 }
                let ptr = base.advanced(by: totalSent)
                return Darwin.send(socket, ptr, remaining, 0)
            }
            if sent <= 0 { return false }
            totalSent += sent
        }
        return true
    }
    
    private func handleClient(clientSocket: Int32, speedTracker: SpeedTracker) {
        defer { Darwin.close(clientSocket) }
        
        var headerBuffer = [UInt8](repeating: 0, count: 8192)
        var totalHeaderBytes = 0
        var headerData = Data()
        
        while totalHeaderBytes < 8192 {
            let bytesRead = recv(clientSocket, &headerBuffer[totalHeaderBytes], headerBuffer.count - totalHeaderBytes, 0)
            if bytesRead <= 0 { return }
            
            // Check if Chrome accidentally attempted an HTTPS connection (TLS ClientHello)
            if totalHeaderBytes == 0 && headerBuffer[0] == 0x16 {
                let notice = "HTTP/1.1 400 Bad Request\r\nContent-Type: text/html; charset=utf-8\r\nConnection: close\r\n\r\n<html><body style=\"font-family:system-ui,-apple-system,sans-serif;background:#0f172a;color:#f8fafc;padding:36px;text-align:center;\"><h2 style=\"color:#f97316;\">⚠️ HTTPS Not Supported on Local Port</h2><p style=\"font-size:15px;line-height:1.6;\">Your browser attempted to connect using <b>https://</b>.<br>Please edit your address bar to start with plain <b>http://</b> (not https://),<br>or open this link in <b>Brave, Firefox, or Samsung Internet</b>.</p></body></html>"
                if let d = notice.data(using: .utf8) { sendAll(socket: clientSocket, data: d) }
                return
            }
            
            totalHeaderBytes += bytesRead
            headerData.append(contentsOf: headerBuffer[(totalHeaderBytes - bytesRead)..<totalHeaderBytes])
            
            if let range = headerData.range(of: Data("\r\n\r\n".utf8)) {
                let headerString = String(decoding: headerData.prefix(upTo: range.lowerBound), as: UTF8.self)
                let bodyRemainder = headerData.suffix(from: range.upperBound)
                processRequest(clientSocket: clientSocket,
                               headerString: headerString,
                               initialBodyData: bodyRemainder,
                               speedTracker: speedTracker)
                return
            }
        }
    }
    
    private func processRequest(clientSocket: Int32,
                                headerString: String,
                                initialBodyData: Data,
                                speedTracker: SpeedTracker) {
        let lines = headerString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return }
        
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return }
        
        let method = String(parts[0]).uppercased()
        let fullPath = String(parts[1])
        
        // Handle Chrome CORS / Private Network Access (PNA) Preflight
        if method == "OPTIONS" {
            handleOptions(clientSocket: clientSocket)
            return
        }
        
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            let kv = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if kv.count == 2 {
                headers[kv[0].lowercased()] = kv[1]
            }
        }
        
        let pathComponents = fullPath.split(separator: "?", maxSplits: 1)
        let route = String(pathComponents.first ?? "")
        let queryString = pathComponents.count > 1 ? String(pathComponents[1]) : ""
        let queryParams = parseQuery(queryString)
        
        if route == "/" || route == "/index.html" || route.isEmpty {
            serveWebUI(clientSocket: clientSocket)
        } else if route == "/api/files" {
            serveFileList(clientSocket: clientSocket)
        } else if route == "/api/download" {
            serveFileDownload(clientSocket: clientSocket, queryParams: queryParams, speedTracker: speedTracker)
        } else if route == "/api/upload" && method == "POST" {
            handleFileUpload(clientSocket: clientSocket, headers: headers, queryParams: queryParams, initialBodyData: initialBodyData, speedTracker: speedTracker)
        } else if route == "/api/benchmark/download" {
            handleBenchmarkDownload(clientSocket: clientSocket, queryParams: queryParams, speedTracker: speedTracker)
        } else if route == "/api/benchmark/upload" && method == "POST" {
            handleBenchmarkUpload(clientSocket: clientSocket, headers: headers, initialBodyData: initialBodyData, speedTracker: speedTracker)
        } else if route == "/api/status" {
            serveStatus(clientSocket: clientSocket, speedTracker: speedTracker)
        } else {
            sendResponse(clientSocket: clientSocket, status: "404 Not Found", contentType: "text/plain", body: "Not Found")
        }
    }
    
    private func handleOptions(clientSocket: Int32) {
        let headers = "HTTP/1.1 204 No Content\r\n" +
                      "Access-Control-Allow-Origin: *\r\n" +
                      "Access-Control-Allow-Methods: GET, POST, OPTIONS, HEAD\r\n" +
                      "Access-Control-Allow-Headers: *\r\n" +
                      "Access-Control-Allow-Private-Network: true\r\n" +
                      "Access-Control-Max-Age: 86400\r\n" +
                      "Connection: close\r\n\r\n"
        if let d = headers.data(using: .utf8) {
            sendAll(socket: clientSocket, data: d)
        }
    }
    
    private func parseQuery(_ qs: String) -> [String: String] {
        var params: [String: String] = [:]
        for item in qs.components(separatedBy: "&") {
            let pair = item.components(separatedBy: "=")
            if pair.count == 2,
               let key = pair[0].removingPercentEncoding,
               let val = pair[1].removingPercentEncoding {
                params[key] = val
            }
        }
        return params
    }
    
    private func sendResponse(clientSocket: Int32,
                              status: String = "200 OK",
                              contentType: String = "application/json",
                              body: String) {
        let bodyData = Data(body.utf8)
        let header = "HTTP/1.1 \(status)\r\n" +
                     "Content-Type: \(contentType)\r\n" +
                     "Content-Length: \(bodyData.count)\r\n" +
                     "Access-Control-Allow-Origin: *\r\n" +
                     "Access-Control-Allow-Methods: GET, POST, OPTIONS, HEAD\r\n" +
                     "Access-Control-Allow-Headers: *\r\n" +
                     "Access-Control-Allow-Private-Network: true\r\n" +
                     "Connection: close\r\n\r\n"
        
        if let headerData = header.data(using: .utf8) {
            sendAll(socket: clientSocket, data: headerData)
        }
        sendAll(socket: clientSocket, data: bodyData)
    }
    
    private func serveWebUI(clientSocket: Int32) {
        let html = WebUIHTML.getContent(hostName: Host.current().localizedName ?? "Mac")
        sendResponse(clientSocket: clientSocket, status: "200 OK", contentType: "text/html; charset=utf-8", body: html)
    }
    
    private func serveFileList(clientSocket: Int32) {
        let fm = FileManager.default
        var filesList: [[String: Any]] = []
        
        if let urls = try? fm.contentsOfDirectory(at: sharedDirectory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) {
            for url in urls {
                let values = try? url.resourceValues(forKeys: [.fileSizeKey])
                let size = Int64(values?.fileSize ?? 0)
                let name = url.lastPathComponent
                filesList.append([
                    "name": name,
                    "size": size,
                    "formattedSize": ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                ])
            }
        }
        
        let json = (try? JSONSerialization.data(withJSONObject: filesList, options: [])) ?? Data("[]".utf8)
        let body = String(decoding: json, as: UTF8.self)
        sendResponse(clientSocket: clientSocket, status: "200 OK", contentType: "application/json", body: body)
    }
    
    private func serveFileDownload(clientSocket: Int32, queryParams: [String: String], speedTracker: SpeedTracker) {
        guard let fileName = queryParams["name"] else {
            sendResponse(clientSocket: clientSocket, status: "400 Bad Request", body: "Missing file name")
            return
        }
        
        let fileURL = sharedDirectory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let handle = try? FileHandle(forReadingFrom: fileURL) else {
            sendResponse(clientSocket: clientSocket, status: "404 Not Found", body: "File not found")
            return
        }
        defer { try? handle.close() }
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0
        
        let header = "HTTP/1.1 200 OK\r\n" +
                     "Content-Type: application/octet-stream\r\n" +
                     "Content-Length: \(fileSize)\r\n" +
                     "Content-Disposition: attachment; filename=\"\(fileName)\"\r\n" +
                     "Access-Control-Allow-Origin: *\r\n" +
                     "Access-Control-Allow-Methods: GET, POST, OPTIONS, HEAD\r\n" +
                     "Access-Control-Allow-Headers: *\r\n" +
                     "Access-Control-Allow-Private-Network: true\r\n" +
                     "Connection: close\r\n\r\n"
        
        if let headerData = header.data(using: .utf8) {
            sendAll(socket: clientSocket, data: headerData)
        }
        
        speedTracker.startSession(direction: .writeToPhone, totalBytes: fileSize, fileName: fileName)
        
        let chunkSize = 65536
        var transferred: Int64 = 0
        
        while transferred < fileSize {
            let data = handle.readData(ofLength: chunkSize)
            if data.isEmpty { break }
            
            if !sendAll(socket: clientSocket, data: data) { break }
            
            transferred += Int64(data.count)
            speedTracker.recordBytes(Int64(data.count), direction: .writeToPhone)
            onTransferProgress?(transferred, fileSize, .writeToPhone, fileName)
        }
        
        speedTracker.endSession()
        onTransferCompleted?(fileName, transferred, .writeToPhone)
    }
    
    private func handleFileUpload(clientSocket: Int32,
                                  headers: [String: String],
                                  queryParams: [String: String],
                                  initialBodyData: Data,
                                  speedTracker: SpeedTracker) {
        let fileName = queryParams["name"] ?? "Transfer_\(Int(Date().timeIntervalSince1970)).dat"
        var contentLength = Int64(headers["content-length"] ?? "0") ?? 0
        if contentLength <= 0, let sizeParam = queryParams["size"], let s = Int64(sizeParam) {
            contentLength = s
        }
        
        try? FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: true)
        let targetURL = downloadDirectory.appendingPathComponent(fileName)
        
        FileManager.default.createFile(atPath: targetURL.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: targetURL) else {
            sendResponse(clientSocket: clientSocket, status: "500 Internal Server Error", body: "Could not create file")
            return
        }
        defer { try? handle.close() }
        
        speedTracker.startSession(direction: .readFromPhone, totalBytes: contentLength, fileName: fileName)
        
        var totalReceived: Int64 = 0
        
        if !initialBodyData.isEmpty {
            handle.write(initialBodyData)
            totalReceived += Int64(initialBodyData.count)
            speedTracker.recordBytes(Int64(initialBodyData.count), direction: .readFromPhone)
            onTransferProgress?(totalReceived, contentLength, .readFromPhone, fileName)
        }
        
        var buffer = [UInt8](repeating: 0, count: 65536)
        while totalReceived < contentLength || (contentLength == 0 && true) {
            let needed = contentLength > 0 ? min(Int64(buffer.count), contentLength - totalReceived) : Int64(buffer.count)
            if needed <= 0 { break }
            
            let bytesRead = recv(clientSocket, &buffer, Int(needed), 0)
            if bytesRead <= 0 { break }
            
            let dataChunk = Data(bytes: buffer, count: bytesRead)
            handle.write(dataChunk)
            totalReceived += Int64(bytesRead)
            
            speedTracker.recordBytes(Int64(bytesRead), direction: .readFromPhone)
            onTransferProgress?(totalReceived, contentLength, .readFromPhone, fileName)
            
            if totalReceived >= contentLength && contentLength > 0 { break }
        }
        
        speedTracker.endSession()
        onTransferCompleted?(fileName, totalReceived, .readFromPhone)
        
        sendResponse(clientSocket: clientSocket, status: "200 OK", body: "{\"status\":\"success\",\"bytes\":\(totalReceived)}")
    }
    
    private func handleBenchmarkDownload(clientSocket: Int32, queryParams: [String: String], speedTracker: SpeedTracker) {
        let sizeMB = Int(queryParams["size"] ?? "50") ?? 50
        let totalBytes = Int64(sizeMB) * 1024 * 1024
        
        let header = "HTTP/1.1 200 OK\r\n" +
                     "Content-Type: application/octet-stream\r\n" +
                     "Content-Length: \(totalBytes)\r\n" +
                     "Access-Control-Allow-Origin: *\r\n" +
                     "Access-Control-Allow-Methods: GET, POST, OPTIONS, HEAD\r\n" +
                     "Access-Control-Allow-Headers: *\r\n" +
                     "Access-Control-Allow-Private-Network: true\r\n" +
                     "Connection: close\r\n\r\n"
        
        if let headerData = header.data(using: .utf8) {
            sendAll(socket: clientSocket, data: headerData)
        }
        
        speedTracker.startSession(direction: .writeToPhone, totalBytes: totalBytes, fileName: "Wi-Fi Speed Test (Download)")
        
        let chunkSize = 65536
        let dummy = Data(repeating: 0xAA, count: chunkSize)
        var transferred: Int64 = 0
        
        while transferred < totalBytes {
            let toSend = min(Int64(chunkSize), totalBytes - transferred)
            let chunk = toSend == Int64(chunkSize) ? dummy : dummy.prefix(Int(toSend))
            if !sendAll(socket: clientSocket, data: chunk) { break }
            
            transferred += toSend
            speedTracker.recordBytes(toSend, direction: .writeToPhone)
        }
        
        speedTracker.endSession()
    }
    
    private func handleBenchmarkUpload(clientSocket: Int32, headers: [String: String], initialBodyData: Data, speedTracker: SpeedTracker) {
        let contentLength = Int64(headers["content-length"] ?? "0") ?? 0
        speedTracker.startSession(direction: .readFromPhone, totalBytes: contentLength, fileName: "Wi-Fi Speed Test (Upload)")
        
        var totalReceived: Int64 = Int64(initialBodyData.count)
        if totalReceived > 0 {
            speedTracker.recordBytes(totalReceived, direction: .readFromPhone)
        }
        
        var buffer = [UInt8](repeating: 0, count: 65536)
        while totalReceived < contentLength {
            let needed = min(Int64(buffer.count), contentLength - totalReceived)
            let bytesRead = recv(clientSocket, &buffer, Int(needed), 0)
            if bytesRead <= 0 { break }
            
            totalReceived += Int64(bytesRead)
            speedTracker.recordBytes(Int64(bytesRead), direction: .readFromPhone)
        }
        
        speedTracker.endSession()
        sendResponse(clientSocket: clientSocket, status: "200 OK", body: "{\"status\":\"ok\",\"bytes\":\(totalReceived)}")
    }
    
    private func serveStatus(clientSocket: Int32, speedTracker: SpeedTracker) {
        let json: [String: Any] = [
            "speedMBs": speedTracker.currentSpeedMBs,
            "speedMbps": speedTracker.currentSpeedMbps,
            "peakSpeedMBs": speedTracker.peakSpeedMBs,
            "avgSpeedMBs": speedTracker.averageSpeedMBs,
            "totalBytes": speedTracker.totalBytesTransferred,
            "isTransferring": speedTracker.isTransferring,
            "direction": speedTracker.activeDirection.shortLabel
        ]
        let data = (try? JSONSerialization.data(withJSONObject: json, options: [])) ?? Data()
        sendResponse(clientSocket: clientSocket, status: "200 OK", body: String(decoding: data, as: UTF8.self))
    }
}
