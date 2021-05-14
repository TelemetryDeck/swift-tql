//
//  File.swift
//
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public extension DTO {
    struct UserDTO: Identifiable, Codable {
        public let id: UUID
        public let organization: DTO.Organization?
        public let firstName: String
        public let lastName: String
        public let email: String
        public let isFoundingUser: Bool
    }
}

#if canImport(Vapor)
import Vapor

extension DTO.UserDTO: Content {}

extension DTO.UserDTO {
    init(user: User) {
        id = user.id!
        organization = DTO.Organization(id: user.$organization.id, name: user.organization.name, isSuperOrg: user.organization.isSuperOrg)
        firstName = user.firstName
        lastName = user.lastName
        email = user.email
        isFoundingUser = user.isFoundingUser
    }
}
#endif
