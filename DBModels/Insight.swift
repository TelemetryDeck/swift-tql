#if canImport(Vapor)
import Fluent
import Vapor

final class Insight: Model, Content, Hashable {
    
    static let schema = "insights"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "group_id")
    var group: InsightGroup

    /// Insights are ordered by this property
    @Field(key: "order")
    var order: Double?

    @Field(key: "title")
    var title: String

    @Field(key: "subtitle")
    var subtitle: String?
    
    /// If set, use the custom query in this property instead of constructing a query out of the options below
    @Field(key: "druid_custom_query")
    var druidCustomQuery: DruidNativeQuery?

    /// If not nil, only count signals with this type
    @Field(key: "signal_type")
    var signalType: String?

    /// Only count one signal per user
    @Field(key: "unique_user")
    var uniqueUser: Bool

    /// Each filter key needs to present in the metadata payload and have the specified value for the signal to be counted
    @Field(key: "filters")
    var filters: [String: String]

    /// How far back should we look for signals? This should be a negative time interval.
    @Field(key: "rolling_window_size")
    var rollingWindowSize: TimeInterval

    /// If not nil, return a breakdown of values in this metadata payload key. Incompatible with groupBy
    @Field(key: "breakdown_key")
    var breakdownKey: String?

    /// If not nil, group and count found signals by this time interval. Incompatible with breakdownKey
    @Field(key: "group_by")
    var groupBy: InsightGroupByInterval?

    /// What kind of graph should this Insight be displayed as?
    @Field(key: "display_mode")
    var displayMode: InsightDisplayMode

    /// Should the insight be displayed as a large banner instead of a tile?
    @Field(key: "is_expanded")
    var isExpanded: Bool

    /// The amount of time (in seconds) this query took to calculate last time
    @Field(key: "last_runtime")
    var lastRunTime: TimeInterval?

    /// The query that was last used to run this query
    @Field(key: "last_query")
    var lastQuery: String?

    /// The date this query was last run
    @Field(key: "last_run_at")
    var lastRunAt: Date?

    /// Should use druid for calculating this insght
    @Field(key: "should_use_druid")
    var shouldUseDruid: Bool

    func insightDataTransferObject(withData data: [[String: String]], calculatedAt: Date, calculationDuration: TimeInterval) -> InsightDataTransferObject {
        InsightDataTransferObject(
            id: id!,
            order: order,
            title: title,
            subtitle: subtitle,
            signalType: signalType,
            uniqueUser: uniqueUser,
            filters: filters,
            rollingWindowSize: rollingWindowSize,
            breakdownKey: breakdownKey,
            groupBy: groupBy,
            displayMode: displayMode,
            isExpanded: isExpanded,
            shouldUseDruid: shouldUseDruid,
            data: data,
            calculatedAt: calculatedAt,
            calculationDuration: calculationDuration
        )
    }
    
    static func == (lhs: Insight, rhs: Insight) -> Bool {
        lhs.id == rhs.id
    }
    
    // Hashing used for caching
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(order)
        hasher.combine(uniqueUser)
        hasher.combine(filters)
        hasher.combine(breakdownKey)
        hasher.combine(groupBy)
        hasher.combine(displayMode)
        hasher.combine(isExpanded)
    }
}

struct InsightDataTransferObject: Content {
    let id: UUID

    let order: Double?
    let title: String
    let subtitle: String?

    /// Which signal types are we interested in? If nil, do not filter by signal type
    let signalType: String?

    /// If true, only include at the newest signal from each user
    let uniqueUser: Bool

    /// Only include signals that match all of these key-values in the payload
    let filters: [String: String]

    /// How far to go back to aggregate signals
    let rollingWindowSize: TimeInterval

    /// If set, return a breakdown of the values of this payload key
    let breakdownKey: String?

    /// If set, group and count found signals by this time interval. Incompatible with breakdownKey
    var groupBy: InsightGroupByInterval?

    /// How should this insight's data be displayed?
    var displayMode: InsightDisplayMode

    /// If true, the insight will be displayed bigger
    var isExpanded: Bool

    /// Should use druid for calculating this insght
    let shouldUseDruid: Bool

    /// Current Live Calculated Data
    let data: [[String: String]]

    /// When was this DTO calculated?
    let calculatedAt: Date

    /// How long did this DTO take to calculate?
    let calculationDuration: TimeInterval
}

struct InsightCreateRequestBody: Content, Validatable {
    let order: Double?
    let title: String
    let subtitle: String?

    /// Which signal types are we interested in? If nil, do not filter by signal type
    let signalType: String?

    /// If true, only include at the newest signal from each user
    let uniqueUser: Bool

    /// Only include signals that match all of these key-values in the payload
    let filters: [String: String]

    /// How far to go back to aggregate signals
    let rollingWindowSize: TimeInterval

    /// If set, return a breakdown of the values of this payload key
    let breakdownKey: String?

    /// If set, group and count found signals by this time interval. Incompatible with breakdownKey
    var groupBy: InsightGroupByInterval?

    /// How should this insight's data be displayed?
    var displayMode: InsightDisplayMode

    /// If true, the insight will be displayed bigger
    let isExpanded: Bool

    static func validations(_ validations: inout Validations) {
        // TOOD: More validations
        validations.add("title", as: String.self, is: !.empty)
    }
}

struct InsightUpdateRequestBody: Content {
    let groupID: UUID
    let order: Double?
    let title: String
    let subtitle: String?

    /// Which signal types are we interested in? If nil, do not filter by signal type
    let signalType: String?

    /// If true, only include at the newest signal from each user
    let uniqueUser: Bool

    /// Only include signals that match all of these key-values in the payload
    let filters: [String: String]

    /// How far to go back to aggregate signals
    let rollingWindowSize: TimeInterval

    /// If set, return a breakdown of the values of this payload key
    let breakdownKey: String?

    /// If set, group and count found signals by this time interval. Incompatible with breakdownKey
    var groupBy: InsightGroupByInterval?

    /// How should this insight's data be displayed?
    let displayMode: InsightDisplayMode

    /// If true, the insight will be displayed bigger
    let isExpanded: Bool

    /// Should use druid for calculating this insght
    let shouldUseDruid: Bool?
}
#endif
