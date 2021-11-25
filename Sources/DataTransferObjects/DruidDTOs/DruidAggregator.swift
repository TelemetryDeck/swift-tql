import Foundation

public struct DruidAggregator: Codable, Hashable {
    public init(type: DruidAggregatorType, name: String, fieldName: String? = nil) {
        self.type = type
        self.name = name
        self.fieldName = fieldName
    }
    
    public let type: DruidAggregatorType
    public let name: String
    public var fieldName: String? = nil // should be nil for type count, maybe that should be enforced in code?
}

public enum DruidAggregatorType: String, Codable, Hashable {
    case countÒ

    case longSum
    case doubleSum
    case floatSum

    case doubleMin
    case doubleMax
    case floatMin
    case floatMax
    case longMin
    case longMax

    case doubleMean

    case doubleFirst
    case doubleLast
    case floatFirst
    case floatLast
    case longFirst
    case longLast
    case stringFirst
    case stringLast

    case doubleAny
    case floatAny
    case longAny
    case stringAny

    case thetaSketch

    // JavaScript aggregator missing
}
