public struct AppendableIndexSpec: Codable, Hashable, Equatable, Sendable {
    public init(type: String, preserveExistingMetrics: Bool? = nil) {
        self.type = type
        self.preserveExistingMetrics = preserveExistingMetrics
    }

    public let type: String
    public let preserveExistingMetrics: Bool?
}
