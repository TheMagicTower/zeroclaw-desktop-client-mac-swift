import Foundation

enum SubmitMode: String, Codable, CaseIterable {
    case cmdEnter = "cmdEnter"
    case enter    = "enter"

    var label: String {
        switch self {
        case .cmdEnter: return "Cmd+Return"
        case .enter:    return "Return"
        }
    }

    var placeholder: String {
        switch self {
        case .cmdEnter: return "Message ZeroClaw… (Cmd+Return to send)"
        case .enter:    return "Message ZeroClaw… (Return to send)"
        }
    }
}

struct ConnectionProfile: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var endpointURL: String
    var submitMode: SubmitMode

    init(id: UUID = UUID(), name: String, endpointURL: String, submitMode: SubmitMode = .cmdEnter) {
        self.id = id
        self.name = name
        self.endpointURL = endpointURL
        self.submitMode = submitMode
    }

    // Custom decode so old profiles without submitMode default to .cmdEnter
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        endpointURL = try c.decode(String.self, forKey: .endpointURL)
        submitMode = (try? c.decode(SubmitMode.self, forKey: .submitMode)) ?? .cmdEnter
    }

    var baseURL: URL? {
        var s = endpointURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return nil }
        if !s.hasSuffix("/") { s += "/" }
        return URL(string: s)
    }

    var displayHost: String {
        guard let url = URL(string: endpointURL), let host = url.host else {
            return endpointURL
        }
        if let port = url.port { return "\(host):\(port)" }
        return host
    }
}
