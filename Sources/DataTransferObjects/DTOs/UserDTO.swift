//
//  UserDTO.swift
//
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public extension DTOv1 {
    struct UserDTO: Identifiable, Codable {
        public let id: UUID
        public let organization: DTOv1.Organization?
        public var firstName: String
        public var lastName: String
        public var email: String
        public let emailIsVerified: Bool
        public var receiveMarketingEmails: Bool?
        public let isFoundingUser: Bool
        public var receiveReports: ReportSendingRate

        public init(
            id: UUID,
            organization: DTOv1.Organization?,
            firstName: String,
            lastName: String,
            email: String,
            emailIsVerified: Bool,
            receiveMarketingEmails: Bool?,
            isFoundingUser: Bool,
            receiveReports: ReportSendingRate
        ) {
            self.id = id
            self.organization = organization
            self.firstName = firstName
            self.lastName = lastName
            self.email = email
            self.emailIsVerified = emailIsVerified
            self.receiveMarketingEmails = receiveMarketingEmails
            self.isFoundingUser = isFoundingUser
            self.receiveReports = receiveReports
        }
    }
}
