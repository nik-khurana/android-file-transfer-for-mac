import SwiftUI
import AppKit

@main
public struct AndroidFileTransferApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Phone Downloads in Finder") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: LocalWebServer.shared.downloadDirectory.path)
                }
                .keyboardShortcut("o", modifiers: [.command])
                
                Button("Open Shared Folder in Finder") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: LocalWebServer.shared.sharedDirectory.path)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            CommandMenu("Device") {
                Button("Refresh Device Status") {
                    ADBService.shared.reconnectAfterEject()
                    TransferManager.shared.refreshNetworkInfo()
                }
                .keyboardShortcut("r", modifiers: [.command])
                
                Button("Safely Eject Device") {
                    ADBService.shared.safelyEjectDevice()
                }
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(!ADBService.shared.isDeviceConnected)
                
                Divider()
                
                Button("Toggle Demo / Simulation Mode") {
                    ADBService.shared.toggleSimulationMode()
                }
                .keyboardShortcut("d", modifiers: [.command, .option])
            }
        }
    }
}

public class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        if let icnsPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let img = NSImage(contentsOfFile: icnsPath) {
            NSApp.applicationIconImage = img
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        // Complete teardown: stop web server socket and background ADB daemon
        LocalWebServer.shared.stop()
        ADBService.shared.stopAllServices(killAdbDaemon: true)
    }
}

