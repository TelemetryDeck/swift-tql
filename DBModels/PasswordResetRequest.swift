#if canImport(Vapor)
import Fluent
import Vapor

final class PasswordResetRequest: Model, Content {
    static let schema: String = "password_reset_requests"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user")
    var user: User

    @Field(key: "code")
    var code: String

    @Field(key: "created_at")
    var createdAt: Date

    @Field(key: "fulfilled_at")
    var fulfilledAt: Date?
}
#endif
