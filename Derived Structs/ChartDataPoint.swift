import Foundation

/// A single data point in a `ChartDataSet`
public struct ChartDataPoint: Hashable, Identifiable {
    public var id: String { xAxisValue }

    public let xAxisValue: String
    public let yAxisValue: String?
    
    public init(xAxisValue: String, yAxisValue: String?) {
        self.xAxisValue = xAxisValue
        self.yAxisValue = yAxisValue
    }
    
    init(insightData: DTO.InsightData) {
        self.init(xAxisValue: insightData.xAxisValue, yAxisValue: insightData.yAxisValue)
    }
    
    private let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.usesGroupingSeparator = true
        return numberFormatter
    }()

    public var yAxisNumber: NSNumber? {
        guard let yAxisValue = yAxisValue else { return NSNumber(value: 0) }
        return numberFormatter.number(from: yAxisValue)
    }

    public var yAxisDouble: Double? {
        yAxisNumber?.doubleValue
    }

    public var xAxisDate: Date? {
        if #available(macOS 10.14, iOS 14.0, *) {
            return Formatter.iso8601noFS.date(from: xAxisValue) ?? Formatter.iso8601.date(from: xAxisValue)
        } else {
            return nil
        }
    }
}
