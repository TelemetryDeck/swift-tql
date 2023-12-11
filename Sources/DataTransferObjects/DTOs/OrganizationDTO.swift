//
//  OrganizationDTO.swift
//
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public extension DTOv1 {
    struct Organization: Codable, Hashable, Identifiable {
        public init(id: UUID, name: String, isSuperOrg: Bool, createdAt: Date?, updatedAt: Date?) {
            self.id = id
            self.name = name
            self.isSuperOrg = isSuperOrg
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }

        public var id: UUID
        public var name: String
        public var isSuperOrg: Bool
        public var createdAt: Date?
        public var updatedAt: Date?
    }
}
