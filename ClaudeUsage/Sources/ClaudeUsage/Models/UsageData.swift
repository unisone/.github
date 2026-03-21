import Foundation

struct UsageData {
    let fiveHourPercentage: Double
    let weeklyPercentage: Double
    let fiveHourPromptCount: Int
    let fiveHourPromptLimit: Int
    let weeklySonnetHours: Double
    let weeklyOpusHours: Double
    let weeklySonnetLimit: Double
    let weeklyOpusLimit: Double?
    let cycleResetTime: Date
    let weekResetTime: Date
    let lastRefreshed: Date

    /// Time remaining until the 5-hour cycle resets.
    var cycleTimeRemaining: TimeInterval {
        max(0, cycleResetTime.timeIntervalSinceNow)
    }

    /// Time remaining until the weekly cycle resets.
    var weekTimeRemaining: TimeInterval {
        max(0, weekResetTime.timeIntervalSinceNow)
    }

    /// Formatted string for cycle time remaining, e.g. "2h 15m".
    var cycleTimeRemainingFormatted: String {
        formatTimeInterval(cycleTimeRemaining)
    }

    /// Formatted string for week time remaining, e.g. "3d 5h".
    var weekTimeRemainingFormatted: String {
        formatTimeInterval(weekTimeRemaining)
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let days = totalMinutes / (60 * 24)
        let hours = (totalMinutes % (60 * 24)) / 60
        let minutes = totalMinutes % 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
