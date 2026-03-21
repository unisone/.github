import Foundation

struct UsageCalculator {

    func calculate(entries: [ConversationEntry], tier: PlanTier) -> UsageData {
        let now = Date()

        // 5-hour cycle: epoch-aligned fixed windows
        let hoursSinceEpoch = now.timeIntervalSince1970 / 3600
        let cycleNumber = Int(hoursSinceEpoch / 5)
        let cycleStartEpoch = TimeInterval(cycleNumber * 5) * 3600
        let cycleStart = Date(timeIntervalSince1970: cycleStartEpoch)
        let cycleEnd = Date(timeIntervalSince1970: cycleStartEpoch + 5 * 3600)

        // Weekly cycle: Monday 00:00 UTC
        let weekStart = startOfWeekUTC(from: now)
        let weekEnd = weekStart.addingTimeInterval(7 * 24 * 3600)

        // Count 5-hour prompts: external user messages only, not meta
        let fiveHourEntries = entries.filter { entry in
            entry.type == .user &&
            entry.isExternalUser &&
            !entry.isMeta &&
            entry.timestamp >= cycleStart &&
            entry.timestamp < cycleEnd
        }
        let promptCount = fiveHourEntries.count

        // Weekly usage: calculate session durations by model
        let weekEntries = entries.filter { $0.timestamp >= weekStart && $0.timestamp < weekEnd }
        let (sonnetHours, opusHours) = calculateWeeklyModelHours(entries: weekEntries)

        // Calculate percentages
        let fiveHourPct = min(100, Double(promptCount) / Double(tier.fiveHourPromptLimit) * 100)

        let sonnetLimit = tier.weeklySonnetHoursLimit
        let opusLimit = tier.weeklyOpusHoursLimit

        let weeklyPct: Double
        if let opusLimit = opusLimit, opusLimit > 0 {
            weeklyPct = min(100, max(
                sonnetHours / sonnetLimit * 100,
                opusHours / opusLimit * 100
            ))
        } else {
            weeklyPct = min(100, sonnetHours / sonnetLimit * 100)
        }

        return UsageData(
            fiveHourPercentage: fiveHourPct,
            weeklyPercentage: weeklyPct,
            fiveHourPromptCount: promptCount,
            fiveHourPromptLimit: tier.fiveHourPromptLimit,
            weeklySonnetHours: sonnetHours,
            weeklyOpusHours: opusHours,
            weeklySonnetLimit: sonnetLimit,
            weeklyOpusLimit: opusLimit,
            cycleResetTime: cycleEnd,
            weekResetTime: weekEnd,
            lastRefreshed: now
        )
    }

    /// Calculate weekly model hours by grouping entries into sessions and allocating duration proportionally.
    private func calculateWeeklyModelHours(entries: [ConversationEntry]) -> (sonnet: Double, opus: Double) {
        // Group by sessionId
        var sessions: [String: [ConversationEntry]] = [:]
        for entry in entries {
            let sid = entry.sessionId ?? "unknown"
            sessions[sid, default: []].append(entry)
        }

        var totalSonnetHours: Double = 0
        var totalOpusHours: Double = 0

        for (_, sessionEntries) in sessions {
            guard sessionEntries.count >= 2 else { continue }

            let sorted = sessionEntries.sorted { $0.timestamp < $1.timestamp }
            let duration = sorted.last!.timestamp.timeIntervalSince(sorted.first!.timestamp) / 3600

            guard duration > 0 else { continue }

            // Count assistant responses by model
            let assistantEntries = sessionEntries.filter { $0.type == .assistant && $0.model != nil }
            let sonnetCount = assistantEntries.filter { $0.model == .sonnet }.count
            let opusCount = assistantEntries.filter { $0.model == .opus }.count
            let totalModelCount = sonnetCount + opusCount

            guard totalModelCount > 0 else { continue }

            let sonnetFraction = Double(sonnetCount) / Double(totalModelCount)
            let opusFraction = Double(opusCount) / Double(totalModelCount)

            totalSonnetHours += duration * sonnetFraction
            totalOpusHours += duration * opusFraction
        }

        return (totalSonnetHours, totalOpusHours)
    }

    /// Find the start of the current ISO week (Monday 00:00 UTC).
    private func startOfWeekUTC(from date: Date) -> Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
}
