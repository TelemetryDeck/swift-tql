//
//  File.swift
//  
//
//  Created by Daniel Jilg on 05.06.21.
//

import Foundation

/// Signal with a dictionary-like payload, as received from the Ingester
struct KafkaSignalStructureWithDict: Codable {
    let receivedAt: Date
    let isTestMode: String
    let appID: UUID
    let clientUser: String
    let sessionID: String
    let type: String
    let payload: [String: String]

    var platform: String? { payload["platform"] }
    var systemVersion: String? { payload["systemVersion"] }
    var majorSystemVersion: String? { payload["majorSystemVersion"] }
    var majorMinorSystemVersion: String? { payload["majorMinorSystemVersion"] }
    var appVersion: String? { payload["appVersion"] }
    var buildNumber: String? { payload["buildNumber"] }
    var modelName: String? { payload["modelName"] }
    var architecture: String? { payload["architecture"] }
    var operatingSystem: String? { payload["operatingSystem"] }
    var targetEnvironment: String? { payload["targetEnvironment"] }
    var locale: String? { payload["locale"] }
    var telemetryClientVersion: String? { payload["telemetryClientVersion"] }

    func toTagStructure() -> KafkaSignalStructureWithTags {
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
    static func convertToMultivalueDimension(payload: [String: String]?) -> [String] {
        guard let payload = payload else { return [] }
        return payload.map { key, value in key.replacingOccurrences(of: ":", with: "_") + ":" + value }
    }
}

/// Signal with a tag-like payload as string array, which is compatible with Druid
///
/// @see convertToMultivalueDimension
struct KafkaSignalStructureWithTags: Codable {
    let receivedAt: Date
    let isTestMode: String
    let appID: UUID
    let clientUser: String
    let sessionID: String
    let type: String
    let payload: [String]

    // Denormalized Payload Items
    let platform: String?
    let systemVersion: String?
    let majorSystemVersion: String?
    let majorMinorSystemVersion: String?
    let appVersion: String?
    let buildNumber: String?
    let modelName: String?
    let architecture: String?
    let operatingSystem: String?
    let targetEnvironment: String?
    let locale: String?
    let telemetryClientVersion: String?
}
