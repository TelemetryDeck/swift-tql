import Fluent
import Vapor

enum PlanTimePeriod: String, Codable {
    case monthly
    case yearly
}

final class Plan: Model, Content {
    static let schema: String = "plans"

    @ID(key: .id)
    var id: UUID?

    /// The Display Title of this Plan
    @Field(key: "title")
    var title: String

    /// A longer description of the Plan, if applicable
    @Field(key: "description")
    var description: String?

    /// The price in euro cents
    @Field(key: "price")
    var price: Int

    /// Order publicly visible plans by this
    @Field(key: "order")
    var order: Int

    /// If true, show this plan as a publicly selectable plan
    @Field(key: "is_public")
    var isPublic: Bool

    /// If the plan is not public, show it to people who enter this discount code
    @Field(key: "discount_code")
    var discountCode: String?

    /// The time period for which the plan is booked. Can be monthly or yearly
    @Field(key: "time_period")
    var timePeriod: PlanTimePeriod

    /// The number of signals organizations with this plan can receive at most
    @Field(key: "included_signals")
    var includedSignals: Int

    /// The number of org members organizations with this plan can have at most
    @Field(key: "included_organization_members")
    var includedOrganizationMembers: Int

    /// The number of apps organizations with this plan can manage at most
    @Field(key: "included_apps")
    var includedApps: Int

    /// If true, members of the organization get preferred treatment in email support
    @Field(key: "has_priority_email_support")
    var hasPriorityEmailSupport: Bool

    /// If true, members of the organization get video call / phone support
    @Field(key: "has_phone_support")
    var hasPhoneSupport: Bool
}
