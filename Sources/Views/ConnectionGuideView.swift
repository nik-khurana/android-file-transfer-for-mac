import SwiftUI
import AppKit

public struct ConnectionGuideView: View {
    @ObservedObject var adbService = ADBService.shared
    @StateObject var vm = ConnectionGuideViewModel()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Page Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.teal)
                        Text("Android Setup & Connection Guide")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                    }
                    Text("Choose between zero-install high-speed Wi-Fi or full-speed USB-C direct bus transfer.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // 2 Equal Vertical Columns: Wi-Fi on Left, USB on Right
                HStack(alignment: .top, spacing: 20) {
                    // ==========================================
                    // LEFT COLUMN: Wi-Fi Wireless Portal
                    // ==========================================
                    VStack(alignment: .leading, spacing: 14) {
                        // Wi-Fi Column Header Banner
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.cyan.opacity(0.18))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "wifi")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Wi-Fi Fast Portal")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                Text("Wireless • Zero App Install • Instant")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("RECOMMENDED")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.cyan.opacity(0.15))
                                .foregroundColor(.cyan)
                                .clipShape(Capsule())
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(LinearGradient(colors: [.cyan.opacity(0.4), .cyan.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                        
                        // Card 1: Wi-Fi Steps
                        GuideCard(
                            icon: "qrcode.viewfinder",
                            iconColor: .cyan,
                            title: "Wireless Quick Connect",
                            badge: "5 Simple Steps"
                        ) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "1.circle.fill").foregroundColor(.cyan)
                                    Text("Connect your Mac and phone to the **same Wi-Fi network**.")
                                }
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "2.circle.fill").foregroundColor(.cyan)
                                    Text("Open the **Wi-Fi Fast Portal** tab in this app.")
                                }
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "3.circle.fill").foregroundColor(.cyan)
                                    Text("Open your phone's **Camera app** and point it at the QR code on your Mac screen.")
                                }
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "4.circle.fill").foregroundColor(.cyan)
                                    Text("Tap the notification banner to open the portal in your browser.")
                                }
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "5.circle.fill").foregroundColor(.cyan)
                                    Text("Upload photos, 4K/8K videos, or download files at full wireless speed!")
                                }
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        }
                        
                        // Card 2: Chrome Notice
                        GuideCard(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .orange,
                            title: "Chrome HTTP vs HTTPS Notice",
                            badge: "Browser Tips"
                        ) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Why Chrome may show 'Site cannot provide a secure connection' (ERR_SSL_PROTOCOL_ERROR):")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Modern Chrome on Android enforces 'HTTPS-First Mode' that automatically upgrades local IP addresses (`http://192.168.x.x`) to `https://`. Because local Wi-Fi file transfers run over standard local HTTP, Chrome's automatic HTTPS upgrade causes the connection to fail.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Divider().opacity(0.4)
                                
                                Text("Recommended Solutions:")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("1.")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.orange)
                                        Text("**Use Alternative Browser (Best Experience)**: Open the portal in **Brave, Firefox, Samsung Internet, Opera, or DuckDuckGo**. These connect directly without forcing HTTPS.")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("2.")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.orange)
                                        Text("**Type Explicit `http://` in Chrome**: Ensure the address bar explicitly begins with `http://` (not `https://`). If prompted, tap *'Proceed anyway'*. ")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("3.")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.orange)
                                        Text("**Disable HTTPS-First in Chrome**: In Chrome Settings ➔ **Privacy and security** ➔ toggle off **'Always use secure connections'**.")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    // ==========================================
                    // RIGHT COLUMN: USB Cable Direct
                    // ==========================================
                    VStack(alignment: .leading, spacing: 14) {
                        // USB Column Header Banner
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.18))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "cable.connector")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("USB Direct Transfer")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                Text("Max Hardware Bus Speed • Full File Explorer")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("HIGH SPEED")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(LinearGradient(colors: [.green.opacity(0.4), .green.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                        
                        // Card 1: USB Setup Steps
                        GuideCard(
                            icon: "cable.connector",
                            iconColor: .green,
                            title: "USB-C Direct Bus Setup",
                            badge: "Max Speed (40–350 MB/s)"
                        ) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "1.circle.fill").foregroundColor(.green)
                                    Text("**Plug in USB-C Cable**: Connect your phone to your Mac using a USB-C data cable.")
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "2.circle.fill").foregroundColor(.green)
                                    Text("**Enable Developer Options**: In phone Settings ➔ **About phone ➔ Software info**, tap **Build number** 7 times until unlocked.")
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "3.circle.fill").foregroundColor(.green)
                                    Text("**Enable USB Debugging**: In Settings ➔ **Developer options**, switch **USB debugging** to ON.")
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "4.circle.fill").foregroundColor(.green)
                                    Text("**Authorize Mac**: When the popup appears on your phone screen, check *Always allow from this computer* and tap **Allow**.")
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "5.circle.fill").foregroundColor(.green)
                                    Text("**Safely Disconnect (Eject)**: When finished, click **Eject** (⏏) in the sidebar/toolbar or press **⌘E** to safely flush flash cache (`sync`) before unplugging.")
                                }
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        }
                        
                        // Card 2: Universal Zero-Setup ADB Engine
                        GuideCard(
                            icon: "shippingbox.fill",
                            iconColor: .purple,
                            title: "Universal Zero-Setup ADB Engine",
                            badge: adbService.isAdbAvailable ? "Built-in & Ready" : "Standby"
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 18))
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Zero Dependencies — Works on Any Mac")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.primary)
                                        Text("Android File Transfer Pro comes pre-packaged with Google's official **Android Platform Tools (Universal Mach-O binary)** supporting Apple Silicon (M1/M2/M3/M4) and Intel Macs natively — no Homebrew, Xcode, or command-line setup needed!")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Divider().opacity(0.4)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Active ADB Engine:")
                                            .font(.system(size: 12, weight: .semibold))
                                        
                                        HStack(spacing: 5) {
                                            Circle()
                                                .fill(adbService.isAdbAvailable ? Color.green : Color.orange)
                                                .frame(width: 8, height: 8)
                                            Text(adbService.isAdbAvailable ? adbService.adbSourceDescription : "Searching...")
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                                .foregroundColor(adbService.isAdbAvailable ? .green : .orange)
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    if let path = adbService.resolvedAdbPath {
                                        Text(path)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                                
                                // Advanced Custom Path Disclosure for Developers
                                DisclosureGroup("Advanced: Specify Custom ADB Binary Path") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("If you are an Android developer and want to override the pre-packaged binary with a specific custom SDK:")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                        
                                        HStack(spacing: 6) {
                                            TextField("/path/to/adb", text: $vm.adbPathInput)
                                                .textFieldStyle(.roundedBorder)
                                                .font(.system(size: 11, design: .monospaced))
                                            
                                            Button("Apply") {
                                                vm.applyCustomPath()
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .controlSize(.small)
                                            
                                            if !adbService.customAdbPath.isEmpty {
                                                Button("Reset") {
                                                    adbService.customAdbPath = ""
                                                    vm.adbPathInput = ""
                                                    adbService.refreshAdbStatus()
                                                }
                                                .buttonStyle(.bordered)
                                                .controlSize(.small)
                                            }
                                        }
                                    }
                                    .padding(.top, 6)
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .padding(22)
        }
    }
}

private struct GuideCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let badge: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(iconColor)
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Text(badge)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(iconColor.opacity(0.12))
                    .foregroundColor(iconColor)
                    .clipShape(Capsule())
                    .layoutPriority(1)
            }
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

