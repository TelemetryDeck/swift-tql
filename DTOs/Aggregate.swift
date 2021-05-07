//
//  File.swift
//
//
//  Created by Daniel Jilg on 15.04.21.
//

import Foundation

public extension DTO {
    struct Aggregate: Codable {
        public let min: TimeInterval
        public let avg: TimeInterval
        public let max: TimeInterval
    }
}

#if canImport(Vapor)
import Vapor

extension DTO.Aggregate: Content {}
#endif
