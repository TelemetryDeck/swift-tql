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
        public var isSuperOrg: Bool
        public var appIDs: [App.ID]
    }
    
    public struct App: Codable, Hashable, Identifiable {
        public var id: UUID
        public var name: String
        public var organizationID: Organization.ID
        public var insightGroupIDs: [InsightGroup.ID]
    }
    
    public struct InsightGroup: Codable, Hashable, Identifiable {
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
}


#if canImport(Vapor)
import Vapor

extension DTOsWithIdentifiers.Organization: Content {}
extension DTOsWithIdentifiers.App: Content {}
extension DTOsWithIdentifiers.InsightGroup: Content {}
extension DTOsWithIdentifiers.Insight: Content {}
#endif
