import Foundation

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
