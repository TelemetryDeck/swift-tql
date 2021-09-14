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

    init() {}

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
#endif
