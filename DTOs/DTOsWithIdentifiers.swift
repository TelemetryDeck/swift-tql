//
//  InsightDTOs.swift
//  InsightDTOs
//
//  Created by Daniel Jilg on 17.08.21.
//

import Foundation

public enum DTOsWithIdentifiers {
    public struct Organization: Codable, Hashable, Identifiable {
        public var id: UUID
        public var name: String
        public var createdAt: Date?
        public var updatedAt: Date?
        public var isSuperOrg: Bool
        public var stripeMaxSignals: Int64?
        public var maxSignalsMultiplier: Double?
        public var resolvedMaxSignals: Int64
        public var isInRestrictedMode: Bool
        public var appIDs: [App.ID]
        public var badgeAwardIDs: [BadgeAward.ID]
    }
    
    public struct BadgeAward: Codable, Hashable, Identifiable {
        public var id: UUID
        public var badgeID: UUID
        public var organizationID: UUID
        public var awardedAt: Date
    }
    
    public struct Badge: Codable, Hashable, Identifiable {
        public var id: UUID
        public var title: String
        public var description: String
        public var imageURL: URL?
        public var signalCountMultiplier: Double?
    }
    
    public struct App: Codable, Hashable, Identifiable {
        public var id: UUID
        public var name: String
        public var organizationID: Organization.ID
        public var insightGroupIDs: [Group.ID]
    }
    
    public struct Group: Codable, Hashable, Identifiable {
        public var id: UUID
        public var title: String
        public var order: Double?
        public var appID: App.ID
        public var insightIDs: [Insight.ID]
    }
    
    /// Defines an insight as saved to the database, no calculation results
    public struct Insight: Codable, Hashable, Identifiable {
        public var id: UUID
        public var groupID: UUID

        public var order: Double?
        public var title: String
        
        /// If set, use the custom query in this property instead of constructing a query out of the options below
        var druidCustomQuery: DruidCustomQuery?

        /// Which signal types are we interested in? If nil, do not filter by signal type
        public var signalType: String?

        /// If true, only include at the newest signal from each user
        public var uniqueUser: Bool

        /// Only include signals that match all of these key-values in the payload
        public var filters: [String: String]

        /// If set, break down the values in this key
        public var breakdownKey: String?

        /// If set, group and count found signals by this time interval. Incompatible with breakdownKey
        public var groupBy: InsightGroupByInterval?

        /// How should this insight's data be displayed?
        public var displayMode: InsightDisplayMode

        /// If true, the insight will be displayed bigger
        public var isExpanded: Bool

        /// The amount of time (in seconds) this query took to calculate last time
        public var lastRunTime: TimeInterval?

        /// The date this query was last run
        public var lastRunAt: Date?
    }
    
    /// Defines the result of an insight calculation
    public struct InsightCalculationResult: Codable, Hashable, Identifiable {
        /// The ID of the insight that was calculated
        public let id: UUID

        /// The insight that was calculated
        public let insight: DTOsWithIdentifiers.Insight

        /// Current Live Calculated Data
        public let data: [DTOsWithIdentifiers.InsightCalculationResultRow]

        /// When was this DTO calculated?
        public let calculatedAt: Date

        /// How long did this DTO take to calculate?
        public let calculationDuration: TimeInterval
    }
    
    /// Actual row of data inside an InsightCalculationResult
    public struct InsightCalculationResultRow: Codable, Hashable {
        public var xAxisValue: String
        public var yAxisValue: Int64
    }
    
    public struct PriceStructure: Identifiable, Codable {
        public let id: String
        public let order: Int
        public let title: String
        public let description: String
        public let includedSignals: Int64
        public let price: String
    }
    
    /// A short message that goes out to  users and is usually displayed in the app UI
    public struct StatusMessage: Identifiable, Codable {
        public let id: String
        public let validFrom: Date
        public let validUntil: Date?
        public let title: String
        public let description: String?
        public let systemImageName: String?
    }
}


#if canImport(Vapor)
import Vapor

extension DTOsWithIdentifiers.Organization: Content {}
extension DTOsWithIdentifiers.BadgeAward: Content {}
extension DTOsWithIdentifiers.Badge: Content {}
extension DTOsWithIdentifiers.App: Content {}
extension DTOsWithIdentifiers.Group: Content {}
extension DTOsWithIdentifiers.Insight: Content {}
extension DTOsWithIdentifiers.InsightCalculationResult: Content {}
extension DTOsWithIdentifiers.InsightCalculationResultRow: Content {}
extension DTOsWithIdentifiers.PriceStructure: Content {}
extension DTOsWithIdentifiers.StatusMessage: Content {}
#endif

extension DTOsWithIdentifiers.Insight {
    public static func newTimeSeriesInsight(groupID: UUID) -> DTOsWithIdentifiers.Insight {      
        DTOsWithIdentifiers.Insight(
            id: UUID.empty,
            groupID: groupID,
            order: nil,
            title: "New Time Series Insight",
            druidCustomQuery: nil,
            signalType: nil,
            uniqueUser: false,
            filters: [:],
            breakdownKey: nil,
            groupBy: .day,
            displayMode: .lineChart,
            isExpanded: false,
            lastRunTime: nil,
            lastRunAt: nil
        )
    }

    public static func newBreakdownInsight(groupID: UUID, title: String? = nil, breakdownKey: String? = nil) -> DTOsWithIdentifiers.Insight {
        DTOsWithIdentifiers.Insight(
            id: UUID.empty,
            groupID: groupID,
            order: nil,
            title: title ?? "New Breakdown Insight",
            druidCustomQuery: nil,
            signalType: nil,
            uniqueUser: false,
            filters: [:],
            breakdownKey: breakdownKey ?? "systemVersion",
            groupBy: .day,
            displayMode: .pieChart,
            isExpanded: false,
            lastRunTime: nil,
            lastRunAt: nil
        )
    }

    public static func newDailyUserCountInsight(groupID: UUID) -> DTOsWithIdentifiers.Insight {
        DTOsWithIdentifiers.Insight(
            id: UUID.empty,
            groupID: groupID,
            order: nil,
            title: "Daily Active Users",
            druidCustomQuery: nil,
            signalType: nil,
            uniqueUser: true,
            filters: [:],
            breakdownKey: nil,
            groupBy: .day,
            displayMode: .lineChart,
            isExpanded: false,
            lastRunTime: nil,
            lastRunAt: nil
        )
    }

    public static func newWeeklyUserCountInsight(groupID: UUID) -> DTOsWithIdentifiers.Insight {
        DTOsWithIdentifiers.Insight(
            id: UUID.empty,
            groupID: groupID,
            order: nil,
            title: "Weekly Active Users",
            druidCustomQuery: nil,
            signalType: nil,
            uniqueUser: true,
            filters: [:],
            breakdownKey: nil,
            groupBy: .week,
            displayMode: .barChart,
            isExpanded: false,
            lastRunTime: nil,
            lastRunAt: nil
        )
    }

    public static func newMonthlyUserCountInsight(groupID: UUID) -> DTOsWithIdentifiers.Insight {
        DTOsWithIdentifiers.Insight(
            id: UUID.empty,
            groupID: groupID,
            order: nil,
            title: "Active Users this Month",
            druidCustomQuery: nil,
            signalType: nil,
            uniqueUser: true,
            filters: [:],
            breakdownKey: nil,
            groupBy: .month,
            displayMode: .raw,
            isExpanded: false,
            lastRunTime: nil,
            lastRunAt: nil
        )
    }

    public static func newSignalInsight(groupID: UUID) -> DTOsWithIdentifiers.Insight {
        DTOsWithIdentifiers.Insight(
            id: UUID.empty,
            groupID: groupID,
            order: nil,
            title: "Signals by Day",
            druidCustomQuery: nil,
            signalType: nil,
            uniqueUser: false,
            filters: [:],
            breakdownKey: nil,
            groupBy: .day,
            displayMode: .lineChart,
            isExpanded: false,
            lastRunTime: nil,
            lastRunAt: nil
        )
    }
    
    public static func newCustomQueryInsight(groupID: UUID) -> DTOsWithIdentifiers.Insight {
        let customQuery = DruidCustomQuery(
            queryType: .groupBy,
            dataSource: "telemetry-signals",
            intervals: [],
            granularity: .all,
            aggregations: [
                .init(type: .longSum, name: "total_usage", fieldName: "count")
            ]
        )
        
        return DTOsWithIdentifiers.Insight(
            id: UUID.empty,
            groupID: groupID,
            order: nil,
            title: "Custom Query",
            druidCustomQuery: customQuery,
            signalType: nil,
            uniqueUser: false,
            filters: [:],
            breakdownKey: nil,
            groupBy: .day,
            displayMode: .lineChart,
            isExpanded: false,
            lastRunTime: nil,
            lastRunAt: nil
        )
    }
}
