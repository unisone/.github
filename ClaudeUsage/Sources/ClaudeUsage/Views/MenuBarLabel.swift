import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var tracker: UsageTracker

    var body: some View {
        if let data = tracker.usageData {
            Text("\(Int(data.fiveHourPercentage))% \u{00B7} \(Int(data.weeklyPercentage))%")
        } else {
            Image(systemName: "chart.bar")
        }
    }
}
