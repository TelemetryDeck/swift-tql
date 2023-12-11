//
//  KafkaSignalStructure.swift
//
//
//  Created by Daniel Jilg on 05.06.21.
//

import Foundation

/// Signal with a dictionary-like payload, as received from the Ingester
public struct KafkaSignalStructureWithDict: Codable {
    public let receivedAt: Date
    public let isTestMode: String
    public let appID: UUID
    public let clientUser: String
    public let sessionID: String
    public let type: String
    public let payload: [String: String]

    public var platform: String? { payload["platform"] }
    public var systemVersion: String? { payload["systemVersion"] }
    public var majorSystemVersion: String? { payload["majorSystemVersion"] }
    public var majorMinorSystemVersion: String? { payload["majorMinorSystemVersion"] }
    public var appVersion: String? { payload["appVersion"] }
    public var buildNumber: String? { payload["buildNumber"] }
    public var modelName: String? { payload["modelName"] }
    public var architecture: String? { payload["architecture"] }
    public var operatingSystem: String? { payload["operatingSystem"] }
    public var targetEnvironment: String? { payload["targetEnvironment"] }
    public var locale: String? { payload["locale"] }
    public var telemetryClientVersion: String? { payload["telemetryClientVersion"] }

    public init(
        receivedAt: Date,
        isTestMode: String,
        appID: UUID,
        clientUser: String,
        sessionID: String,
        type: String,
        payload: [String: String]
    ) {
        self.receivedAt = receivedAt
        self.isTestMode = isTestMode
        self.appID = appID
        self.clientUser = clientUser
        self.sessionID = sessionID
        self.type = type
        self.payload = payload
    }

    public func toTagStructure() -> KafkaSignalStructureWithTags {
        KafkaSignalStructureWithTags(
            receivedAt: receivedAt,
            isTestMode: isTestMode,
            appID: appID,
            clientUser: clientUser,
            sessionID: sessionID,
            type: type,
            payload: KafkaSignalStructureWithDict.convertToMultivalueDimension(payload: payload),

            // Pull common payload keys out of the payload dictionary and put them one level up. This can help
            // increase performance on the druid level by treating these as fields instead of having to
            // string-search through payload for them.
            platform: platform,
            systemVersion: systemVersion,
            majorSystemVersion: majorSystemVersion,
            majorMinorSystemVersion: majorMinorSystemVersion,
            appVersion: appVersion,
            buildNumber: buildNumber,
            modelName: modelName,
            architecture: architecture,
            operatingSystem: operatingSystem,
            targetEnvironment: targetEnvironment,
            locale: locale,
            telemetryClientVersion: telemetryClientVersion
        )
    }

    /// Maps the payload dictionary to a String based Array, with key and value concatenated with a colon : character
    ///
    /// The key should never contain a colon character. Should it contain one anyway, we'll replace it with
    /// an underscore _ character. This way, we can ensure the first colon is always the delimiter character,
    /// with everything before it the key and everything after it the value.
    public static func convertToMultivalueDimension(payload: [String: String]?) -> [String] {
        guard let payload = payload else { return [] }
        return payload.map { key, value in key.replacingOccurrences(of: ":", with: "_") + ":" + value }
    }
}

/// Signal with a tag-like payload as string array, which is compatible with Druid
///
/// @see convertToMultivalueDimension
public struct KafkaSignalStructureWithTags: Codable {
    public let receivedAt: Date
    public let isTestMode: String
    public let appID: UUID
    public let clientUser: String
    public let sessionID: String
    public let type: String
    public let payload: [String]

    // Denormalized Payload Items
    public let platform: String?
    public let systemVersion: String?
    public let majorSystemVersion: String?
    public let majorMinorSystemVersion: String?
    public let appVersion: String?
    public let buildNumber: String?
    public let modelName: String?
    public let architecture: String?
    public let operatingSystem: String?
    public let targetEnvironment: String?
    public let locale: String?
    public let telemetryClientVersion: String?
}
