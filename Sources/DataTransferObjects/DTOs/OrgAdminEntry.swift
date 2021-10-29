//
//  OrgAdminEntry.swift
//  Telemetry Admin
//
//  Created by Charlotte Böhm on 30.07.21.
//

import Foundation

public extension DTOv1 {
    struct OrgAdminEntry: Codable, Identifiable {
        public var id: UUID
        public var organisationName: String?
        public var createdAt: Date?
        public var updatedAt: Date?
        public var appAdminEntries: [DTOv1.AppAdminEntry]
        public var signalCount: Int = 0
    }
}
