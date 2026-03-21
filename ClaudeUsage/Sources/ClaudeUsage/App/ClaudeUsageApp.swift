import SwiftUI

@main
struct ClaudeUsageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var tracker = UsageTracker()

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView(tracker: tracker)
                .frame(width: 280)
        } label: {
            MenuBarLabel(tracker: tracker)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(tracker: tracker)
        }
    }
}
