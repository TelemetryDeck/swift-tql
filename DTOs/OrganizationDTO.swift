//
//  File.swift
//
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public struct OrganizationDTO: Codable, Hashable, Identifiable {
    public init(id: UUID, name: String, isSuperOrg: Bool) {
        self.id = id
        self.name = name
        self.isSuperOrg = isSuperOrg
    }

    public var id: UUID
    public var name: String
    public var isSuperOrg: Bool
}
