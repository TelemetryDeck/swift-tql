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
    
    /// The last time this organization's signal number have been checked against their plan
    @Field(key: "signal_numbers_checked_at")
    var signalNumbersCheckedAt: Date?

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
    
    /// The maximum number of signals this organization can receive without being marked as restricted.
    ///
    /// Special case: `-1` should be treated as infinite signals.
    func getMaxSignals() -> Int64 {
        guard self.stripeMaxSignals != -1 else {
            return -1
        }
        
        let resolvedMaxSignals = self.stripeMaxSignals ?? MAX_SIGNALS_FREE_PLAN
        let resolvedMultiplier = self.maxSignalsMultiplier ?? 1.0
        
        return Int64(Double(resolvedMaxSignals) * resolvedMultiplier)
    }
    
    /// Return true if the organization should be in restricted mode, false otherwise
    func shouldBeRestricted(withActualSignalNumber actualSignalNumber: Int64) -> Bool {
        var max_signals = self.getMaxSignals()
        if max_signals == -1 {
            // -1 means infinite signals
            max_signals = Int64.max
        }
        
        return actualSignalNumber > max_signals
    }
}
#endif
