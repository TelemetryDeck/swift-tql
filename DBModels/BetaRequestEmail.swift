import Fluent
import Vapor

final class BetaRequestEmail: Model, Content {
    static let schema = "beta_request_emails"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "registration_token")
    var registrationToken: String

    @Field(key: "requested_at")
    var requestedAt: Date

    @Field(key: "sent_at")
    var sentAt: Date?

    @Field(key: "is_fulfilled")
    var isFulfilled: Bool
}
