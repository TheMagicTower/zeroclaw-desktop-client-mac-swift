import Foundation

enum ZeroClawError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(Int, String)
    case noToken

    var errorDescription: String? {
        switch self {
        case .invalidURL:    return "Invalid server URL"
        case .unauthorized:  return "Unauthorized — pair first via Settings"
        case .serverError(let code, let msg): return "Server error \(code): \(msg)"
        case .noToken:       return "No bearer token — pair first"
        }
    }
}

// Thread-safe REST + SSE client for the ZeroClaw daemon gateway.
final class ZeroClawClient {
    let baseURL: URL
    private(set) var token: String?

    init(baseURL: URL, token: String? = nil) {
        self.baseURL = baseURL
        self.token = token
    }

    func setToken(_ token: String?) {
        self.token = token
    }

    // MARK: - Pairing

    /// POST /pair — exchange pairing code for bearer token.
    /// ZeroClaw expects the code in the `X-Pairing-Code` header.
    func pair(code: String) async throws -> String {
        let url = baseURL.appendingPathComponent("pair")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(code, forHTTPHeaderField: "X-Pairing-Code")
        let (data, response) = try await URLSession.shared.data(for: req)
        try validateResponse(response, data: data)
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let t = json["token"] as? String
        else {
            throw ZeroClawError.serverError(-1, "No token in pairing response")
        }
        self.token = t
        return t
    }

    // MARK: - Chat

    /// POST /webhook — server only accepts {"message": "..."},
    /// so conversation history is injected into the message text itself.
    func webhook(message: String) async throws -> String {
        guard let url = URL(string: "webhook", relativeTo: baseURL) else {
            throw ZeroClawError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["message": message])
        let (data, response) = try await URLSession.shared.data(for: req)
        try validateResponse(response, data: data)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return (json["response"] as? String)
                ?? (json["message"] as? String)
                ?? (json["content"] as? String)
                ?? (json["reply"] as? String)
                ?? (String(data: data, encoding: .utf8) ?? "")
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - REST endpoints

    func status() async throws -> [String: Any] {
        try await getJSON("api/status")
    }

    func cost() async throws -> [String: Any] {
        try await getJSON("api/cost")
    }

    func health() async throws -> [String: Any] {
        try await getJSON("health")
    }

    func config() async throws -> [String: Any] {
        try await getJSON("api/config")
    }

    func fetchHistory() async throws -> [ServerHistoryMessage] {
        guard let url = URL(string: "api/history", relativeTo: baseURL) else {
            throw ZeroClawError.invalidURL
        }
        var req = URLRequest(url: url)
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: req)
        try validateResponse(response, data: data)
        let decoded = try JSONDecoder().decode(ServerHistoryResponse.self, from: data)
        return decoded.messages
    }

    func tools() async throws -> [[String: Any]] {
        let json = try await getJSON("api/tools")
        return json["tools"] as? [[String: Any]] ?? []
    }

    // MARK: - SSE Event stream

    /// GET /api/events — yields SSEEvents until the stream closes.
    /// Reconnection is handled by the caller (StatusViewModel).
    func eventStream() -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            // detached: byte-reading loop must not run on @MainActor
            Task.detached(priority: .utility) { [self] in
                guard let url = URL(string: "api/events", relativeTo: self.baseURL) else {
                    continuation.finish(throwing: ZeroClawError.invalidURL)
                    return
                }
                var req = URLRequest(url: url)
                req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                if let token = self.token {
                    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                do {
                    let (bytes, httpResponse) = try await URLSession.shared.bytes(for: req)
                    if let http = httpResponse as? HTTPURLResponse, http.statusCode == 401 {
                        continuation.finish(throwing: ZeroClawError.unauthorized)
                        return
                    }
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        guard
                            let data = payload.data(using: .utf8),
                            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        else { continue }
                        let event = self.makeSSEEvent(from: json)
                        continuation.yield(event)
                    }
                } catch {
                    continuation.finish(throwing: error)
                    return
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Helpers

    private func getJSON(_ path: String) async throws -> [String: Any] {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw ZeroClawError.invalidURL
        }
        var req = URLRequest(url: url)
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        try validateResponse(response, data: data)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299: return
        case 401: throw ZeroClawError.unauthorized
        default:
            let body = String(data: data, encoding: .utf8) ?? "(empty)"
            throw ZeroClawError.serverError(http.statusCode, body)
        }
    }

    private func makeSSEEvent(from json: [String: Any]) -> SSEEvent {
        let typeStr = json["type"] as? String ?? ""
        let type = SSEEvent.EventType(rawValue: typeStr) ?? .unknown
        return SSEEvent(type: type, timestamp: Date(), raw: json)
    }
}
