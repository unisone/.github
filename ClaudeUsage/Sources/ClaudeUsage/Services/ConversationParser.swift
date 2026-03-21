import Foundation

struct ConversationParser {
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Parse all conversation JSONL files under ~/.claude/projects/
    func parseAllConversations(since cutoffDate: Date? = nil) throws -> [ConversationEntry] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let projectsDir = homeDir.appendingPathComponent(".claude/projects")

        guard FileManager.default.fileExists(atPath: projectsDir.path) else {
            return []
        }

        let jsonlFiles = try discoverJSONLFiles(in: projectsDir, modifiedSince: cutoffDate)
        var entries: [ConversationEntry] = []

        for fileURL in jsonlFiles {
            let fileEntries = try parseJSONLFile(at: fileURL)
            entries.append(contentsOf: fileEntries)
        }

        return entries
    }

    /// Discover all .jsonl files under the given directory, optionally filtering by modification date.
    private func discoverJSONLFiles(in directory: URL, modifiedSince cutoff: Date?) throws -> [URL] {
        let fm = FileManager.default
        var jsonlFiles: [URL] = []

        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "jsonl" else { continue }

            let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey])
            guard resourceValues?.isRegularFile == true else { continue }

            if let cutoff = cutoff, let modDate = resourceValues?.contentModificationDate {
                guard modDate >= cutoff else { continue }
            }

            jsonlFiles.append(fileURL)
        }

        return jsonlFiles
    }

    /// Parse a single JSONL file into ConversationEntry records.
    private func parseJSONLFile(at url: URL) throws -> [ConversationEntry] {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else { return [] }

        var entries: [ConversationEntry] = []
        let sessionId = extractSessionId(from: url)

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if let entry = parseLine(trimmed, sessionId: sessionId) {
                entries.append(entry)
            }
        }

        return entries
    }

    /// Extract a session ID from the file path. The parent directory name is often the session ID.
    private func extractSessionId(from url: URL) -> String {
        let parent = url.deletingLastPathComponent().lastPathComponent
        if parent == "subagents" {
            return url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
        }
        return parent
    }

    /// Parse a single JSON line into a ConversationEntry.
    private func parseLine(_ line: String, sessionId: String) -> ConversationEntry? {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Parse timestamp
        guard let timestampStr = json["timestamp"] as? String,
              let timestamp = Self.dateFormatter.date(from: timestampStr)
                              ?? Self.fallbackDateFormatter.date(from: timestampStr) else {
            return nil
        }

        // Parse type
        let typeStr = json["type"] as? String ?? "other"
        let entryType: EntryType
        switch typeStr {
        case "user": entryType = .user
        case "assistant": entryType = .assistant
        case "queue-operation": entryType = .queueOperation
        default: entryType = .other
        }

        // Parse model from message
        var model: ModelType? = nil
        if let message = json["message"] as? [String: Any],
           let modelStr = message["model"] as? String {
            model = ModelType(from: modelStr)
        }

        // Parse userType
        let userType = json["userType"] as? String
        let isExternalUser = userType == "external"

        // Parse isMeta
        let isMeta = json["isMeta"] as? Bool ?? false

        return ConversationEntry(
            type: entryType,
            timestamp: timestamp,
            model: model,
            isExternalUser: isExternalUser,
            isMeta: isMeta,
            sessionId: sessionId
        )
    }
}
