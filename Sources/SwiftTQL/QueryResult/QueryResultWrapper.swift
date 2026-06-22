import Foundation

@available(*, deprecated, message: "QueryResults should passed around as QueryResultData as much as possible.")
public struct QueryResultWrapper: Codable, Hashable, Equatable, Sendable {
    public let result: QueryResult?
    public let error: String?

    public let calculationDuration: TimeInterval
    public let calculationFinishedAt: Date

    public init(result: QueryResult?, calculationDuration: TimeInterval, finishedAt: Date, error: String?) {
        self.result = result
        self.calculationDuration = calculationDuration
        self.error = error
        calculationFinishedAt = finishedAt
    }
}
