import Foundation

enum ModelType: String {
    case sonnet
    case opus
    case unknown

    init(from modelString: String) {
        let lower = modelString.lowercased()
        if lower.contains("opus") {
            self = .opus
        } else if lower.contains("sonnet") {
            self = .sonnet
        } else {
            self = .unknown
        }
    }
}

enum EntryType: String {
    case user
    case assistant
    case queueOperation = "queue-operation"
    case other
}

struct ConversationEntry {
    let type: EntryType
    let timestamp: Date
    let model: ModelType?
    let isExternalUser: Bool
    let isMeta: Bool
    let sessionId: String?
}
