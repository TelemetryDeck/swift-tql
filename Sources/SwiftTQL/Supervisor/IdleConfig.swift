/// When the supervisor enters the idle state, no new tasks are launched subsequent to the completion of the currently executing tasks. This strategy may lead to reduced costs for cluster operators while using topics that get sporadic data. Idle state transitioning is currently designated as experimental.
public struct IdleConfig: Codable, Hashable, Equatable, Sendable {
    public init(enabled: Bool? = nil, inactiveAfterMillis: Int? = nil) {
        self.enabled = enabled
        self.inactiveAfterMillis = inactiveAfterMillis
    }

    public let enabled: Bool?
    public let inactiveAfterMillis: Int?
}
