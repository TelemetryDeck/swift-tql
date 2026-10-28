import SwiftTQL
import Tracing
import Vapor

extension QueryTimeInterval: Content {}

/// Segment state routes on the Overlord.
///
/// Marking segments unused removes them from the Historicals and hides them from queries, but keeps them in deep
/// storage until a kill task deletes them permanently. Mark them used again to undo.
///
/// https://druid.apache.org/docs/latest/api-reference/data-management-api
public struct DataSourcesRoutes {
    let druid: Druid

    public struct SegmentChangeMetadata: Codable, Content {
        public let numChangedSegments: Int?
        public let segmentStateChanged: Bool?
    }

    /// Body of `POST indexer/v1/datasources/{dataSource}/markUnused` and `.../markUsed`. Druid accepts either an
    /// interval (optionally narrowed to segment versions) or a list of segment IDs, never both.
    struct SegmentsFilter: Codable, Content, Equatable {
        var interval: QueryTimeInterval?
        var versions: [String]?
        var segmentIds: [String]?
    }

    static func dataSourceURL(baseURL: String, dataSource: String) -> String {
        "\(baseURL)indexer/v1/datasources/\(dataSource)"
    }

    /// Marks all segments of a datasource that are fully contained in `interval` as unused.
    ///
    /// - Parameter versions: Only mark segments with one of these versions unused. `nil` means every version.
    public func markSegmentsAsUnused(
        datasource: String,
        interval: QueryTimeInterval,
        versions: [String]? = nil
    ) async throws -> SegmentChangeMetadata {
        try await updateSegments(
            dataSource: datasource,
            action: "markUnused",
            filter: .init(interval: interval, versions: versions),
            spanName: "Druid.DataSources.markSegmentsAsUnused"
        )
    }

    /// Marks the given segments of a datasource as unused.
    public func markSegmentsAsUnused(datasource: String, segmentIds: [String]) async throws -> SegmentChangeMetadata {
        try await updateSegments(
            dataSource: datasource,
            action: "markUnused",
            filter: .init(segmentIds: segmentIds),
            spanName: "Druid.DataSources.markSegmentsAsUnused"
        )
    }

    /// Marks all unused segments of a datasource that are fully contained in `interval` as used again. Undoes
    /// `markSegmentsAsUnused` as long as no kill task has deleted the segments yet.
    public func markSegmentsAsUsed(
        datasource: String,
        interval: QueryTimeInterval,
        versions: [String]? = nil
    ) async throws -> SegmentChangeMetadata {
        try await updateSegments(
            dataSource: datasource,
            action: "markUsed",
            filter: .init(interval: interval, versions: versions),
            spanName: "Druid.DataSources.markSegmentsAsUsed"
        )
    }

    /// Marks every segment of a datasource as unused, which removes the datasource from queries.
    public func markAllSegmentsAsUnused(datasource: String) async throws -> SegmentChangeMetadata {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.DataSources.markAllSegmentsAsUnused") { _ in
                let uri = URI(string: Self.dataSourceURL(baseURL: baseURL, dataSource: datasource))

                let response = try await druid.client.delete(uri)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to mark all segments as unused")
                    }
                }

                return try response.content.decode(SegmentChangeMetadata.self)
            }
        }
    }

    private func updateSegments(
        dataSource: String,
        action: String,
        filter: SegmentsFilter,
        spanName: String
    ) async throws -> SegmentChangeMetadata {
        return try await druid.execute { baseURL in
            try await withSpan(spanName) { _ in
                let uri = URI(string: "\(Self.dataSourceURL(baseURL: baseURL, dataSource: dataSource))/\(action)")

                let response = try await druid.client.post(uri, content: filter)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to \(action) segments")
                    }
                }

                return try response.content.decode(SegmentChangeMetadata.self)
            }
        }
    }
}
