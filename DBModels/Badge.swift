#if canImport(Vapor)
import Fluent
import Vapor

/// Connects an Organization with a badge
final class BadgeAward: Model, Content {
    static let schema: String = "organization_badge"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "badge")
    var badge: Badge

    @Parent(key: "organization")
    var organization: Organization
    
    @Timestamp(key: "awardedAt", on: .create)
    var awardedAt: Date?
}

/// Labels an organization, with possible benefits
final class Badge: Model, Content {
    static let schema: String = "badges"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "is_visible")
    var isVisible: Bool
    
    @Field(key: "title")
    var title: String

    @Field(key: "description")
    var description: String
    
    @Field(key: "image_url")
    var imageURL: String?
    
    @Field(key: "signal_count_multiplier")
    var signalCountMultiplier: Double?
}
#endif
