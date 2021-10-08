//
//  File.swift
//
//
//  Created by Daniel Jilg on 12.05.21.
//

import Foundation

#warning("These structs need to be checked, if they are needed. If yes, they need cleanup and be integrated into DTOv2")

public extension DTOv1 {
    struct IdentifiableSignal: Codable, Hashable, Identifiable {
        public var id = UUID()
        public var appID: UUID?
        public var count: Int
        public var receivedAt: Date
        public var clientUser: String
        public var sessionID: String
        public var type: String
        public var payload: [String: String]?
        
        var signal: Signal {
            return Signal(appID: appID, count: count, receivedAt: receivedAt, clientUser: clientUser, sessionID: sessionID, type: type, payload: payload)
        }
    }
    
    struct Signal: Codable, Hashable {
        public var appID: UUID?
        public var count: Int?
        public var receivedAt: Date
        public var clientUser: String
        public var sessionID: String?
        public var type: String
        public var payload: [String: String]?
        
        func toIdentifiableSignal() -> IdentifiableSignal {
            return IdentifiableSignal(id: UUID(), appID: appID, count: count ?? 1, receivedAt: receivedAt, clientUser: clientUser, sessionID: sessionID ?? "–", type: type, payload: payload)
        }
    }

    struct SignalDruidStructure: Codable, Hashable {
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
                    let subsequence = entry.split(separator: ":", maxSplits: 1)
                    if let key = subsequence.first, let value = subsequence.last {
                        actualPayload[String(key)] = String(value)
                    }
                }
            }
            return Signal(appID: appID, count: count, receivedAt: receivedAt, clientUser: clientUser, sessionID: sessionID, type: type, payload: actualPayload)
        }
    }
}

#if canImport(Vapor)
    import Vapor
    extension DTOv1.Signal: Content {}
    extension DTOv1.SignalDruidStructure: Content {}
#endif
