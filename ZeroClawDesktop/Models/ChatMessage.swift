import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: Role
    var content: String
    let timestamp: Date
    var isStreaming: Bool

    enum Role: Codable {
        case user
        case assistant
        case toolCall(name: String)
        case toolResult(name: String)
        case error

        private enum CodingKeys: String, CodingKey { case type, name }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            switch try c.decode(String.self, forKey: .type) {
            case "user":       self = .user
            case "assistant":  self = .assistant
            case "toolCall":   self = .toolCall(name: try c.decode(String.self, forKey: .name))
            case "toolResult": self = .toolResult(name: try c.decode(String.self, forKey: .name))
            default:           self = .error
            }
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .user:                 try c.encode("user",       forKey: .type)
            case .assistant:            try c.encode("assistant",  forKey: .type)
            case .toolCall(let name):   try c.encode("toolCall",   forKey: .type); try c.encode(name, forKey: .name)
            case .toolResult(let name): try c.encode("toolResult", forKey: .type); try c.encode(name, forKey: .name)
            case .error:                try c.encode("error",      forKey: .type)
            }
        }
    }

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }

    static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: .user, content: content)
    }

    static func assistant(_ content: String, streaming: Bool = false) -> ChatMessage {
        ChatMessage(role: .assistant, content: content, isStreaming: streaming)
    }
}
