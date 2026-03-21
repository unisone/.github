import Foundation
import SwiftUI
import Combine

@MainActor
class UsageTracker: ObservableObject {
    @Published var usageData: UsageData?
    @Published var isLoading = false
    @Published var lastError: String?

    private let parser = ConversationParser()
    private let calculator = UsageCalculator()
    private var refreshTimer: Timer?

    var planTier: PlanTier {
        get {
            guard let raw = UserDefaults.standard.string(forKey: "planTier"),
                  let tier = PlanTier(rawValue: raw) else {
                return .pro
            }
            return tier
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "planTier")
            Task { await refresh() }
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Only scan files modified in the last 7 days for performance
            let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
            let entries = try await Task.detached(priority: .utility) {
                try ConversationParser().parseAllConversations(since: cutoff)
            }.value

            usageData = calculator.calculate(entries: entries, tier: planTier)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func startAutoRefresh(interval: TimeInterval = 300) {
        stopAutoRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
        // Also refresh immediately on start
        Task { await refresh() }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
