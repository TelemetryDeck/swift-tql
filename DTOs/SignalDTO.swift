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
        public var sessionID: String
        public var type: String
        public var payload: [String: String]?
    }
}

#if canImport(Vapor)
    import Vapor
    extension DTO.Signal: Content {}
#endif
