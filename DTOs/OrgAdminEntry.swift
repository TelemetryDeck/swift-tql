//
//  OrgAdminEntry.swift
//  Telemetry Admin
//
//  Created by Charlotte Böhm on 30.07.21.
//

import Foundation

public extension DTO {
    struct OrgAdminEntry: Codable, Identifiable {
        public var id: UUID
        public var organisationName: String?
        public var appAdminEntries: [DTO.AppAdminEntry]
        public var signalCount: Int = 0
    }
}

#if canImport(Vapor)
import Vapor

extension DTO.OrgAdminEntry: Content {}
#endif

