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
        public var firstName: String
        public var lastName: String
        public var email: String
        public let emailIsVerified: Bool
        public var receiveMarketingEmails: Bool?
        public let isFoundingUser: Bool
        public var receiveReports: ReportSendingRate
    }
}

#if canImport(Vapor)
import Vapor

extension DTO.UserDTO: Content {}

extension DTO.UserDTO {
    init(user: User) {
        if let org = user.$organization.value {
            organization = DTO.Organization(id: user.$organization.id, name: org.name, isSuperOrg: org.isSuperOrg, createdAt: org.createdAt, updatedAt: org.updatedAt)
        } else {
            organization = DTO.Organization(id: user.$organization.id, name: "", isSuperOrg: false, createdAt: nil, updatedAt: nil)
        }
        
        id = user.id!
        firstName = user.firstName
        lastName = user.lastName
        email = user.email
        isFoundingUser = user.isFoundingUser
        receiveMarketingEmails = user.receiveMarketingEmails
        emailIsVerified = user.emailIsVerified
        receiveReports = user.receiveReports ?? .never
    }
}
#endif
