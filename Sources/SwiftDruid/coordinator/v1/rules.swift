import SwiftTQL
import Tracing
import Vapor

extension RetentionRule: Content {}

/// Retention rules on the Coordinator.
///
/// Druid has no delete endpoint for rules: `delete(dataSource:)` stores an empty rule list, which makes the datasource
/// fall back to the cluster default rules (`_default`).
///
/// https://druid.apache.org/docs/latest/api-reference/retention-rules-api
public struct RetentionRuleRoutes {
    let druid: Druid

    /// The datasource name Druid uses for the cluster default rules.
    public static let defaultRulesDataSource = "_default"

    static func rulesURL(baseURL: String, dataSource: String? = nil, full: Bool = false) -> String {
        guard let dataSource else { return "\(baseURL)coordinator/v1/rules" }
        return "\(baseURL)coordinator/v1/rules/\(dataSource)\(full ? "?full" : "")"
    }

    /// Rules of every datasource that has rules, keyed by datasource, including `_default`.
    public func list() async throws -> [String: [RetentionRule]] {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.RetentionRules.list") { _ in
                let uri = URI(string: Self.rulesURL(baseURL: baseURL))

                let response = try await druid.client.get(uri)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to list retention rules")
                    }
                }

                return try response.content.decode([String: [RetentionRule]].self)
            }
        }
    }

    /// Rules of one datasource. Empty when the datasource has no rules of its own.
    ///
    /// - Parameter full: Append the cluster default rules, i.e. return the full list the Coordinator evaluates.
    public func get(dataSource: String, full: Bool = false) async throws -> [RetentionRule] {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.RetentionRules.get") { _ in
                let uri = URI(string: Self.rulesURL(baseURL: baseURL, dataSource: dataSource, full: full))

                let response = try await druid.client.get(uri)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to get retention rules")
                    }
                }

                return try response.content.decode([RetentionRule].self)
            }
        }
    }

    /// Replaces all rules of a datasource. Druid rejects rule lists in which a rule can never match because an
    /// earlier rule (e.g. `loadForever`) already covers every segment.
    ///
    /// - Parameters:
    ///   - author: Stored in the rule audit history (`X-Druid-Author`).
    ///   - comment: Stored in the rule audit history (`X-Druid-Comment`).
    public func set(dataSource: String, rules: [RetentionRule], author: String? = nil, comment: String? = nil) async throws {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.RetentionRules.set") { _ in
                let uri = URI(string: Self.rulesURL(baseURL: baseURL, dataSource: dataSource))

                var headers = HTTPHeaders()
                if let author { headers.add(name: "X-Druid-Author", value: author) }
                if let comment { headers.add(name: "X-Druid-Comment", value: comment) }

                let response = try await druid.client.post(uri, headers: headers, content: rules)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to set retention rules")
                    }
                }
            }
        }
    }

    /// Removes all rules of a datasource so the cluster default rules apply to it.
    public func delete(dataSource: String, author: String? = nil, comment: String? = nil) async throws {
        try await set(dataSource: dataSource, rules: [], author: author, comment: comment)
    }
}
