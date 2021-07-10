import Foundation

/// A single data point in a `ChartDataSet`
public struct ChartDataPoint: Hashable, Identifiable {
    public var id: String { xAxisValue }

    public let xAxisValue: String
    public let xAxisDate: Date?
    
    public let yAxisValue: String?
    public let yAxisDouble: Double?
    
    public init(xAxisValue: String, yAxisValue: String?) {
        self.xAxisValue = xAxisValue
        self.yAxisValue = yAxisValue
        
        if let yAxisValue = yAxisValue {
            yAxisDouble = Double(yAxisValue)
        } else {
            yAxisDouble = nil
        }
        
        if #available(macOS 10.14, iOS 14.0, *) {
            xAxisDate = Formatter.iso8601noFS.date(from: xAxisValue) ?? Formatter.iso8601.date(from: xAxisValue)
        } else {
            xAxisDate = nil
        }
    }
    
    init(insightData: DTO.InsightData) {
        self.init(xAxisValue: insightData.xAxisValue, yAxisValue: insightData.yAxisValue)
    }
}
