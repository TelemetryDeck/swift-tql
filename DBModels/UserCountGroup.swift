import Fluent
import Vapor

final class UserCountGroup: Model, Content {
    static let schema = "usercount_groups"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "app_id")
    var app: App

    @Field(key: "title")
    var title: String

    @Field(key: "time_interval")
    var timeInterval: TimeInterval

    @Children(for: \.$userCountGroup)
    var historiclData: [UserCount]
}

struct UserCountGroupDataTransferObject: Content {
    var id: UUID?
    var app: [String: String]
    var title: String
    var timeInterval: TimeInterval
    var historicalData: [UserCount]

    // This is not a field, and should be calculated at retrieval time
    var rollingCurrentCount: Int
}
