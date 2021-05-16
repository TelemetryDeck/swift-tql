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
        public let emailIsVerified: Bool
        public let receiveMarketingEmails: Bool?
        public let isFoundingUser: Bool
    }
}

#if canImport(Vapor)
import Vapor

extension DTO.UserDTO: Content {}

extension DTO.UserDTO {
    init(user: User) {
        if let org = user.$organization.value {
            organization = DTO.Organization(id: user.$organization.id, name: org.name, isSuperOrg: org.isSuperOrg)
        } else {
            organization = DTO.Organization(id: user.$organization.id, name: "", isSuperOrg: false)
        }
        
        id = user.id!
        firstName = user.firstName
        lastName = user.lastName
        email = user.email
        isFoundingUser = user.isFoundingUser
        receiveMarketingEmails = user.receiveMarketingEmails
        emailIsVerified = user.emailIsVerified
    }
}
#endif
