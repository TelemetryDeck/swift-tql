import SwiftTQL
import Tracing
import Vapor

public struct SQLRoutes {
    let druid: Druid

    public struct DruidSQLQueryType: Codable, Content {
        public struct Context: Codable, Content {
            public enum Engine: String, Codable, Content {
                case native
            }

            let engine: Engine
        }

        let context: Context
        let query: String
    }

    public func execute(query: DruidSQLQueryType) async throws -> [[String: ValueWrapper]] {
        return try await withSpan("Druid.Druid.SQL.Query") { _ in
            let uri = URI(string: "\(druid.baseURL)v2/sql")

            let response = try await druid.client.post(uri, content: query)
            guard response.status == .ok else {
                if let error = try? response.content.decode(DruidError.self) {
                    throw try Abort(response.status, reason: error.errorMessage)
                } else {
                    throw try Abort(.internalServerError, reason: "Failed to run query")
                }
            }

            return try response.content.decode([[String: ValueWrapper]].self)
        }
    }
}
