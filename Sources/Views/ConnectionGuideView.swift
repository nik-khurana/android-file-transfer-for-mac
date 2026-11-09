import SwiftUI
import AppKit

public struct ConnectionGuideView: View {
    @ObservedObject var adbService = ADBService.shared
    @StateObject var vm = ConnectionGuideViewModel()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Android Setup & Connection Guide")
                        .font(.system(size: 22, weight: .bold))
                    Text("Everything you need to know about high-speed file transfers on macOS.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Section 1: Wi-Fi Transfer (Zero Setup)
                GuideCard(
                    icon: "wifi",
                    iconColor: .blue,
                    title: "Method 1: Wi-Fi High-Speed Web Portal (Instant & No Cables)",
                    badge: "Easiest • Recommended"
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Ensure your Mac and phone are connected to the same Wi-Fi network.")
                        Text("2. Open the **Wi-Fi Fast Portal** tab in this app.")
                        Text("3. Open the **Camera app** on your phone and point it at the QR code on your Mac screen.")
                        Text("4. Tap the link banner to open the portal. *(Note: If Chrome forces HTTPS, try Brave, Firefox, or Samsung Internet, or ensure the address starts with plain http://)*.")
                        Text("5. Upload photos, 4K/8K videos, or download files at full Wi-Fi speed!")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                }
                
                // Chrome HTTP / HTTPS Notice Card
                GuideCard(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    title: "Chrome HTTP vs HTTPS Notice",
                    badge: "Wi-Fi Browser Tips"
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Why Chrome may show 'Site cannot provide a secure connection' (ERR_SSL_PROTOCOL_ERROR):")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Modern Google Chrome on Android features an aggressive 'HTTPS-First Mode' that automatically upgrades local IP links (`http://192.168.x.x`) to `https://`. Because local Wi-Fi file transfers run over standard local HTTP, Chrome's automatic HTTPS upgrade causes the connection to fail.")
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
                                Text("**Use an Alternative Browser (Best Experience)**: Open the link in **Brave, Firefox, Samsung Internet, Opera, or DuckDuckGo**. These browsers do not force HTTPS on local IP addresses and connect immediately without any warnings.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(alignment: .top, spacing: 8) {
                                Text("2.")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.orange)
                                Text("**Type Explicit `http://` in Chrome**: If using Chrome, ensure the address bar explicitly begins with `http://` (not `https://`). If Chrome prompts with *'The site cannot provide a secure connection'*, look for a link to *'Proceed anyway (HTTP)'*.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(alignment: .top, spacing: 8) {
                                Text("3.")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.orange)
                                Text("**Disable HTTPS-First in Chrome**: In Chrome Settings ➔ **Privacy and security** ➔ turn off **'Always use secure connections'**.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Section 2: USB Cable & USB Debugging
                GuideCard(
                    icon: "cable.connector",
                    iconColor: .green,
                    title: "Method 2: USB-C High-Speed Cable & Direct Transfer",
                    badge: "Max Speed (40–350 MB/s)"
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "1.circle.fill").foregroundColor(.green)
                            Text("**Plug in USB-C Cable**: Connect your phone to your Mac using a USB-C data cable.")
                        }
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "2.circle.fill").foregroundColor(.green)
                            Text("**Enable Developer Options**: On your phone, open **Settings ➔ About phone ➔ Software information**. Tap **Build number** 7 times rapidly until unlocked.")
                        }
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "3.circle.fill").foregroundColor(.green)
                            Text("**Enable USB Debugging**: Go back to Settings ➔ **Developer options** ➔ switch **USB debugging** to ON.")
                        }
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "4.circle.fill").foregroundColor(.green)
                            Text("**Authorize Mac**: When the popup appears on your phone screen, check *Always allow from this computer* and tap **Allow**.")
                        }
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "5.circle.fill").foregroundColor(.green)
                            Text("**Safely Disconnect (Eject)**: When done, click the **Eject** button (⏏) in the sidebar or toolbar, or press **⌘E**. This automatically flushes dirty storage caches (`sync`) so it is safe to unplug your USB cable.")
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                }
                
                // Section 3: ADB Status & Configuration
                GuideCard(
                    icon: "terminal",
                    iconColor: .purple,
                    title: "Mac ADB Tools Configuration",
                    badge: adbService.isAdbAvailable ? "Configured" : "Action Needed"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Current ADB Status:")
                                .font(.system(size: 13, weight: .semibold))
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(adbService.isAdbAvailable ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text(adbService.isAdbAvailable ? (adbService.resolvedAdbPath ?? "Installed") : "Not Found in Standard Paths")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(adbService.isAdbAvailable ? .green : .orange)
                            }
                        }
                        
                        if !adbService.isAdbAvailable {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("To install ADB via Homebrew in Terminal, run:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("brew install android-platform-tools")
                                        .font(.system(size: 12, design: .monospaced))
                                    Spacer()
                                    Button("Copy") {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString("brew install android-platform-tools", forType: .string)
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.system(size: 11))
                                }
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(6)
                            }
                        }
                        
                        // Custom Path Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Or specify a custom ADB binary path:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("/path/to/adb", text: $vm.adbPathInput)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button("Apply") {
                                    vm.applyCustomPath()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
            }
            .padding(20)
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
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(iconColor)
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                }
                Spacer()
                Text(badge)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(iconColor.opacity(0.12))
                    .foregroundColor(iconColor)
                    .clipShape(Capsule())
            }
            
            content()
        }
        .padding(18)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
