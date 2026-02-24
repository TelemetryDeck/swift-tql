import SwiftTQL
import Tracing
import Vapor

extension QueryTimeInterval: Content {}

public struct DataSourcesRoutes {
    let druid: Druid

    public struct SegmentChangeMetadata: Codable, Content {
        public let numChangedSegments: Int?
        public let segmentStateChanged: Bool?
    }

    public func markSegmentsAsUnused(datasource: String, interval: QueryTimeInterval) async throws -> SegmentChangeMetadata {
        return try await withSpan("Druid.DataSources.markSegmentsAsUnused") { _ in
            let uri = URI(string: "\(druid.baseURL)indexer/v1/datasources/\(datasource)/markUnused")

            let response = try await druid.client.post(uri, content: ["interval": interval])
            guard response.status == .ok else {
                if let error = try? response.content.decode(DruidError.self) {
                    throw Abort(response.status, reason: error.errorMessage)
                } else {
                    throw Abort(.internalServerError, reason: "Failed to run query")
                }
            }

            return try response.content.decode(SegmentChangeMetadata.self)
        }
    }
}
