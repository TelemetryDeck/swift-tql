//
//  File.swift
//
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public struct InsightData {
    public init(xAxisValue: String, yAxisValue: String?) {
        self.xAxisValue = xAxisValue
        self.yAxisValue = yAxisValue
    }

    public var xAxisValue: String
    public var yAxisValue: String?

    public enum CodingKeys: String, CodingKey {
        case xAxisValue
        case yAxisValue
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

#if canImport(Vapor)
    import Vapor
    extension InsightData: Content {}
#else
    extension InsightData: Codable {}
#endif

public struct InsightDTO {
    public init(id: UUID, order: Double?, title: String, subtitle: String?, signalType: String?, uniqueUser: Bool, filters: [String: String], rollingWindowSize: TimeInterval, breakdownKey: String? = nil, groupBy: InsightGroupByInterval? = nil, displayMode: InsightDisplayMode, isExpanded: Bool, data: [InsightData], calculatedAt: Date, calculationDuration: TimeInterval, shouldUseDruid: Bool?) {
        self.id = id
        self.group = [:]
        self.order = order
        self.title = title
        self.subtitle = subtitle
        self.signalType = signalType
        self.uniqueUser = uniqueUser
        self.filters = filters
        self.rollingWindowSize = rollingWindowSize
        self.breakdownKey = breakdownKey
        self.groupBy = groupBy
        self.displayMode = displayMode
        self.isExpanded = isExpanded
        self.data = data
        self.calculatedAt = calculatedAt
        self.calculationDuration = calculationDuration
        self.shouldUseDruid = shouldUseDruid
    }

    public let id: UUID
    public var group: [String: UUID]

    public let order: Double?
    public let title: String
    public let subtitle: String?

    /// Which signal types are we interested in? If nil, do not filter by signal type
    public let signalType: String?

    /// If true, only include at the newest signal from each user
    public let uniqueUser: Bool

    /// Only include signals that match all of these key-values in the payload
    public let filters: [String: String]

    /// How far to go back to aggregate signals
    public let rollingWindowSize: TimeInterval

    /// If set, break down the values in this key
    public var breakdownKey: String?

    /// If set, group and count found signals by this time interval. Incompatible with breakdownKey
    public var groupBy: InsightGroupByInterval?

    /// How should this insight's data be displayed?
    public var displayMode: InsightDisplayMode

    /// If true, the insight will be displayed bigger
    var isExpanded: Bool

    /// Current Live Calculated Data
    public let data: [InsightData]

    /// When was this DTO calculated?
    public let calculatedAt: Date

    /// How long did this DTO take to calculate?
    public let calculationDuration: TimeInterval

    /// Should use druid for calculating this insght
    public let shouldUseDruid: Bool?

    public var isEmpty: Bool {
        data.compactMap(\.yAxisValue).count == 0
    }
}

#if canImport(Vapor)
    import Vapor
    extension InsightDTO: Content {}
#else
    extension InsightDTO: Codable {}
#endif
