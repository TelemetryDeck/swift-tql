import Fluent
import Vapor

final class App: Model, Content {
    static let schema = "apps"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Parent(key: "organization_id")
    var organization: Organization
}
