import SwiftTQL
import Tracing
import Vapor

/// Read-only Coordinator metadata routes.
///
/// https://druid.apache.org/docs/latest/api-reference/data-management-api
public struct CoordinatorRoutes {
    let druid: Druid

    /// One entry of `GET coordinator/v1/datasources/{dataSource}/intervals?simple`: total segment size in bytes
    /// and segment count for one interval.
    public struct IntervalStats: Codable, Content, Equatable, Sendable {
        public let size: Int
        public let count: Int

        public init(size: Int, count: Int) {
            self.size = size
            self.count = count
        }
    }

    static func intervalsURL(baseURL: String, dataSource: String) -> String {
        "\(baseURL)coordinator/v1/datasources/\(dataSource)/intervals?simple"
    }

    /// Segment bytes and counts per interval. Keys are "start/end" ISO 8601 interval strings as Druid returns them
    /// (e.g. "2026-09-01T00:00:00.000Z/2026-10-01T00:00:00.000Z"). Returns nil when the datasource is unknown:
    /// Druid answers 204 No Content (or 404) for it.
    public func intervals(dataSource: String) async throws -> [String: IntervalStats]? {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.Coordinator.intervals") { _ in
                let uri = URI(string: Self.intervalsURL(baseURL: baseURL, dataSource: dataSource))

                let response = try await druid.client.get(uri)
                if response.status == .notFound || response.status == .noContent { return nil }
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to get datasource intervals")
                    }
                }

                return try response.content.decode([String: IntervalStats].self)
            }
        }
    }
}
