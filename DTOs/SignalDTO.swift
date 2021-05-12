//
//  File.swift
//
//
//  Created by Daniel Jilg on 12.05.21.
//

import Foundation

public extension DTO {
    struct Signal: Codable, Hashable {
        public var id: UUID?
        public var appID: UUID?
        public var count: Int?
        public var receivedAt: Date
        public var clientUser: String
        public var sessionID: String?
        public var type: String
        public var payload: [String: String]?
    }

    struct SignalDruidStructure: Codable, Hashable {
        public var id: UUID?
        public var appID: UUID?
        public var count: Int?
        public var receivedAt: Date
        public var clientUser: String
        public var sessionID: String?
        public var type: String
        public var payload: String

        func toSignal() -> Signal {
            let payloadJSON = payload.replacingOccurrences(of: "\\", with: "").data(using: .utf8)
            var actualPayload = [String: String]()
            if let payloadJSON = payloadJSON,
               let payloadArray = try? JSONDecoder().decode([String].self, from: payloadJSON) {
                for entry in payloadArray {
                    let subsequence = entry.split(separator: ":")
                    if let key = subsequence.first, let value = subsequence.last {
                        actualPayload[String(key)] = String(value)
                    }
                }
            }
            return Signal(id: id, appID: appID, count: count, receivedAt: receivedAt, clientUser: clientUser, sessionID: sessionID, type: type, payload: [:])
        }
    }
}

#if canImport(Vapor)
    import Vapor
    extension DTO.Signal: Content {}
    extension DTO.SignalDruidStructure: Content {}
#endif
