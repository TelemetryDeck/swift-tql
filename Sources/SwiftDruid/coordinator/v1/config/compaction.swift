import SwiftTQL
import Tracing
import Vapor

extension AutoCompactionDynamicConfig: Content {}

/// Per-datasource compaction configs, via Druid's unified compaction API.
///
/// The unified API writes Coordinator compaction configs while compaction supervisors are disabled, and `autocompact`
/// supervisors while they are enabled (`useSupervisors` in the cluster compaction config).
///
/// https://druid.apache.org/docs/latest/api-reference/automatic-compaction-api
public struct CompactionRoutes {
    let druid: Druid

    public struct CompactionConfigReturnType: Codable, Content {
        public let type: String
        public let dataSource: String
        public let taskPriority: Int
        public let maxRowsPerSegment: Int?
        public let skipOffsetFromLatest: String
        public let ioConfig: CompactionIOConfig?
    }

    struct CompactionConfigsResponse: Codable {
        let compactionConfigs: [CompactionConfigReturnType]
    }

    public func list() async throws -> [CompactionConfigReturnType] {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.Compaction.list") { _ in
                let uri = URI(string: "\(baseURL)indexer/v1/compaction/config/datasources")

                let response = try await druid.client.get(uri)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to get compaction config")
                    }
                }

                return try response.content.decode(CompactionConfigsResponse.self).compactionConfigs
            }
        }
    }

    public func create(compactionConfig: AutoCompactionDynamicConfig) async throws {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.Compaction.create") { _ in
                let uri = URI(string: "\(baseURL)indexer/v1/compaction/config/datasources/\(compactionConfig.dataSource)")

                let response = try await druid.client.post(uri, content: compactionConfig)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to create compaction config")
                    }
                }
            }
        }
    }

    public func get(dataSource: String) async throws -> CompactionConfigReturnType? {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.Compaction.get") { _ in
                let uri = URI(string: "\(baseURL)indexer/v1/compaction/config/datasources/\(dataSource)")

                let response = try await druid.client.get(uri)
                if response.status == .notFound { return nil }
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to get compaction config")
                    }
                }

                return try response.content.decode(CompactionConfigReturnType.self)
            }
        }
    }

    public func delete(dataSource: String) async throws {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.Compaction.delete") { _ in
                let uri = URI(string: "\(baseURL)indexer/v1/compaction/config/datasources/\(dataSource)")

                let response = try await druid.client.delete(uri)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to delete compaction config")
                    }
                }
            }
        }
    }
}
