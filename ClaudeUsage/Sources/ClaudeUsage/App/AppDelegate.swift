import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon -- this is a menu bar-only app
        NSApp.setActivationPolicy(.accessory)
    }
}
