import Fluent
import Vapor

/// Connects a Plan to an organization
final class Subscription: Model, Content {
    static let schema: String = "subscriptions"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "plan")
    var plan: Plan

    @Parent(key: "organization")
    var organization: Organization

    /// The time at which this specific subscription becomes active
    @Field(key: "valid_from")
    var validFrom: Date

    /// The time at which this specific subscription is becomes no longer active
    @Field(key: "valid_until")
    var validUntil: Date

    /// The amount of euro cents paid for this subscription
    @Field(key: "amount_paid")
    var amountPaid: Int
}
