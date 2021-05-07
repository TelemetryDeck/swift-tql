//
//  File.swift
//
//
//  Created by Daniel Jilg on 16.04.21.
//

import Foundation

public extension DTO {
    struct AppSignalCount: Codable, Identifiable {
        public let id: UUID
        public let appName: String?
        public let organisationName: String?
        public let organisationID: UUID?
        public let signalCount: Int
        public let userCount: Int
    }
}

#if canImport(Vapor)
import Vapor

extension DTO.AppSignalCount: Content {}
#endif
