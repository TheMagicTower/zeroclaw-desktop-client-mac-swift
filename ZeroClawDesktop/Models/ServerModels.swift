import Foundation

// MARK: - History API

struct ServerHistoryMessage: Decodable {
    let id: String
    let role: String
    let name: String?
    let content: String
    let timestamp: Date?

    private enum CodingKeys: String, CodingKey {
        case id, role, name, content, timestamp
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(String.self, forKey: .id)
        role      = try c.decode(String.self, forKey: .role)
        name      = try? c.decode(String.self, forKey: .name)
        content   = (try? c.decode(String.self, forKey: .content)) ?? ""
        // Accept ISO8601 string or missing
        if let raw = try? c.decode(String.self, forKey: .timestamp) {
            timestamp = ISO8601DateFormatter().date(from: raw)
        } else {
            timestamp = nil
        }
    }

    func toChatMessage() -> ChatMessage? {
        let role: ChatMessage.Role
        switch self.role {
        case "user":        role = .user
        case "assistant":   role = .assistant
        case "tool_call":   role = .toolCall(name: name ?? "unknown")
        case "tool_result": role = .toolResult(name: name ?? "unknown")
        case "error":       role = .error
        default:            return nil
        }
        return ChatMessage(
            id: UUID(uuidString: id) ?? UUID(),
            role: role,
            content: content,
            timestamp: timestamp ?? Date()
        )
    }
}

struct ServerHistoryResponse: Decodable {
    let messages: [ServerHistoryMessage]
}

// Raw JSON from /api/status — fields vary by ZeroClaw config,
// so we keep it as a display-friendly key-value list.
struct ServerStatusDisplay {
    let fields: [(key: String, value: String)]

    init(json: [String: Any]) {
        var result: [(key: String, value: String)] = []
        Self.flatten(json: json, prefix: "", into: &result)
        fields = result.sorted { $0.key < $1.key }
    }

    static func flatten(json: [String: Any], prefix: String, into result: inout [(key: String, value: String)]) {
        for (key, value) in json {
            let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
            if let nested = value as? [String: Any] {
                flatten(json: nested, prefix: fullKey, into: &result)
            } else if value is NSNull {
                // skip null values
            } else {
                result.append((key: fullKey, value: "\(value)"))
            }
        }
    }
}

// Raw JSON from /api/cost
struct CostDisplay {
    let fields: [(key: String, value: String)]
    let totalCostUSD: Double?

    init(json: [String: Any]) {
        var result: [(key: String, value: String)] = []
        ServerStatusDisplay.flatten(json: json, prefix: "", into: &result)
        fields = result.sorted { $0.key < $1.key }
        totalCostUSD = json["total_cost_usd"] as? Double
    }
}
