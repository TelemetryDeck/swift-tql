#if canImport(Vapor)
import Fluent
import Vapor

final class UserToken: Model, Content {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    @Field(key: "expires_at")
    var expiresAt: Date

    init() {}

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        expiresAt = Date(timeIntervalSinceNow: 60 * 60 * 24 * 30 * 6) // around 6 months
        $user.id = userID
    }
}

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user

    // TODO: actual validity requirements
    /// If this is false, the token will be deleted from the database and the user will not be
    /// authenticated. For simplicity, we'll make the tokens eternal by hard-coding this to true.
    var isValid: Bool {
        true
    }
}
#endif
