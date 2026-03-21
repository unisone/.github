import SwiftUI

struct UsagePopoverView: View {
    @ObservedObject var tracker: UsageTracker

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let data = tracker.usageData {
                usageContent(data)
            } else if tracker.isLoading {
                ProgressView("Loading usage data...")
                    .padding()
            } else if let error = tracker.lastError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            } else {
                Text("No usage data available")
                    .foregroundColor(.secondary)
                    .padding()
            }

            Divider()

            actionButtons
        }
        .padding(12)
        .onAppear {
            tracker.startAutoRefresh()
        }
    }

    @ViewBuilder
    private func usageContent(_ data: UsageData) -> some View {
        // 5-Hour Cycle
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("5-Hour Cycle")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("Resets in \(data.cycleTimeRemainingFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            UsageBar(
                percentage: data.fiveHourPercentage,
                label: "\(data.fiveHourPromptCount)/\(data.fiveHourPromptLimit) prompts"
            )
        }

        // Weekly Usage
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Weekly Usage")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("Resets in \(data.weekTimeRemainingFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            UsageBar(
                percentage: data.weeklyPercentage,
                label: "Overall"
            )

            // Model breakdown
            HStack {
                Text("Sonnet:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1fh / %.0fh", data.weeklySonnetHours, data.weeklySonnetLimit))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            if let opusLimit = data.weeklyOpusLimit {
                HStack {
                    Text("Opus:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1fh / %.0fh", data.weeklyOpusHours, opusLimit))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }

        // Last refreshed
        HStack {
            Spacer()
            Text("Updated \(data.lastRefreshed, style: .relative) ago")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 2) {
            Button {
                if let url = URL(string: "https://claude.ai") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text("Open Dashboard")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)

            Button {
                Task { await tracker.refresh() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                    Spacer()
                    Text("\u{2318}R")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .keyboardShortcut("r", modifiers: .command)

            Divider()

            SettingsLink {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings...")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Quit")
                    Spacer()
                    Text("\u{2318}Q")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

struct UsageBar: View {
    let percentage: Double
    let label: String

    private var barColor: Color {
        if percentage < 50 { return .green }
        if percentage < 80 { return .orange }
        return .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("\(Int(percentage))%")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(barColor)
                Spacer()
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geometry.size.width * min(1, percentage / 100), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
