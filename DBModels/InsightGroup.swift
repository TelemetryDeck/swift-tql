#if canImport(Vapor)
import Fluent
import Vapor

final class InsightGroup: Model, Content {
    static let schema = "insight_group"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "app_id")
    var app: App

    @Field(key: "title")
    var title: String

    @Field(key: "order")
    var order: Double?

    @Children(for: \.$group)
    var insights: [Insight]
}
#endif
