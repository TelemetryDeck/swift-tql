import Foundation

public struct DruidTimeSeriesResult: Codable {
    public init(timestamp: Date, result: [String : Double]) {
        self.timestamp = timestamp
        self.result = result
    }
    
    public let timestamp: Date
    public let result: [String: Double]
}

public enum DruidResultType: String, Codable {
    case timeSeries
}

public struct DruidResultWrapper: Codable {
    public let resultType: DruidResultType
    public let timeSeriesResults: [DruidTimeSeriesResult]

    public init(resultType: DruidResultType, timeSeriesResults: [DruidTimeSeriesResult]) {
        self.resultType = resultType
        self.timeSeriesResults = timeSeriesResults
    }
}
