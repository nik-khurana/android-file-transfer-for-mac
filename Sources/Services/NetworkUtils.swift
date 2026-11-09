import Foundation
import CoreImage
import AppKit

public enum NetworkUtils {
    
    /// Finds the Mac's active primary IPv4 address on Wi-Fi (en0) or Ethernet (en1/en...)
    public static func getLocalIPAddress() -> String {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return "127.0.0.1"
        }
        
        var en0Addr: String?
        var otherEnAddr: String?
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                
                let ipStr = String(cString: hostname)
                
                if !ipStr.starts(with: "127.") && !ipStr.isEmpty {
                    if name == "en0" {
                        en0Addr = ipStr
                    } else if name.starts(with: "en") && otherEnAddr == nil {
                        otherEnAddr = ipStr
                    }
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return en0Addr ?? otherEnAddr ?? "127.0.0.1"
    }
    
    /// Generates a crisp, pure bitmap NSImage QR code from a URL string
    public static func generateQRCode(from string: String, size: CGFloat = 260) -> NSImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let ci = filter.outputImage else { return nil }
        
        let bitmap = NSBitmapImageRep(ciImage: ci)
        guard let tiff = bitmap.tiffRepresentation,
              let img = NSImage(data: tiff) else {
            return nil
        }
        img.size = NSSize(width: size, height: size)
        return img
    }
}
