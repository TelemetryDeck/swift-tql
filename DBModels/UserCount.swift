import Fluent
import Vapor

final class UserCount: Model, Content {
    static let schema = "usercounts"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "count")
    var count: Int

    @Field(key: "calculated_at")
    var calculatedAt: Date

    @Parent(key: "usercount_group_id")
    var userCountGroup: UserCountGroup
}
