#if canImport(Vapor)
import Fluent
import Vapor

final class OrganizationJoinRequest: Model, Content {
    static let schema = "organization_join_requests"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "organization_id")
    var organization: Organization

    @Field(key: "email")
    var email: String

    @Field(key: "registration_token")
    var registrationToken: String
}
#endif
