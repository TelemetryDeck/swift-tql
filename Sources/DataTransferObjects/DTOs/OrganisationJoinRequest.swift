//
//  OrganisationJoinRequest.swift
//  Telemetry Viewer
//
//  Created by Daniel Jilg on 14.05.21.
//

import Foundation

public extension DTOv1 {
    /// Sent to the server to create a user belonging to the organization
    struct OrganizationJoinRequestDTO: Codable {
        public init(email: String, receiveMarketingEmails: Bool, firstName: String, lastName: String, password: String, organizationID: UUID, registrationToken: String) {
            self.email = email
            self.firstName = firstName
            self.lastName = lastName
            self.password = password
            self.organizationID = organizationID
            self.registrationToken = registrationToken
            self.receiveMarketingEmails = receiveMarketingEmails
        }

        public var email: String
        public var firstName: String
        public var lastName: String
        public var password: String
        public let organizationID: UUID
        public var registrationToken: String
        public var receiveMarketingEmails: Bool
    }
}
