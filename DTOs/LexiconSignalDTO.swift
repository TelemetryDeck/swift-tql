//
//  File.swift
//
//
//  Created by Daniel Jilg on 12.05.21.
//

import Foundation

public extension DTO {
    struct LexiconSignalDTO: Codable, Hashable, Identifiable {
        public var id: String { return type }
        public var type: String
        public var signalCount: Int
        public var userCount: Int
        public var sessionCount: Int
    }
}

#if canImport(Vapor)
    import Vapor
    extension DTO.LexiconSignalDTO: Content {}
#endif
