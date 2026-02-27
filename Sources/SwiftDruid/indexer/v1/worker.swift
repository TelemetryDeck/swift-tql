import SwiftTQL
import Tracing
import Vapor

public struct OverlordRoutes {
    let druid: Druid

    // MARK: - Overlord Dynamic Configuration

    /// Overlord dynamic configuration for worker assignment
    /// Reference: https://druid.apache.org/docs/latest/api-reference/dynamic-configuration-api#overlord-dynamic-configuration
    public struct OverlordDynamicConfig: Content {
        public init(
            type: String = "default",
            selectStrategy: SelectStrategy? = nil,
            autoScaler: AutoScaler? = nil
        ) {
            self.type = type
            self.selectStrategy = selectStrategy
            self.autoScaler = autoScaler
        }

        /// The type of configuration, defaults to "default"
        public var type: String

        /// Strategy for selecting which workers to assign tasks to
        public var selectStrategy: SelectStrategy?

        /// Autoscaler configuration (null if autoscaling is disabled)
        public var autoScaler: AutoScaler?
    }

    /// Strategy the Overlord uses to assign tasks to workers
    public struct SelectStrategy: Content {
        public init(
            type: SelectStrategyType,
            workerCategorySpec: WorkerCategorySpec? = nil,
            affinityConfig: [String: [String]]? = nil
        ) {
            self.type = type
            self.workerCategorySpec = workerCategorySpec
            self.affinityConfig = affinityConfig
        }

        /// Strategy type (e.g., "fillCapacity", "equalDistribution",
        /// "fillCapacityWithCategorySpec", "equalDistributionWithCategorySpec")
        public var type: SelectStrategyType

        /// Worker category specification for category-based strategies
        public var workerCategorySpec: WorkerCategorySpec?

        public var affinityConfig: [String: [String]]?

        public enum SelectStrategyType: String, Content {
            case equalDistribution
            case equalDistributionWithCategorySpec
            case fillCapacity
            case fillCapacityWithCategorySpec
        }
    }

    /// Configuration for worker categories
    public struct WorkerCategorySpec: Content {
        public init(
            categoryMap: [String: CategoryConfig] = [:],
            strong: Bool = false
        ) {
            self.categoryMap = categoryMap
            self.strong = strong
        }

        /// Maps task type to worker category
        public var categoryMap: [String: CategoryConfig]

        /// When true, tasks wait for preferred category workers
        /// When false, tasks can fall back to any available worker
        public var strong: Bool
    }

    public struct CategoryConfig: Content {
        public init(defaultCategory: String? = nil, categoryAffinity: [String : String]? = nil) {
            self.defaultCategory = defaultCategory
            self.categoryAffinity = categoryAffinity
        }
        
        /// Specify default category for a task type.
        public var defaultCategory: String?

        /// An object mapping a datasource name to a category name of the Middle Manager.
        ///
        /// If category isn't specified for a datasource, then using the defaultCategory. If no specified category and the defaultCategory is also null, then tasks can run on any available Middle Managers.
        public var categoryAffinity: [String: String]?
    }

    /// Autoscaler configuration
    public struct AutoScaler: Content {
        public init(type: String) {
            self.type = type
        }

        /// Type of autoscaler (e.g., "ec2", "gce")
        public var type: String

        // Additional autoscaler-specific fields can be added as needed
    }

    /// Get current Overlord dynamic configuration
    public func getConfig() async throws -> OverlordDynamicConfig? {
        try await withSpan("Druid.Overlord.getConfig") { _ in
            let uri = URI(string: "\(druid.baseURL)indexer/v1/worker")

            let response = try await druid.client.get(uri)
            guard response.status == .ok else {
                if let error = try? response.content.decode(DruidError.self) {
                    throw Abort(response.status, reason: error.errorMessage)
                } else {
                    throw Abort(.internalServerError, reason: "Failed to get overlord config")
                }
            }

            // Returns nil if no configuration is set
            if response.body == nil || response.body?.readableBytes == 0 {
                return nil
            }

            return try response.content.decode(OverlordDynamicConfig.self)
        }
    }

    /// Update Overlord dynamic configuration
    public func updateConfig(
        _ config: OverlordDynamicConfig,
        author: String? = nil,
        comment: String? = nil
    ) async throws {
        try await withSpan("Druid.Overlord.updateConfig") { _ in
            let uri = URI(string: "\(druid.baseURL)indexer/v1/worker")

            var headers = HTTPHeaders()
            if let author = author {
                headers.add(name: "X-Druid-Author", value: author)
            }
            if let comment = comment {
                headers.add(name: "X-Druid-Comment", value: comment)
            }

            let response = try await druid.client.post(uri, headers: headers, content: config)
            guard response.status == .ok else {
                if let error = try? response.content.decode(DruidError.self) {
                    throw Abort(response.status, reason: error.errorMessage)
                } else {
                    throw Abort(.internalServerError, reason: "Failed to update overlord config")
                }
            }
        }
    }

    /// Get Overlord dynamic configuration history
    public func getConfigHistory(
        interval: String? = nil,
        count: Int? = nil
    ) async throws -> [ConfigHistoryEntry] {
        try await withSpan("Druid.Overlord.getConfigHistory") { _ in
            var uri = URI(string: "\(druid.baseURL)indexer/v1/worker/history")

            var queryItems: [String] = []
            if let interval = interval {
                queryItems.append("interval=\(interval)")
            }
            if let count = count {
                queryItems.append("count=\(count)")
            }
            if !queryItems.isEmpty {
                uri = URI(string: "\(druid.baseURL)indexer/v1/worker/history?\(queryItems.joined(separator: "&"))")
            }

            let response = try await druid.client.get(uri)
            guard response.status == .ok else {
                if let error = try? response.content.decode(DruidError.self) {
                    throw Abort(response.status, reason: error.errorMessage)
                } else {
                    throw Abort(.internalServerError, reason: "Failed to get config history")
                }
            }

            return try response.content.decode([ConfigHistoryEntry].self)
        }
    }

    /// Configuration history entry
    public struct ConfigHistoryEntry: Content {
        public var config: OverlordDynamicConfig
        public var auditInfo: AuditInfo

        public struct AuditInfo: Content {
            public var author: String
            public var comment: String
            public var ip: String
            public var auditTime: String
        }
    }
}
