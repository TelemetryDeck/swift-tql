#if canImport(Vapor)
import Fluent
import Vapor

final class Signal: Model, Content {
    static let schema = "signals"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "app_id")
    var app: App

    @Timestamp(key: "received_at", on: .create)
    var receivedAt: Date?

    @Field(key: "client_user")
    var clientUser: String

    @Field(key: "session_id")
    var sessionID: String?

    @Field(key: "signal_type")
    var type: String

    @Field(key: "payload")
    var payload: [String: String]?

    @Field(key: "is_migrated")
    var isMigrated: Bool
}

struct SignalPostBody: Content {
    let type: String
    let clientUser: String
    let sessionID: String?
    let payload: [String: String]?
    var appID: UUID?
    var receivedAt: Date?

    func getResolvedPayload() -> [String: String] {
        let resolvedPayload = payload ?? [:]
        return resolvedPayload.merging(["signalType": type], uniquingKeysWith: { _, last in last })
    }

    func getSignalPostBodyWithResolvedPayload() -> SignalPostBody {
        SignalPostBody(
            type: type,
            clientUser: clientUser,
            sessionID: sessionID,
            payload: getResolvedPayload(),
            appID: appID,
            receivedAt: receivedAt
        )
    }
}
#endif
