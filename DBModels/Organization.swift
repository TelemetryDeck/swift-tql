#if canImport(Vapor)
import Fluent
import Vapor

/// Groups users and apps
final class Organization: Model, Content {
    static let schema = "organizations"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "stripe_customer_id")
    var stripeCustomerID: String?
    
    @Field(key: "stripe_price_lookup_key")
    var stripePriceLookupKey: String?
    
    @Field(key: "stripe_max_signals")
    var stripeMaxSignals: Int64?
    
    @Field(key: "max_signals_multiplier")
    var maxSignalsMultiplier: Double?
    
    @Field(key: "restricted_mode")
    var isInRestrictedMode: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    /// If `true`, this organization should display additional admin capabilities in the viewer app
    @Field(key: "is_super_org")
    var isSuperOrg: Bool

    @Children(for: \.$organization)
    var users: [User]
    
    @Children(for: \.$organization)
    var apps: [App]
    
    @Children(for: \.$organization)
    var badgeAwards: [BadgeAward]

    init() {}

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
#endif
