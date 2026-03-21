import Foundation

enum PlanTier: String, CaseIterable, Codable {
    case pro = "Pro"
    case max5x = "Max 5x"
    case max20x = "Max 20x"

    /// Midpoint estimate of the 5-hour prompt limit for this tier.
    var fiveHourPromptLimit: Int {
        switch self {
        case .pro:    return 25
        case .max5x:  return 125
        case .max20x: return 500
        }
    }

    /// Midpoint estimate of weekly Sonnet hours allowed.
    var weeklySonnetHoursLimit: Double {
        switch self {
        case .pro:    return 60
        case .max5x:  return 210
        case .max20x: return 360
        }
    }

    /// Midpoint estimate of weekly Opus hours allowed. Nil for Pro (no Opus access).
    var weeklyOpusHoursLimit: Double? {
        switch self {
        case .pro:    return nil
        case .max5x:  return 25
        case .max20x: return 32
        }
    }
}
