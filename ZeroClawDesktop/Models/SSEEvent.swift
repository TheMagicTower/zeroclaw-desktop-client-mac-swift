import Foundation

struct SSEEvent: Identifiable {
    let id: UUID
    let type: EventType
    let timestamp: Date
    // Raw JSON payload for display
    let raw: [String: Any]

    enum EventType: String {
        case llmRequest = "llm_request"
        case toolCall = "tool_call"
        case toolCallStart = "tool_call_start"
        case agentStart = "agent_start"
        case agentEnd = "agent_end"
        case error
        case unknown
    }

    init(type: EventType, timestamp: Date, raw: [String: Any]) {
        self.id = UUID()
        self.type = type
        self.timestamp = timestamp
        self.raw = raw
    }

    var iconName: String {
        switch type {
        case .llmRequest: return "brain"
        case .toolCall, .toolCallStart: return "wrench.and.screwdriver"
        case .agentStart: return "play.circle"
        case .agentEnd: return "checkmark.circle"
        case .error: return "exclamationmark.triangle"
        case .unknown: return "questionmark.circle"
        }
    }

    var description: String {
        switch type {
        case .llmRequest:
            let provider = raw["provider"] as? String ?? "?"
            let model = raw["model"] as? String ?? "?"
            return "LLM \(provider)/\(model)"
        case .toolCall:
            let tool = raw["tool"] as? String ?? "?"
            let durationMs = raw["duration_ms"] as? Int
            let success = raw["success"] as? Bool ?? true
            let suffix = durationMs.map { " (\($0)ms)" } ?? ""
            return "\(success ? "Tool" : "Tool failed") \(tool)\(suffix)"
        case .toolCallStart:
            let tool = raw["tool"] as? String ?? "?"
            return "Tool start: \(tool)"
        case .agentStart:
            let model = raw["model"] as? String ?? "?"
            return "Agent started (\(model))"
        case .agentEnd:
            let durationMs = raw["duration_ms"] as? Int ?? 0
            let cost = raw["cost_usd"] as? Double
            let costStr = cost.map { String(format: " $%.4f", $0) } ?? ""
            return "Agent done \(durationMs)ms\(costStr)"
        case .error:
            return raw["message"] as? String ?? "Error"
        case .unknown:
            return raw["type"] as? String ?? "Unknown event"
        }
    }
}
