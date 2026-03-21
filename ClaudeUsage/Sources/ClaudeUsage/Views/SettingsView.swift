import SwiftUI

struct SettingsView: View {
    @ObservedObject var tracker: UsageTracker
    @AppStorage("planTier") private var selectedTierRaw: String = PlanTier.pro.rawValue

    private var selectedTier: PlanTier {
        PlanTier(rawValue: selectedTierRaw) ?? .pro
    }

    var body: some View {
        Form {
            Section("Subscription Plan") {
                Picker("Plan Tier", selection: $selectedTierRaw) {
                    ForEach(PlanTier.allCases, id: \.rawValue) { tier in
                        Text(tier.rawValue).tag(tier.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedTierRaw) { _, newValue in
                    if let tier = PlanTier(rawValue: newValue) {
                        tracker.planTier = tier
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated Limits for \(selectedTier.rawValue):")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("5hr prompts: ~\(selectedTier.fiveHourPromptLimit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "Weekly Sonnet: ~%.0fh", selectedTier.weeklySonnetHoursLimit))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let opusLimit = selectedTier.weeklyOpusHoursLimit {
                        Text(String(format: "Weekly Opus: ~%.0fh", opusLimit))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }

            Section("About") {
                Text("ClaudeUsage monitors your Claude usage by parsing local conversation data from ~/.claude/projects/")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Limits are estimates based on publicly available information. Actual limits may vary.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
    }
}
