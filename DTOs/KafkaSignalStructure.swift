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
    let appID: UUID
    let clientUser: String
    let sessionID: String
    let type: String
    let payload: [String: String]

    func toTagStructure() -> KafkaSignalStructureWithTags {
        KafkaSignalStructureWithTags(
            receivedAt: receivedAt,
            appID: appID,
            clientUser: clientUser,
            sessionID: sessionID,
            type: type,
            payload: KafkaSignalStructureWithDict.convertToMultivalueDimension(payload: payload)
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
    let appID: UUID
    let clientUser: String
    let sessionID: String
    let type: String
    let payload: [String]
}
