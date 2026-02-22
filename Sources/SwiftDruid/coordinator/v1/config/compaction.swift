import SwiftTQL
import Tracing
import Vapor

public struct CompactionRoutes {
    let druid: Druid

    public struct CompactionConfigReturnType: Codable, Content {
        public let type: String
        public let dataSource: String
        public let taskPriority: Int
        public let maxRowsPerSegment: Int?
        public let skipOffsetFromLatest: String
    }

    public func list() async throws -> [CompactionConfigReturnType] {
        return try await withSpan("Druid.Supervisor.list") { _ in
            let uri = URI(string: "\(druid.baseURL)coordinator/v1/config/compaction/")

            let response = try await druid.client.get(uri)
            guard response.status == .ok else {
                if let error = try? response.content.decode(DruidError.self) {
                    throw try Abort(response.status, reason: error.errorMessage)
                } else {
                    throw Abort(.internalServerError, reason: "Failed to get compaction config")
                }
            }

            return try response.content.decode([CompactionConfigReturnType].self)
        }
    }

//    public func create(compactionConfig: AutoCompactionDynamicConfig) async throws -> CompactionConfigReturnType? {
//        return try await withSpan("Druid.Supervisor.create") { _ in
//            let uri = URI(string: "\(druid.baseURL)coordinator/v1/config/compaction")
//
//            let response = try await druid.client.post(uri, content: compactionConfig)
//            if response.status == .notFound { return nil }
//            guard response.status == .ok else {
//                if let error = try? response.content.decode(DruidError.self) {
//                    throw try Abort(response.status, reason: error.errorMessage)
//                } else {
//                    throw Abort(.internalServerError, reason: "Failed to create compaction config")
//                }
//            }
//
//            return try response.content.decode(CompactionConfigReturnType.self)
//        }
//    }

    public func get(dataSource: String) async throws -> CompactionConfigReturnType? {
        return try await withSpan("Druid.Supervisor.list") { _ in
            let uri = URI(string: "\(druid.baseURL)coordinator/v1/config/compaction/\(dataSource)")

            let response = try await druid.client.get(uri)
            if response.status == .notFound { return nil }
            guard response.status == .ok else {
                if let error = try? response.content.decode(DruidError.self) {
                    throw try Abort(response.status, reason: error.errorMessage)
                } else {
                    throw Abort(.internalServerError, reason: "Failed to get compaction config")
                }
            }

            return try response.content.decode(CompactionConfigReturnType.self)
        }
    }

    public func delete(dataSource: String) async throws {
        return try await withSpan("Druid.Supervisor.delete") { _ in
            let uri = URI(string: "\(druid.baseURL)coordinator/v1/config/compaction/\(dataSource)")

            let response = try await druid.client.delete(uri)
            guard response.status == .ok else {
                if let error = try? response.content.decode(DruidError.self) {
                    throw try Abort(response.status, reason: error.errorMessage)
                } else {
                    throw Abort(.internalServerError, reason: "Failed to delete compaction config")
                }
            }
        }
    }
}
